-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20200123) then
    local function warning()
        tes3.messageBox(
            "[Enhanced Telekinesis ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
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
  [tes3.effect.invisibility] = true,
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
  local controllers = dofile("Data Files\\MWSE\\mods\\OperatorJack\\EnhancedInvisibility\\controllers.lua")

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
  timerController:init()

  print("[Enhanced Invisibility: INFO] Initialized.")
end
event.register("loaded", onLoaded)
-------------------------