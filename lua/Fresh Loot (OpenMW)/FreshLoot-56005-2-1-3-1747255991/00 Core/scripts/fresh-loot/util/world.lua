local T = require("openmw.types")
local world = require("openmw.world")

local mTypes = require("scripts.fresh-loot.config.types")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

local function getActiveCells()
    local cellStats = {}
    for _, player in ipairs(world.players) do
        if not cellStats[player.cell.id] then
            cellStats[player.cell.id] = mTypes.new.cellStat(player.cell, player)
        else
            table.insert(cellStats[player.cell.id].players, player)
        end
    end
    return cellStats
end
module.getActiveCells = getActiveCells

local function getPlayerLevel()
    return mHelpers.average(world.players, function(player) return T.Actor.stats.level(player).current end)
end
module.getPlayerLevel = getPlayerLevel

local function sendPlayersEvent(data)
    for _, player in ipairs(world.players) do
        player:sendEvent(data.event, data.data or player)
    end
end
module.sendPlayersEvent = sendPlayersEvent

local function createRecord(type, recordPatch, recordBase)
    recordPatch.template = recordBase
    return world.createRecord(type.createRecordDraft(recordPatch))
end
module.createRecord = createRecord

local function replaceItem(container, item, record, count, newRecord, newCount)
    local slot
    if container and T.Actor.objectIsInstance(container) then
        slot = mObj.getEquippedItemSlot(container, item)
    end
    local newItem = world.createObject(newRecord.id, newCount)
    local condition = T.Item.itemData(item).condition
    if condition then
        local conditionRatio = condition / record.health
        T.Item.itemData(newItem).condition = math.floor(newRecord.health * conditionRatio)
    end
    if container then
        newItem:moveInto(container.type.inventory(container))
    else
        newItem:teleport(item.cell.name, item.position, item.rotation)
    end
    local valueDiff = newRecord.value - record.value
    item:remove(count)
    return mTypes.new.inventoryItem(newItem, slot, valueDiff)
end
module.replaceItem = replaceItem

return module