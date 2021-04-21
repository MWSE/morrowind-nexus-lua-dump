--[[
-- Sepulchral Curses
-- by inpv, 2020
]]

--[[ DATA ]]
local configPath = "sepulchralcurses"
local config = mwse.loadConfig(configPath)
local stalhrimVeinActivated = false
local onSolstheim = false

if (config == nil) then
	config = { enabled = true, spawnFrostDaedra = false, pickEquippedOnly = true }
end

local revenantList = {
  "ancestor_ghost",
  "bonelord",
  "bonewalker",
  "Bonewalker_Greater",
  "skeleton",
  "skeleton archer",
  "skeleton warrior",
  "skeleton champion"
}

local bmCreatureList = {
  "atronach_frost"
}

local revenantTauntList = {
  "Who dares to defile the place of my final resting? Now die!",
  "Who interrupts my eternal slumber? Die!",
  "You'll join me soon enough, mortal."
}

local environmentalEffectList = {
  "[A grave chill gives you creeping horripilation as you feel a revenant appear behind you]",
  "[A sudden gust of ice cold wind causes you to freeze for a second]",
  "[A disturbing presence emerges right behind you]"
}

local bmEnvironmentalEffectList = {
  "[You open the chest and feel even colder than before]",
  "[A thin frosty crust starts to appear on the floor as you open the chest]",
  "[As you open the chest, you notice the fires inside the barrow has gone dim]"
}

local bmEnvironmentalEffectListStalhrim = {
  "[As you wave your pick, it gets stuck in the ice. You're not alone here]",
  "[You feel an alien emanation slipping through the cracks and manifesting behind you]",
  "[A cold burst springs from the stalhrim vein]"
}

--[[ HELPER FUNCTIONS ]]
local function isCreatureSpawned()
  local isSpawned
  local playerLuck = tes3.mobilePlayer.luck.current -- how lucky the player is not to disturb the dead
  local playerAgility = tes3.mobilePlayer.agility.current -- how carefully the player opens the container

  local baseChance = math.random(70, 75)
  local triggerChance = math.random(100)
  local safeChance = baseChance + math.floor(playerLuck / 10) + math.floor(playerAgility / 10)

  if triggerChance <= safeChance then
    isSpawned = false
  else
    isSpawned = true
  end

  return isSpawned
end

local function spawnCreature()

  local creatureName

  local function spawnUndead()
    creatureName = revenantList[math.random(1, #revenantList)]

    tes3.messageBox(revenantTauntList[math.random(1, #revenantTauntList)])
    tes3.messageBox(environmentalEffectList[math.random(1, #environmentalEffectList)])

    tes3.playSound{ soundPath = "Fx\\magic\\conjH.wav" }
    tes3.playSound{ soundPath = "Fx\\magic\\destH.wav" }
  end

  if config.spawnFrostDaedra == true then
    if onSolstheim then
      creatureName = bmCreatureList[math.random(1, #bmCreatureList)]

      if (stalhrimVeinActivated) then
        tes3.messageBox(bmEnvironmentalEffectListStalhrim[math.random(1, #bmEnvironmentalEffectListStalhrim)])
        tes3.playSound{ soundPath = "Fx\\inpv\\SepulchralCurses\\NordicPickStalhrimHit.wav" }
      else
        tes3.messageBox(bmEnvironmentalEffectList[math.random(1, #bmEnvironmentalEffectList)])
      end

      tes3.playSound{ soundPath = "Fx\\magic\\conjH.wav" }
      tes3.playSound{ soundPath = "Fx\\magic\\frstH.wav" }
    else
      spawnUndead()
    end
  else
    spawnUndead()
  end

  mwscript.placeAtPC{ reference = tes3.player, object = creatureName, direction = 1, distance = 100, count = 1 }
end

--[[ REPETITION REDUCERS ]]
local function doSpawn(e)
  if e.target.data.SepulchralCurses == nil then
    e.target.data.SepulchralCurses = {activated = true}
    if isCreatureSpawned() then
      spawnCreature()
    end
  elseif e.target.data.SepulchralCurses.activated == true then
    -- the trap has already been activated
  end
end

local function checkLockedAndSpawn(e)
  if (tes3.getLocked({ reference = e.target })) then
    return false -- ignoring locked containers
  else
    doSpawn(e)
  end
end

local function findTombSpawn(e, cell)
  if string.find(e.target.object.name, "Urn") or string.find(e.target.object.name, "Chest") then
    if string.find(cell.name, "Tomb") or string.find(cell.name, "Ancestral Vault") or string.find(cell.name, "Burial Cavern") then
      checkLockedAndSpawn(e)
    end
  end
end

--[[ MAIN EVENT ]]
local function onActivate(e)

  if not config.enabled then return end

  local cell = tes3.getPlayerCell()

  if (e.activator == tes3.player) then
    if (cell.isInterior) then
      if config.spawnFrostDaedra == true then
        if string.find(cell.name, "Barrow") or string.find(cell.name, "Tombs of Skaalara") or string.find(cell.name, "Glenschul's Tomb") or string.find(cell.name, "Gandrung Caverns") then
          onSolstheim = true
          if string.find(e.target.object.name, "Chest") then
            if stalhrimVeinActivated then
              stalhrimVeinActivated = false
            end
            checkLockedAndSpawn(e)
          elseif string.find(e.target.object.name, "Stalhrim") and mwscript.getItemCount({reference = tes3.player, item = "bm nordic pick"}) ~= 0 then
            if config.pickEquippedOnly == true then
              if mwscript.hasItemEquipped({reference = tes3.player, item = "bm nordic pick"}) then
                stalhrimVeinActivated = true
                doSpawn(e)
              else
                if e.target.data.SepulchralCurses == nil then
                  tes3.messageBox("You don't have a pick in your hands.")
                  return false
                else
                -- the grave has been unsealed, so the player doesn't need a pick anymore
                end
              end
            else
              stalhrimVeinActivated = true
              doSpawn(e)
            end
          end
        else
          onSolstheim = false
          findTombSpawn(e, cell)
        end
      else
        findTombSpawn(e, cell)
      end
    end
  end
end

event.register("activate", onActivate)

--[[ MCM ]]
local function registerModConfig()
    local mcm = require("mcm.mcm")

    local sidebarDefault = (
        "Makes robbing tombs and barrows harder by adding a chance of summoning a random angry undead/elemental daedra when opening burial containers."
    )

    local template = mcm.createTemplate("Sepulchral Curses")
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage{
        description = sidebarDefault
    }

    page:createOnOffButton{
        label = "Enable Sepulchral Curses",
        variable = mcm.createTableVariable{
            id = "enabled",
            table = config
        },
        description = "Turn this mod on or off."
    }

    page:createOnOffButton{
      label = "Frost Atronachs on Solstheim",
      variable = mcm.createTableVariable{
          id = "spawnFrostDaedra",
          table = config
      },
      description = "Adds Frost Atronachs to Solstheim barrows."
    }

    page:createOnOffButton{
      label = "Stalhrim mining overhaul",
      variable = mcm.createTableVariable{
          id = "pickEquippedOnly",
          table = config
      },
      description = "Stalhrim deposits can only be mined with pick equipped."
    }

    template:register()
end

event.register("modConfigReady", registerModConfig)
