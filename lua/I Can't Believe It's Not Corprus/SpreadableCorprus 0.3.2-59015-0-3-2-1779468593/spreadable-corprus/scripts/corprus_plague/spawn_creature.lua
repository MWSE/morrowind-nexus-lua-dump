local types = require('openmw.types')
local world = require('openmw.world')

local M = {}

function M.getNpcDisplayName(actor)
    local npcRecord = types.NPC.record(actor.recordId)
    if npcRecord and npcRecord.name and npcRecord.name ~= '' then
        return npcRecord.name
    end
    return actor.recordId
end

function M.create(creatureTemplateId, displayName)
    local id = string.lower(creatureTemplateId)
    local template = types.Creature.records[id]
    if not template then
        template = types.Creature.record(id)
    end

    if template then
        local ok, creature = pcall(function()
            local recordDraft = types.Creature.createRecordDraft({
                name = displayName,
                template = template,
            })
            local newRecord = world.createRecord(recordDraft)
            return world.createObject(newRecord.id)
        end)
        if ok and creature then
            creature.enabled = true
            if creature:isValid() then
                return creature
            end
        end
    end

    local creature = world.createObject(id)
    if creature then
        creature.enabled = true
    end
    if not creature or not creature:isValid() then
        error('failed to spawn creature: ' .. id)
    end
    return creature
end

return M
