local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local playerSettings = storage.globalSection("SettingsDebugMode")
local disableNPCs = false
local alreadyTPedPlayer = false

local function getInventory(object)

    --Quick way to get the inventory of an object, regardless of type
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
    return nil--Not any of the above types, so no inv
end


local function ZackUtilsAddItem(data)
    local item = world.createObject(data.itemId, data.count)
    print(data.actor.recordId)
    local inv = getInventory(data.actor)
    item:moveInto(types.Actor.inventory(data.actor))
    if (data.equip == true) then
        data.actor:sendEvent("addItemEquipReturn", item)
    end
    return item
end
local function removeItemCount(data)
    if (data.itemId ~= nil and data.count > 0) then
        local inv = types.Actor.inventory(data.actor)
        local item = inv:find(data.itemId)
        if (item ~= nil) then
            item:remove(data.count)
        end
    end
end
local function itemSwapEvent(data)
local actorToRemove = data.actorToRemove
local newItem = data.newItem
local swappingItem = data.swappingItem
removeItemCount({itemId = swappingItem,count = 1,actor = actorToRemove})
local newItem = ZackUtilsAddItem({itemId = newItem,count = 1,actor = actorToRemove})
actorToRemove:sendEvent("equipNewItem",newItem)
end

return {
    interfaceName  = "ClothingSwap",
    interface      = {
      version = 1,
    },
    engineHandlers = {
    },
    eventHandlers  = {
        itemSwapEvent = itemSwapEvent,
    },
  }
  