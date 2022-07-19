local mod = "Enhanced Detection Lite"
local version = "2.0.1"

-- Initial setup
require("OperatorJack.EnhancedDetection.effects")

-- Declare controllers
local referenceControllers = nil
local timerController = nil

-- Register event handlers
local function onObjectInvalidated(e)
    local ref = e.object
    if not referenceControllers then return end

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

-- Register mod initialization event handler
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
end

event.register("loaded", onLoaded)

local function onInitialized()
    mwse.log("[%s %s] initialized.", mod, version)
end

event.register("initialized", onInitialized)