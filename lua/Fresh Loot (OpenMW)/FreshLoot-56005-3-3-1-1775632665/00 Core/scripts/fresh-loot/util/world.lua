local T = require("openmw.types")
local world = require("openmw.world")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mT = require("scripts.fresh-loot.config.types")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

module.getActiveActors = function()
    return world.activeActors
end

local function getClosestPlayer(actor)
    local closestPlayer
    local minDist = math.huge
    for _, player in ipairs(world.players) do
        if actor.cell:isInSameSpace(player) then
            local dist = (actor.position - player.position):length()
            if dist < minDist then
                closestPlayer = player
                minDist = dist
            end
        end
    end
    return closestPlayer
end

module.getActiveCells = function()
    local singleActorPerCell = {}
    for _, actor in ipairs(world.activeActors) do
        singleActorPerCell[actor.cell.id] = actor
    end
    local activeCells = {}
    for _, actor in pairs(singleActorPerCell) do
        table.insert(activeCells, mT.new.cellData(actor.cell, getClosestPlayer(actor)))
    end
    return activeCells
end

module.getPlayerLevel = function()
    return mHelpers.average(world.players, function(player) return T.Actor.stats.level(player).current end)
end

module.sendPlayersEvent = function(data)
    for _, player in ipairs(world.players) do
        player:sendEvent(data.event, data.data or player)
    end
end

module.createRecord = function(type, recordPatch, recordBase)
    recordPatch.template = recordBase
    return world.createRecord(type.createRecordDraft(recordPatch))
end

module.replaceItem = function(container, item, record, removeCount, newRecord, newCount)
    local slot
    if container and container.type ~= T.Container then
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
    item:remove(removeCount)
    return mT.new.inventoryItem(newItem, slot, valueDiff)
end

module.attachScript = function(object, scriptPath)
    if not object:hasScript(scriptPath) then
        object:addScript(scriptPath)
    else
        log(string.format("Object \"%s\" already has the script \"%s\" attached", object, scriptPath))
    end
end

module.detachScript = function(object, scriptPath)
    if object:hasScript(scriptPath) then
        object:removeScript(scriptPath)
    else
        log(string.format("Object \"%s\" did not have the script \"%s\" attached", object, scriptPath))
    end
end

module.equipItems = function(actor, items)
    module.attachScript(actor, mDef.scripts.actorEquip)
    actor:sendEvent(mDef.events.equipItems, items)
end

module.requestActorStats = function(actor, responseEvent)
    module.attachScript(actor, mDef.scripts.actorGetStats)
    actor:sendEvent(mDef.events.getActorStats, responseEvent)
end

return module