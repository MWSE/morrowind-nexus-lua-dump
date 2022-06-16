--[[
-- Sepulchral Curses
-- by inpv, 2020-2022
]]

local config = require("inpv.Sepulchral Curses.config")
local data = require("inpv.Sepulchral Curses.data")

local stalhrimVeinActivated = false
local onSolstheim = false
local eventActor = nil

--[[ OBJECT VALIDATION ]]

local function checkTable(matchName, table) -- matching against respective object list
  local isMatched = false

    for i, match in ipairs(table) do
      if string.find(matchName, match) then
        isMatched = true
        break
      end
    end

  return isMatched
end

local function checkSpawn(e) -- check if the object can spawn undead at all
  local canSpawn = false

  if config.includeMiscObjects == true then
    if checkTable(e.target.object.id, data.miscObjectsMatchList) then -- what other objects can spawn undead?
      canSpawn = true
    end
  end

  if canSpawn == false then
    if (e.target.object.objectType == tes3.objectType.container) then -- is it even a container?
      if checkTable(e.target.object.id, data.objectsList) then
        canSpawn = true
      end
    end
  end

  return canSpawn
end

--[[ CREATURE SPAWNING ]]

local function isCreatureSpawned() -- calculates the spawn chance
  local isSpawned
  local openActor = eventActor.mobile
  if openActor == nil then return end -- just in case
  local openActorLuck = openActor.luck.current -- how lucky the actor is not to disturb the dead
  local openActorAgility = openActor.agility.current -- how carefully the actor opens the container

  if config.upperBorder <= config.lowerBorder then
    tes3.messageBox("Incorrect border values, settings restored to default (70-75)")
    config.lowerBorder = 70
    config.upperBorder = 75
  end

  local baseChance = math.random(config.lowerBorder, config.upperBorder)
  local triggerChance = math.random(100)
  local safeChance = baseChance + math.floor(openActorLuck / 10) + math.floor(openActorAgility / 10)

  if triggerChance <= safeChance then
    isSpawned = false
  else
    isSpawned = true
  end

  return isSpawned
end

local function spawnCreature() -- spawns the appropriate monster

  local creatureName

  local function spawnUndead()
    if config.easyMode == true then
      creatureName = tes3.getObject(data.leveledRevenantList[math.random(1, #data.leveledRevenantList)]):pickFrom()
    else
      creatureName = data.revenantList[math.random(1, #data.revenantList)]
    end

    if config.displayMessages == true then
      tes3.messageBox(data.revenantTauntList[math.random(1, #data.revenantTauntList)])
      tes3.messageBox(data.environmentalEffectList[math.random(1, #data.environmentalEffectList)])
    end

    tes3.playSound{ soundPath = "Fx\\magic\\conjH.wav" }
    tes3.playSound{ soundPath = "Fx\\magic\\destH.wav" }
  end


  if onSolstheim then
    if config.spawnFrostDaedra == true then
      creatureName = data.bmCreatureList[math.random(1, #data.bmCreatureList)]

      if (stalhrimVeinActivated) then
        if config.displayMessages == true then
          tes3.messageBox(data.bmEnvironmentalEffectListStalhrim[math.random(1, #data.bmEnvironmentalEffectListStalhrim)])
        end
        tes3.playSound{ soundPath = "Fx\\inpv\\SepulchralCurses\\NordicPickStalhrimHit.wav" }
      else
        if config.displayMessages == true then
          tes3.messageBox(data.bmEnvironmentalEffectList[math.random(1, #data.bmEnvironmentalEffectList)])
        end
      end

      tes3.playSound{ soundPath = "Fx\\magic\\conjH.wav" }
      tes3.playSound{ soundPath = "Fx\\magic\\frstH.wav" }
    else
      if stalhrimVeinActivated == false then
        spawnUndead()
      end
    end
  else
    spawnUndead()
  end

  mwscript.placeAtPC{ reference = tes3.player, object = creatureName, direction = 1, distance = 100, count = 1 }
end

local function doSpawn()
  if isCreatureSpawned() then
    spawnCreature()
  end
end

--[[ LOCKS AND TRAPS DETECTION ]]

local function writeNodeData(e) -- write the lockNode first to later find whether the player has the key for this container
  if e.target.lockNode == nil then
    -- no lock, so no need to write
  else
    if e.target.data.SepulchralCurses == nil then -- only write for traps that are not activated yet
      e.target.data.SepulchralCurses = {lockData = e.target.lockNode}
    end
  end
end

local function checkActivated(e)
  local trapActivated = false

  if e.target.data.SepulchralCurses == nil then
  elseif e.target.data.SepulchralCurses.activated == true then
    trapActivated = true
  end

  return trapActivated
end

local function checkTrapped(e) -- check the trapped container status
  local isTrapped = false

  if e.target.lockNode == nil
  or e.target.lockNode.trap == nil then
    -- no lock or not trapped, pass
  elseif e.target.lockNode.trap ~= nil then
    isTrapped = true
  end

  return isTrapped
end

local function checkKey(e) -- check if the player has the key for this container
  local hasKey = false

  if e.target.data.SepulchralCurses == nil
  or e.target.data.SepulchralCurses.lockData == nil then
    -- no lock or not activated yet, pass
  else
    if tes3.getItemCount({reference = tes3.player, item = e.target.data.SepulchralCurses.lockData.key}) == 0 then
    elseif tes3.getItemCount({reference = tes3.player, item = e.target.data.SepulchralCurses.lockData.key}) >= 1 then
      hasKey = true
    end
  end

  return hasKey
end

local function checkTrappedAndKey(e)
  if checkTrapped(e) == true then -- let the vanilla trap activate first
  else
    if checkKey(e) == true then -- no trap + let the player open freely
    else
      if checkActivated(e) == false then
        doSpawn()
      else
        -- the SC trap has already been activated
      end
    end
  end
end

local function activateStalhrimVeinTrap(e)
  stalhrimVeinActivated = true -- activate the vein

  if checkActivated(e) == false then
    doSpawn()
  else
    -- the vein has already been activated
  end
end

local function markAsActivated(e)
  if e.target.data.SepulchralCurses == nil then -- mark container as activated before deciding to spawn
    e.target.data.SepulchralCurses = {activated = true}
  elseif e.target.data.SepulchralCurses.activated == true then
    -- the trap has already been activated
  end
end

--[[ MAIN EVENT ]]
local function onActivate(e)

  if not config.enabled then return end

  local cell = tes3.getPlayerCell()
  eventActor = e.activator

  if (eventActor == tes3.player)
  or (eventActor == tes3.npc)
  or (eventActor == tes3.creature) then -- NPCs and creature companions are no exception

    if (cell.isInterior) then
      onSolstheim = checkTable(cell.name, data.bmLocationsMatchList)
      if onSolstheim == true then
        if checkSpawn(e) then -- maybe it's a container?
          if stalhrimVeinActivated then
            stalhrimVeinActivated = false -- to display the right messages on spawn
          end
          writeNodeData(e)
          checkTrappedAndKey(e)
          markAsActivated(e)
        else -- then it's probably a Stalhrim vein
          if string.find(e.target.object.name, "Stalhrim") and tes3.getItemCount({reference = eventActor, item = "bm nordic pick"}) ~= 0 then
            if config.pickEquippedOnly == true then
              if mwscript.hasItemEquipped({reference = eventActor, item = "bm nordic pick"}) then
                activateStalhrimVeinTrap(e)
                markAsActivated(e)
              else
                if e.target.data.SepulchralCurses == nil then
                  if (eventActor == tes3.player) then
                    tes3.messageBox("You don't have a pick in your hands.")
                  elseif (eventActor == tes3.npc) or (eventActor == tes3.creature) then
                    tes3.messageBox(eventActor.object.name .. " doesn't have a pick readied.")
                  end
                  return false
                else
                -- the grave has been unsealed, so the player doesn't need a pick anymore
                end
              end
            else
              activateStalhrimVeinTrap(e)
              markAsActivated(e)
            end
          end
        end
      else
        if checkTable(cell.name, data.locationsMatchList) then
          if checkSpawn(e) then
            writeNodeData(e)
            checkTrappedAndKey(e)
            markAsActivated(e)
          end
        end
      end
    end
  end
end

require("inpv.Sepulchral Curses.mcm")
event.register("activate", onActivate)
