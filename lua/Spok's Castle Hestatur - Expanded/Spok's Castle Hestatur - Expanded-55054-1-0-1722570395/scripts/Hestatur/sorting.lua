local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local clothingMap = {
    [types.Clothing.TYPE.Amulet] = "zhac_hest_drawer_amulet",
    [types.Clothing.TYPE.Belt] = "zhac_hest_drawer_belts",
    [types.Clothing.TYPE.LGlove] = "zhac_hest_drawer_gloves",
    [types.Clothing.TYPE.RGlove] = "zhac_hest_drawer_gloves",
    [types.Clothing.TYPE.Ring] = "zhac_hest_drawer_rings",
    [types.Clothing.TYPE.Skirt] = "zhac_hest_drawer_skirt",
    [types.Clothing.TYPE.Shirt] = "zhac_hest_drawer_shirts",
    [types.Clothing.TYPE.Shoes] = "zhac_hest_drawer_shoes",
    [types.Clothing.TYPE.Robe] = "zhac_hest_drawer_robes",
    [types.Clothing.TYPE.Pants] = "zhac_hest_drawer_pant"
}
local function getContainerById(cell, contId)
    for index, value in ipairs(cell:getAll(types.Container)) do
        if value.recordId == contId then
            return value
        end
    end
end
local function isEquipped(actor, item)
    for index, value in pairs(types.Actor.getEquipment(actor)) do
        if value == item then
            return true
        end
    end
    return false
end
local function canSortItem(item)
    if isEquipped(world.players[1], item) then
        return false
    end
    return true
end
local function sortKeys(player)
    
    local sorted = 0
    local keyCont = getContainerById(world.getCellByName("Hestatur, Lord's Chambers"), "zhac_hest_cont_keys")
    local inv = types.Actor.inventory(player)
    for index, value in ipairs(inv:getAll(types.Miscellaneous)) do
        if canSortItem(value) then
            local record = value.type.records[value.recordId]
            if record and record.isKey then
                sorted = sorted + value.count
                value:moveInto(keyCont)
            end
        end
    end
    return sorted
end
local function sortClothing(player)
    local sorted = 0
    for key, value in pairs(clothingMap) do
        local cont = getContainerById(world.getCellByName("Hestatur, Lord's Chambers"), value)
        local inv = types.Actor.inventory(player)
        for index, value in ipairs(inv:getAll(types.Clothing)) do
            if canSortItem(value) then
                local record = value.type.records[value.recordId]
                if record and record.type == key then
                    sorted = sorted + value.count
                    value:moveInto(cont)
                end
            end
        end
    end
    return sorted
end
I.Activation.addHandlerForType(types.Activator, function(obj, actor)

    if obj.recordId == "spok_ht_sorter" then
        --print("done")
        return false
    end

end)
local function runItemSort()
    local player = world.players[1]
    local sorted = 0
    if player then
        sorted = sorted +  sortKeys(player)
        sorted = sorted +   sortClothing(player)
    end
    return sorted
end
return {--I.ItemSortHestatur.runItemSort()
    interfaceName = "ItemSortHestatur",
    interface = {
        runItemSort = runItemSort
    },
    eventHandlers = {
        runItemSort =runItemSort,
    }
}