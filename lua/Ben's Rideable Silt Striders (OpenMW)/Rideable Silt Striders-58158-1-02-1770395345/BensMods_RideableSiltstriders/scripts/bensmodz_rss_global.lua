
--NOTES
-- ToggleCollision in console to noclip fly
-- Use this to run a function kinda like a coroutine -> time.runRepeatedly(updateTime, 1 * time.minute, { type = time.GameTime })
-- when using util.transform.rotateZ(radians) make sure to use radians and not an angle like the docs say
-- Error was saying it couldn't load/find a lua script, it was because it was missing a "require" at the top (core)

--TODO
-- BUG - one time when arriving at khuul from ald ruhn I got off the silt strider and it teleported me to the bottom of the ocean (like y = -100000), Check for a strange pos like this  1 sec after dismounting (check for negative y pos) if it is, teleport player to "end point" in travel data
-- wind sound effect when traveling (louder the faster you go, but not very loud)
-- menu option for free rides and price multipliers (pay more for immersive rides) (Free, 1x, 2x, 5x, 10x, 20x, 100x)
-- test a short race and make sure it still looks good, if not adjust height based on race
-- maybe fade to black to get on/off instead of lerping (idk I like lerping)
-- maybe can use this for gamepad -> GamepadControls.setGamepadCursorActive(value)
-- ask the zackutils guy if there is a better way to move the player than teleport (show him a video)

local util = require('openmw.util')
local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local I = require('openmw.interfaces')

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

local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(xzLen * math.sin(yaw), xzLen * math.cos(yaw), math.sin(pitch))
end

local function rotToFwd(rotation)
  return anglesToV(rotation:getPitch(), rotation:getYaw())
end

local function renableObjects()
  for _, obj in ipairs(disabledObjs) do
      obj.enabled = true
  end
  disabledObjs = {}
end


local function getCellNameByPos(position)
    local cellSize = 8192
    local cellX = math.floor(position.x / cellSize)
    local cellY = math.floor(position.y / cellSize)
    return world.getExteriorCell(cellX, cellY).name
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
  

  -- Set all weather in world to match current weather if its normal
  local w = core.weather.getCurrent(world.players[1].cell).recordId
  if (w ~= "ashstorm" and w ~= "blight" and w ~= "blizzard" and w ~= "snow") then
    for _, region in ipairs(core.regions.records) do
      core.weather.changeWeather(region.id, core.weather.records[w])
    end
  end

  -- Set all weather along path to be current weather
  local w = core.weather.getCurrent(world.players[1].cell).recordId
  for _, point in ipairs(destinationData.points) do
    local region = world.getCellByName(getCellNameByPos(point)).region
    core.weather.changeWeather(region, core.weather.records[w])
  end

end

local function onUpdate(dt)
  
  if pauseCount > 0 then 
    pauseCount = pauseCount - 1
    return
  end
  
  if strider == nil then
    strider = world.createObject("a_siltstrider", 1)
    resetStrider = true
  end
  
  if resetStrider then
    strider:teleport('', util.vector3(0,0,-100000))
    resetStrider = false
  end
  
  if lerpToPosTimer > 0 and raycastFoundSurfacePos then
    lerpToPosTimer = lerpToPosTimer - dt
    local lerpValue = 1 - lerpToPosTimer
    local val = lerpToPosStart.z * (1-lerpValue) + (raycastFoundSurfacePos.z) * lerpValue
    local newPos = util.vector3(lerpToPosStart.x, lerpToPosStart.y, val)
    world.players[1]:teleport('', newPos)
  end

  local player = world.players[1]
  if player then
    if state == "none" then
    
      -- This resets travel npcs to their startingPos after you arrive and they get moved
      if resetTravelActorTimer > 0 then
        resetTravelActorTimer = resetTravelActorTimer - dt
        if resetTravelActorTimer <= 0 then
          player:sendEvent('ResetNearbyActors', { } )
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
        player:sendEvent('DisableNearestStrider', { } )
        player:sendEvent('SetPlayerIsTraveling', { isTraveling = true } )
        striderDir = (destinationData.points[1] - destinationData.startPoint):normalize()
        striderRot = math.atan2(striderDir.y, striderDir.x) - 1.5708
        strider:teleport('', world.players[1].position, util.transform.rotateZ(-striderRot))
        pauseCount = 1
        raycastFoundSurfacePos = nil
        if testStartIndex > 0 then
          pointIndex = testStartIndex
          targetTravelPos = destinationData.points[pointIndex]
        end
      end
    end
    
    -- Traveling
    if state == "traveling" then
    
      slowTravelUpdateTimer = slowTravelUpdateTimer + dt
      if slowTravelUpdateTimer > 1 then
        slowTravelUpdateTimer = 0
        print(tostring(pointIndex) .. " / " .. tostring(#destinationData.points))
      end
      
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
          end
        end
        
      end

      local speed = travelSpeed
      if (dt == 0) then speed = 0 end

      -- FOR TESTING REMOVE IN FINAL
      --if input_jump then speed = 32 end
      -- FOR TESTING REMOVE IN FINAL
      
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
          local lowestHeight = core.land.getHeightAt(targetTravelPos, player.cell) + 1200
          if targetTravelPos.z < lowestHeight then
            targetTravelPos = util.vector3(targetTravelPos.x,targetTravelPos.y,lowestHeight)
          end
        end
        if playerRiding then 
          player:teleport('', targetTravelPos) 
        end
      end

      -- Rotate and Move Silt Strider
      local striderRotTarget = math.atan2(striderDir.y, striderDir.x) - 1.5708
      striderRot = striderRot + ((striderRotTarget - striderRot + math.pi) % (2*math.pi) - math.pi) * dt * math.max(1, striderMaxSpeed / 8)
      if playerDriving and playerRiding then striderRot = striderRot + input_moveL * .005 end
      if playerDriving and playerRiding then striderRot = striderRot - input_moveR * .005 end
      strider:teleport('', targetTravelPos + util.vector3(0,0,-1300), util.transform.rotateZ(-striderRot))

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
        player:sendEvent('SetPlayerIsTraveling', { isTraveling = false } )
        state = "none"
        renableObjects()
        
        -- Stop any abnormal weather
        local w = core.weather.getCurrent(world.players[1].cell).recordId
        if (w == "ashstorm" or w == "blight" or w == "blizzard" or w == "snow") then
          for _, region in ipairs(core.regions.records) do
            core.weather.changeWeather(region.id, core.weather.records['clear'])
          end
        end
        
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
  end
end

local function enableDisableObject(data) 
  local obj = data["obj"]
  if (obj == strider) then return end
  local isActive = data["isActive"]
  obj.enabled = isActive
  if not isActive then table.insert(disabledObjs, obj) end
end

local function startPlayerLerpToPos(data) 
  lerpToPosStart = data.start
  lerpToPosTarget = data.target
  lerpToPosTimer = 1
end

local function playerJumpOffStriderEarly(data) 
  local moveDir = rotToFwd(strider.rotation):cross(util.vector3(0,0,1))
  lerpToPosStart = world.players[1].position + moveDir * 300
  lerpToPosTimer = 1
  world.players[1]:sendEvent('RaycastToFindSurface', { 
    from = lerpToPosStart,
    to = util.vector3(lerpToPosStart.x,lerpToPosStart.y,lerpToPosStart.z - 5000) 
  })
  playerRiding = false 
  world.players[1]:sendEvent('SetPlayerIsTraveling', { isTraveling = false } )
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
  camForward = data.camForward
  input_moveFwd = data.moveFwd
  input_moveL = data.moveL
  input_moveR = data.moveR
  input_jump = data.jump
end

local function setRaycastFoundSurface(data) 
  raycastFoundSurfacePos = data.hitPos
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onObjectActive = function(object) 
          if state == "traveling" and object.recordId == "a_siltstrider" then
              enableDisableObject( { obj = object, isActive = false } )
          end
        end
    },
    eventHandlers = { 
      StartTravel = startTravel,
      SetActiveTravelData = setActiveTravelData,
      EnableDisableObject = enableDisableObject,
      PlayerJumpOffStriderEarly = playerJumpOffStriderEarly,
      TeleportActorToPos = teleportActorToPos,
      ReducePlayersGold = reducePlayersGold,
      LoadUserSettings = loadUserSettings,
      SetPlayerInputs = setPlayerInputs,
      SetRaycastFoundSurface = setRaycastFoundSurface,
    }
}