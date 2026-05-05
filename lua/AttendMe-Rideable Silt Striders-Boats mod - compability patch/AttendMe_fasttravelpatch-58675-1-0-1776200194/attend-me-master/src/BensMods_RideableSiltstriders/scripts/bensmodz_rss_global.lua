local util = require('openmw.util')
local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

-- Shared global storage section read by AttendMe's teleport module to suppress
-- follower teleportation while the player is riding a silt strider.
local rssGlobalSection = storage.globalSection('RideableSiltStridersGlobal')

local modVersion = 1

local activeTravelData = nil --this is all the data for the travel npc (all options they have)
local destinationData = nil --this is the data for the specific destination chosen (eg. Balmora)

local pointIndex = 1
local testStartIndex = 0
local travelSpeed = 0
local state = "none"
local playerRiding = false
local playerDriving = false

local boardStartPos = util.vector3(0,0,0)
local boardTime = 0
local resetTravelActorTimer = 0

local strider = nil
local striderDir = util.vector3(0,0,0)
local striderRot = 0
local striderMaxSpeed = 8 --8 is default
local resetStrider = false
local targetTravelPos = util.vector3(0,0,0)
local striderFlyingAway = false

local slowTravelUpdateTimer = 0
local pauseCount = 0
local disabledObjs = {}

-- Followers that were hidden during travel, to be restored on arrival.
-- Populated via Rss_SetFollowersForTravel sent from the player script,
-- which tracks AttendMe's AttendMeFollowerStatus events.
-- This global script works fine without AttendMe installed — the list just stays empty.
local hiddenFollowers = {}

--Player Inputs
local camForward = util.vector3(0,0,0)
local input_moveFwd = false
local input_moveL = false
local input_moveR = false
local input_jump = false

--PlayerLerpToPosVars
local lerpToPosStart
local lerpToPosTarget
local lerpToPosTimer = 0
local raycastFoundSurfacePos
local playerFallingZ = 0
local snapPlayerToGround = false

local globals = world.mwscript.getGlobalVariables()

local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(xzLen * math.sin(yaw), xzLen * math.cos(yaw), math.sin(pitch))
end

local function rotToFwd(rotation)
  return anglesToV(rotation:getPitch(), rotation:getYaw())
end

local function renableObjects()
  for _, obj in ipairs(disabledObjs) do
      if obj and obj:isValid() then
          obj.enabled = true
      end
  end
  disabledObjs = {}
end

local function getCellNameByPos(position)
    local cellSize = 8192
    local cellX = math.floor(position.x / cellSize)
    local cellY = math.floor(position.y / cellSize)
    return world.getExteriorCell(cellX, cellY).name
end

local function isAlreadyDisabled(obj)
  for _, disabledObj in ipairs(disabledObjs) do
    if disabledObj == obj then
      return true
    end
  end
  return false
end

local function shouldSuppressDuringTravel(object)
  if not object or not object:isValid() then return false end
  local recordId = object.recordId
  if not recordId then return false end
  recordId = string.lower(recordId)
  return recordId:find("cliff", 1, true) ~= nil and recordId:find("racer", 1, true) ~= nil
end

local function disableObjectForTravel(obj)
  if not obj or not obj:isValid() then return end
  if obj == strider then return end
  if not isAlreadyDisabled(obj) then
    table.insert(disabledObjs, obj)
  end
  obj.enabled = false
end

local function suppressCliffRacersWhileTraveling()
  if state == "none" then return end

  for _, actor in ipairs(world.activeActors) do
    if actor and actor:isValid() and types.Actor.objectIsInstance(actor) and shouldSuppressDuringTravel(actor) then
      disableObjectForTravel(actor)
    end
  end
end

-- Re-enable all followers and teleport them to a given destination position.
-- Called on normal arrival and also on early jump-off.
-- Also clears the shared storage flag so AttendMe resumes normal teleport logic.
local function restoreFollowers(destination)
  for _, actor in ipairs(hiddenFollowers) do
    if actor:isValid() then
      actor:teleport('', destination)
      actor.enabled = true
    end
  end
  hiddenFollowers = {}
  rssGlobalSection:set('playerIsTraveling', false)
end

local function startTravel(data) 
  if data.key == "Free Ride" then 
    for k,_ in pairs(activeTravelData) do
        destinationData = activeTravelData[k]
        break
    end
    playerDriving = true
  else 
    destinationData = activeTravelData[data.key] 
    playerDriving = false
  end
  state = "boarding"
  boardStartPos = world.players[1].position
  boardTime = 0

  -- Tell AttendMe's teleport module to suppress follower teleportation for the
  -- duration of the ride. The flag is cleared in restoreFollowers() on arrival.
  rssGlobalSection:set('playerIsTraveling', true)

  -- Ask the player script to collect its live follower list and send it back
  -- via Rss_SetFollowersForTravel. If AttendMe is not installed, the player
  -- script simply sends an empty list and everything still works fine.
  world.players[1]:sendEvent('Rss_CollectFollowers', {})
end

local function onUpdate(dt)

  -- Don't process anything while inventory/menu is open
  if core.isWorldPaused() then return end

  world.players[1]:sendEvent('Rss_getGlobalData', { playerRiding = playerRiding, travelSpeed = travelSpeed } )
  
  if pauseCount > 0 then 
    pauseCount = pauseCount - 1
    return
  end
  
  globals.lua_rss_endride = 0
  globals.lua_rss_moveplayer = 0
  if playerRiding and state ~= "unboarding" then globals.lua_rss_moveplayer = 1 end
  
  if strider == nil then
    local draftInfo = { name = "", model = 'meshes/r/siltstrider.nif'}
    local draft = types.Activator.createRecordDraft(draftInfo)
    local record = world.createRecord(draft)
    strider = world.createObject(record.id, 1)
    resetStrider = true
  end
  
  if resetStrider then
    strider:teleport('', util.vector3(0,0,-10000))
    resetStrider = false
  end
  
  if lerpToPosTimer > 0 and raycastFoundSurfacePos and dt > 0 then
    local terrainHeight = core.land.getHeightAt(util.vector3(raycastFoundSurfacePos.x,raycastFoundSurfacePos.y,0), world.players[1].cell)
    local targetValue = (math.max(0, raycastFoundSurfacePos.z, terrainHeight))
    if playerFallingZ > targetValue + 1 then
      playerFallingZ = playerFallingZ - dt * 800
      local newPos = util.vector3(lerpToPosStart.x, lerpToPosStart.y, playerFallingZ)
      world.players[1]:teleport('', newPos)
    else 
      lerpToPosTimer = 0
    end
  end

  local player = world.players[1]
  if player then
    if state == "none" then
    
      -- This resets travel npcs to their startingPos after you arrive and they get moved
      if resetTravelActorTimer > 0 then
        resetTravelActorTimer = resetTravelActorTimer - dt
        if resetTravelActorTimer <= 0 then
          player:sendEvent('Rss_ResetNearbyActors', { } )
          if player.position.z <= 0 then
            player:teleport('', destinationData.endPoint)
          end
        end
      end
      
    end
    
    -- Boarding
    if state == "boarding" then
      boardTime = boardTime + dt / 2
      if (dt > 0) then player:teleport('', boardStartPos + (destinationData.startPoint - boardStartPos) * boardTime) end
      if boardTime >= 1 then
        state = "traveling"
        playerRiding = true
        striderFlyingAway = false
        targetTravelPos = player.position
        travelSpeed = 0
        pointIndex = 1
        player:sendEvent('Rss_DisableNearestStrider', { } )
        player:sendEvent('Rss_SetPlayerIsTraveling', { isTraveling = true } )
        striderDir = (destinationData.points[1] - destinationData.startPoint):normalize()
        striderRot = math.atan2(striderDir.y, striderDir.x) - 1.5708
        strider:teleport('', world.players[1].position, util.transform.rotateZ(-striderRot))
        pauseCount = 1
        raycastFoundSurfacePos = nil
        world.players[1]:sendEvent('Rss_playerPlayAnimation', { animationName = "idle" })
        if testStartIndex > 0 then
          pointIndex = testStartIndex
          targetTravelPos = destinationData.points[pointIndex]
        end
        return
      end
    end
    
    -- Traveling
    if state == "traveling" then
    
      slowTravelUpdateTimer = slowTravelUpdateTimer + dt
      if slowTravelUpdateTimer > 1 then
        slowTravelUpdateTimer = 0
      end

      -- Keep suppressing cliff racers for the entire ride, including ones that
      -- activate later while the player is already traveling.
      suppressCliffRacersWhileTraveling()
      
      if playerDriving then
      
        striderDir = rotToFwd(strider.rotation)
        if (input_moveFwd == 1) then travelSpeed = travelSpeed + dt * .1 * (striderMaxSpeed - travelSpeed)
        elseif travelSpeed > 0 then travelSpeed = travelSpeed - dt 
        else travelSpeed = 0 end
        
      else
      
        -- Determine Travel Speed
        if (pointIndex > #destinationData.points - 1) then travelSpeed = travelSpeed + dt * 1 * (3 - travelSpeed)
        elseif (pointIndex > #destinationData.points - 4) then travelSpeed = travelSpeed + dt * .5 * (5 - travelSpeed)
        else travelSpeed = travelSpeed + dt * .1 * (striderMaxSpeed - travelSpeed) end
        
        local diff = (destinationData.points[pointIndex] - targetTravelPos)
        local dist = diff:length()
        
        -- Determine Target Direction
        local targetDir = (destinationData.points[pointIndex] - targetTravelPos):normalize()
        if striderDir:dot(targetDir) < 0.2 then
          pointIndex = pointIndex + 1
          striderDir = targetDir
        else
          striderDir = (striderDir + (targetDir - striderDir) * (.016 * 2 * math.max(1, striderMaxSpeed / 8))):normalize()
        end
        
        -- Reached Next Point
        if dist < 50 then
          pointIndex = pointIndex + 1
          
          -- Reached Destination
          if not destinationData.points[pointIndex] then
            state = "unboarding"
            boardStartPos = world.players[1].position
            boardTime = 0
            world.players[1]:sendEvent('Rss_playerPlayAnimation', {  })
          end
        end
        
      end

      local speed = travelSpeed
      if (dt == 0) then speed = 0 end
      
      -- Player jumped off during Free Ride
      if playerDriving and not playerRiding then
        striderDir = rotToFwd(strider.rotation)
        if (dt > 0) then speed = 8 end
        if (player.position - strider.position):length() > 10000 then
          state = "unboarding"
          playerDriving = false
        end
      end

      -- Update Target Travel Point
      if (dt > 0) then 
        targetTravelPos = targetTravelPos + striderDir * speed
        if (playerDriving) then
          local currentHeight = targetTravelPos.z
          if input_jump and playerRiding then currentHeight = currentHeight + 1
          else currentHeight = currentHeight - 1 end
          targetTravelPos = util.vector3(targetTravelPos.x,targetTravelPos.y,currentHeight)
          local lowestHeight = math.max(1000, core.land.getHeightAt(targetTravelPos, player.cell) + 1200)
          if targetTravelPos.z < lowestHeight then
            targetTravelPos = util.vector3(targetTravelPos.x,targetTravelPos.y,lowestHeight)
          end
        end
        if playerRiding then 
          globals.lua_rss_x = targetTravelPos.x
          globals.lua_rss_y = targetTravelPos.y
          globals.lua_rss_z = targetTravelPos.z
        end
      end

      -- Rotate and Move Silt Strider
      local striderRotTarget = math.atan2(striderDir.y, striderDir.x) - 1.5708
      striderRot = striderRot + ((striderRotTarget - striderRot + math.pi) % (2*math.pi) - math.pi) * dt * math.max(1, striderMaxSpeed / 8)
      if playerDriving and playerRiding then striderRot = striderRot + input_moveL * .005 end
      if playerDriving and playerRiding then striderRot = striderRot - input_moveR * .005 end
      strider:teleport('', targetTravelPos + util.vector3(0,0,-1220), util.transform.rotateZ(-striderRot))

    end
    
    -- Unboarding
    if state == "unboarding" then
      boardTime = boardTime + dt / 2
      if playerRiding and dt > 0 then
        player:teleport('', boardStartPos + (destinationData.endPoint - boardStartPos) * boardTime)
      end
      if boardTime >= 1 then
        if playerRiding then resetTravelActorTimer = 1 end
        if destinationData.flyAwayPoints ~= nil and #destinationData.flyAwayPoints > 0 then
          striderFlyingAway = true
          pointIndex = 1
        else
          resetStrider = true
        end
        playerRiding = false
        globals.lua_rss_endride = 1
        pauseCount = 1
        player:sendEvent('Rss_SetPlayerIsTraveling', { isTraveling = false } )
        state = "none"
        renableObjects()

        -- Teleport followers to the destination and re-enable them
        restoreFollowers(destinationData.endPoint)
      end
    end
    
    -- Silt strider flying away animation after an unconventional drop off (eg. caldera)
    if striderFlyingAway then
      targetTravelPos = targetTravelPos + (destinationData.flyAwayPoints[pointIndex] - targetTravelPos):normalize() * 8
      strider:teleport('', targetTravelPos + util.vector3(0,0,-1300), util.transform.rotateZ(-striderRot))
      if (destinationData.flyAwayPoints[pointIndex] - targetTravelPos):length() < 50 then
        pointIndex = pointIndex + 1
        if not destinationData.flyAwayPoints[pointIndex] then
          striderFlyingAway = false
          resetStrider = true
        end
      end
    end
    
    if snapPlayerToGround then
      world.players[1]:sendEvent('Rss_RaycastToFindSurface', { 
        from = world.players[1].position,
        to = world.players[1].position - util.vector3(0,0,10000) 
      })
      if raycastFoundSurfacePos then
        player:teleport('',raycastFoundSurfacePos)
        snapPlayerToGround = false
      end
    end
    
  end
end

local function enableDisableObject(data) 
  local obj = data["obj"]
  if not obj or not obj:isValid() then return end
  if (obj == strider) then return end
  local isActive = data["isActive"]
  obj.enabled = isActive
  if not isActive and not isAlreadyDisabled(obj) then
    table.insert(disabledObjs, obj)
  end
end

local function startPlayerLerpToPos(data) 
  lerpToPosStart = data.start
  lerpToPosTarget = data.target
  lerpToPosTimer = 1
end

local function playerJumpOffStriderEarly(data) 
  -- Don't allow dismount while inventory/menu is open
  if core.isWorldPaused() then return end
  if not playerRiding then return end
  local moveDir = rotToFwd(strider.rotation):cross(util.vector3(0,0,1))
  lerpToPosStart = world.players[1].position + moveDir * 300
  playerFallingZ = lerpToPosStart.z
  lerpToPosTimer = 1
  world.players[1]:sendEvent('Rss_RaycastToFindSurface', { 
    from = lerpToPosStart,
    to = util.vector3(lerpToPosStart.x,lerpToPosStart.y,lerpToPosStart.z - 10000) 
  })
  playerRiding = false 
  globals.lua_rss_endride = 1
  pauseCount = 1
  world.players[1]:sendEvent('Rss_SetPlayerIsTraveling', { isTraveling = false } )
  world.players[1]:sendEvent('Rss_playerPlayAnimation', {  })

  -- Teleport followers to the early dismount position and re-enable them
  restoreFollowers(world.players[1].position)
end

local function setActiveTravelData(data) 
  activeTravelData = data.tData
end

local function teleportActorToPos(data) 
  data.actor:teleport(data.actor.cell, data.pos) 
end

local function reducePlayersGold(data) 
   local gold = types.Actor.inventory(world.players[1]):find('gold_001')
   if gold then gold:remove(data.amount) end
end

local function loadUserSettings(data) 
  striderMaxSpeed = data.speed
end

local function setPlayerInputs(data)
  -- Zero out all inputs while menu/inventory is open so they don't carry over on close
  if core.isWorldPaused() then
    input_moveFwd = 0
    input_moveL = 0
    input_moveR = 0
    input_jump = false
    return
  end
  camForward = data.camForward
  input_moveFwd = data.moveFwd
  input_moveL = data.moveL
  input_moveR = data.moveR
  input_jump = data.jump
end

local function setRaycastFoundSurface(data) 
  raycastFoundSurfacePos = data.hitPos
end

-- Receive the follower list from the player script.
-- The player script listens to AttendMe's AttendMeFollowerStatus events and maintains
-- a live table of following actors. When travel starts, the global script sends
-- Rss_CollectFollowers to the player script, which replies with this event.
-- Each follower is disabled so they don't wander or despawn during the flight,
-- and are restored (teleport + re-enable) when travel ends.
-- If AttendMe is not installed the player script sends an empty list and nothing happens.
local function setFollowersForTravel(data)
  hiddenFollowers = {}
  if not data.followers then return end
  for _, actor in ipairs(data.followers) do
    if actor:isValid() then
      table.insert(hiddenFollowers, actor)
      actor.enabled = false
    end
  end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = function() 
          -- SAVE DATA
          -- hiddenFollowers is intentionally NOT saved. If the player saves mid-travel,
          -- followers will reappear at their last position on load, which is acceptable
          -- since the ride state is also fully reset on load.
          return { modVersion = modVersion, strider = strider, playerRiding = playerRiding, disabledObjs = disabledObjs }
        end,
        onLoad = function(saveData)
          -- LOAD SAVED DATA
          saveData = saveData or {}
          if saveData.strider then 
            strider = saveData.strider 
            resetStrider = true
          end
          if saveData.playerRiding and saveData.playerRiding == true then
            snapPlayerToGround = true
            globals.lua_rss_endride = 1
            pauseCount = 5
          end
          if saveData.disabledObjs then
            disabledObjs = saveData.disabledObjs
            renableObjects()
          end
          -- Clear follower list on load; disabled followers re-enable themselves naturally
          hiddenFollowers = {}
          -- Always clear the travel flag on load so AttendMe is never permanently blocked
          rssGlobalSection:set('playerIsTraveling', false)
        end,
        onObjectActive = function(object) 
          if state == "traveling" and object.recordId == "a_siltstrider" then
              enableDisableObject( { obj = object, isActive = false } )
          end
        end,
        onActorActive = function(actor)
          if state ~= "none" and shouldSuppressDuringTravel(actor) then
            disableObjectForTravel(actor)
          end
        end
    },
    eventHandlers = { 
      Rss_StartTravel = startTravel,
      Rss_SetActiveTravelData = setActiveTravelData,
      Rss_EnableDisableObject = enableDisableObject,
      Rss_PlayerJumpOffStriderEarly = playerJumpOffStriderEarly,
      Rss_TeleportActorToPos = teleportActorToPos,
      Rss_ReducePlayersGold = reducePlayersGold,
      Rss_LoadUserSettings = loadUserSettings,
      Rss_SetPlayerInputs = setPlayerInputs,
      Rss_SetRaycastFoundSurface = setRaycastFoundSurface,
      Rss_SetFollowersForTravel = setFollowersForTravel,
    }
}