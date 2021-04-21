-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20200122) then
  local function warning()
      tes3.messageBox(
          "[Enhanced Detection ERROR] Your MWSE is out of date!"
          .. " You will need to update to a more recent version to use this mod."
      )
  end
  event.register("initialized", warning)
  event.register("loaded", warning)
  return
end
----------------------------

-- Check Magicka Expanded framework --
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Enhanced Detection ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

-- Initial Setup --
require("OperatorJack.EnhancedDetection.effects")
require("OperatorJack.EnhancedDetection.spells")
----------------------------

-- Declare Controllers --
local referenceControllers = nil
local timerController = nil
----------------------------

-- Register Event Handlers --
local function onObjectInvalidated(e)
  local ref = e.object
  for _, referenceController in pairs(referenceControllers) do
    if (referenceController.references[ref] == true) then
      referenceController.references[ref] = nil
    end
  end
end
event.register("objectInvalidated", onObjectInvalidated) 

local effects = {
  [tes3.effect.detectAnimal] = true,
  [tes3.effect.detectEnchantment] = true,
  [tes3.effect.detectKey] = true,
  [tes3.effect.detectDaedra] = true,
  [tes3.effect.detectAutomaton] = true,
  [tes3.effect.detectHumanoid] = true,
  [tes3.effect.detectDead] = true,
  [tes3.effect.detectUndead] = true,
  [tes3.effect.detectDoor] = true,
  [tes3.effect.detectTrap] = true,
}

local function onSpellResist(e)
  if (timerController.active == false and timerController.timer == nil) then
    for _, effect in pairs(e.sourceInstance.source.effects) do
      if (effects[effect.id]) then
        timerController:start()
        return
      end
    end
  end
end
event.register("spellResist", onSpellResist)
-------------------------


-- Register Mod Initialization Event Handler --
local function onLoaded(e)
  -- Clean list of references. This removes vfx from all references when changing saves, if needed.
  local controllers = dofile("Data Files\\MWSE\\mods\\OperatorJack\\EnhancedDetection\\controllers.lua")

  referenceControllers = controllers.referenceControllers
  timerController = controllers.timerController

  for _, referenceController in pairs(referenceControllers) do
    referenceController.visualController:load()
  end

  -- Initialize any active effects. Will auto-stop timer if no effect is active.
  if (timerController.active == true) then
    timerController:cancel()
  end
  timerController.active = false
  timerController:start()

  print("[Enhanced Detection: INFO] Initialized.")
end
event.register("loaded", onLoaded)
-------------------------