local Util = require("CraftingFramework.util.Util")
local Craftable = require("CraftingFramework.components.Craftable")
local StaticActivator = require("CraftingFramework.components.StaticActivator")
local Indicator = require("CraftingFramework.components.Indicator")
local logger = Util.createLogger("CraftingEvents")

---@param e itemDroppedEventData
local function itemDropped(e)
    local craftable = Craftable.getCraftable(e.reference.baseObject.id)
    if not craftable then return end
    logger:debug("Craftable: %s", craftable and craftable.id)
    local placedObject = craftable and craftable:getPlacedObjectId()
    logger:trace("craftable.placedObject: %s", craftable.placedObject)
    logger:trace("placedObject: %s", placedObject)
    if placedObject then
        logger:trace("placedObject: " .. placedObject)
        if placedObject and e.reference.baseObject.id:lower() == craftable.id then
            logger:debug("itemDropped placedObject: " .. placedObject)
            craftable:swap(e.reference)
        end
    end
end
event.register("itemDropped", itemDropped)

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
        duration = 0.1,
        type = timer.real,
        iterations = -1,
        callback = function()
            StaticActivator.callRayTest{
                eventName = "CraftingFramework:StaticActivatorIndicator"
            }
        end
    }
end
event.register("loaded", startIndicatorTimer)

local function triggerActivateKey(e)
    if (e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 0) then
        StaticActivator.doTriggerActivate()
    end
end
event.register("keyDown", triggerActivateKey, { priority = 50})

local function triggerActivateMouse(e)
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
    if indicator and not indicator:doBlockNonCrafted() then
        indicator:additionalUI(e.tooltip)
    end
end
event.register(tes3.event.uiObjectTooltip, doAdditionalUI)
