local Util = require("CraftingFramework.util.Util")
local Craftable = require("CraftingFramework.components.Craftable")
local logger = Util.createLogger("CraftingEvents")

local function craftableActivated(e)
    logger:trace("craftableActivated object id: %s", e.reference.baseObject.id)
    local craftable = Craftable.getPlacedCraftable(e.reference.baseObject.id:lower())
    if craftable then
        logger:trace("craftableActivated placedObject id: %s", craftable:getPlacedObjectId())
        if Util.isShiftDown() and Util.canBeActivated(e.reference) then
            e.reference.data.allowActivate = true
            tes3.player:activate(e.reference)
            e.reference.data.allowActivate = nil
        else
            craftable:activate(e.reference)
        end
    end
end
event.register("CraftingFramework:CraftableActivated", craftableActivated)


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
