local core = require("openmw.core")
local T = require("openmw.types")
local I = require("openmw.interfaces")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mConvert = require("scripts.fresh-loot.loot.convert")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local protectedBeastsActorIds = {}

local module = {}

local function addProtectedBeastsHandler(state)
    I.ItemUsage.addHandlerForType(T.Armor, function(armor, actor)
        local item = state.items[armor.id]
        if not item then return end
        return I.protectedbeasts.onArmorEquip(armor, actor, item.oldRecordId, function(recordId)
            local record = mConvert.convertItemRecordId(state, armor, recordId)
            return record and record.id
        end)
    end)
end

-- Protected Beasts' actor equipped event
module.onPBArmorEquipped = function(state, actor, oldItem, newItem, pbRecordId)
    log(string.format("Protected Beasts: Actor \"%s\" equipped", actor.recordId))

    if protectedBeastsActorIds[actor.recordId] then
        protectedBeastsActorIds[actor.recordId] = nil
        core.sendGlobalEvent(mDef.events.onActorActive, actor)
        return
    end

    if not oldItem or not newItem or not pbRecordId then return end

    local itemData = state.items[oldItem.id]
    if not itemData then
        log(string.format("Protected Beasts: The item \"%s\" is not an FL item", oldItem.recordId))
        return
    else
        log(string.format("Protected Beasts: Replacing state item %s (PB ID \"%s\") with %s for actor \"%s\"",
                oldItem, pbRecordId, newItem, actor.recordId))
    end
    state.items[newItem.id] = mTypes.new.itemData(newItem, itemData.oldCount, pbRecordId, itemData.lvlModIds)
    state.items[oldItem.id] = nil
end

module.isActorEquipmentReady = function(actor)
    return not protectedBeastsActorIds[actor.recordId]
end

module.onPlayerAdded = function(state)
    if I.protectedbeasts and I.protectedbeasts.version >= 1.1 then
        protectedBeastsActorIds = mHelpers.addAllToMap({}, I.protectedbeasts.npcsToDress) or {}
        addProtectedBeastsHandler(state)
    end
end

return module
