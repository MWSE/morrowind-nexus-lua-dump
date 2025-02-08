local Util = require("CraftingFramework.util.Util")
local Craftable = require("CraftingFramework.components.Craftable")
local StaticActivator = require("CraftingFramework.components.StaticActivator")
local Indicator = require("CraftingFramework.components.Indicator")
local logger = Util.createLogger("CraftingEvents")
local RefDropper = require("CraftingFramework.components.RefDropper")

---@param e itemDroppedEventData
event.register("itemDropped", function(e)
    local refSwapper = RefDropper.registeredRefDroppers[e.reference.baseObject.id:lower()]
    if not refSwapper then return end
    logger:debug("RefDropper: %s", refSwapper.droppedObjectId)
    logger:debug("replacerId: %s", refSwapper.replacerId)
    refSwapper:drop(e.reference)
    return true
end, { priority = -300 })


event.register("CraftingFramework:EndPlacement", function(e)
    local reference = e.reference
    local craftable = Craftable.getCraftable(e.reference.baseObject.id)
    if not craftable then return end
    if craftable.positionCallback then
        craftable:positionCallback{ reference = reference}
    end
end)

local function startIndicatorTimer()
    logger:debug("Starting activation indicator timer")
    timer.start{
        duration = 0.15,
        type = timer.real,
        iterations = -1,
        callback = function()
            StaticActivator.updateIndicator{
                eventName = "CraftingFramework:StaticActivatorIndicator"
            }
        end
    }
end
event.register("loaded", startIndicatorTimer)

local controlsAreDisabled = function()
    return tes3.player
        and tes3.player.mobile
        and tes3.player.mobile.controlsDisabled
end

local function triggerActivateKey(e)
    if controlsAreDisabled() then return end
    if (e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 0) then
        StaticActivator.doTriggerActivate()
    end
end
event.register("keyDown", triggerActivateKey, { priority = 50})

local function triggerActivateMouse(e)
    if controlsAreDisabled() then return end
    if (e.button == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 1) then
        StaticActivator.doTriggerActivate()
    end
end
event.register("mouseButtonUp", triggerActivateMouse, { priority = 50})

local function blockActivate(e)
    if e.activator ~= tes3.player then return end
    if e.target.data and e.target.data.crafted then
        if not e.target.data.allowActivate then
            logger:debug("Crafted, block activation")
            return false
        end
    end
end
event.register("activate", blockActivate)

---@param e uiObjectTooltipEventData
local function doAdditionalUI(e)
    local indicator = Indicator:new{
        reference = e.reference,
        item = e.object,
        itemData = e.itemData,
    }
    if indicator and indicator.additionalUI and not indicator:doBlockNonCrafted() then
        indicator:additionalUI(e.tooltip)
    end
end
event.register(tes3.event.uiObjectTooltip, doAdditionalUI)
