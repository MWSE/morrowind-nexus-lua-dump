local world = require('openmw.world')
local T = require('openmw.types')

local log = require('scripts.HBFS.util.log')
local mDef = require('scripts.HBFS.config.definition')
local mTools = require('scripts.HBFS.util.tools')

local module = {}

module.forwardToPlayers = function(data, event)
    for _, player in ipairs(world.players) do
        player:sendEvent(event, data)
    end
end

module.moveItem = function(item, actor)
    log(string.format("Item %s moved into %s's inventory", mTools.objectId(item), mTools.objectId(actor)))
    item:moveInto(actor.type.inventory(actor))
end

module.modItemCondition = function(updates, refreshUi)
    for _, update in ipairs(updates) do
        T.Item.itemData(update.item).condition = update.condition
    end
    if refreshUi then
        refreshUi.player:sendEvent(mDef.events.refreshUiMode, { mode = refreshUi.mode, target = refreshUi.target })
    end
end

module.fixObjects = function(dataLists)
    for key, dataList in pairs(dataLists) do
        local invalidCt, changedIdCt = 0, 0
        for id, data in pairs(dataList) do
            if mTools.isObjectInvalid(data.object) then
                invalidCt = invalidCt + 1
                dataList[id] = nil
            elseif id ~= data.object.id then
                changedIdCt = changedIdCt + 1
                dataList[id] = nil
                dataList[data.object.id] = data
            end
        end
        if invalidCt + changedIdCt > 0 then
            log(string.format("Cleared %d invalid references and fixed %d changed IDs for %s", invalidCt, changedIdCt, key))
        end
    end
end

return module