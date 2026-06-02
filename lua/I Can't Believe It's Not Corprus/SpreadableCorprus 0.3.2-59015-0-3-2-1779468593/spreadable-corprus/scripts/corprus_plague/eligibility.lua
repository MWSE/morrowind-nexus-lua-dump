local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')
local actorRef = require('scripts.corprus_plague.actor_ref')

local M = {}

function M.isNpcActor(actor)
    if not actor or not actor:isValid() then
        return false
    end
    if not types.NPC.objectIsInstance(actor) then
        return false
    end
    if types.Player.objectIsInstance(actor) then
        return false
    end
    return true
end

function M.isImmune(actor)
    local recordId = actor.recordId

    if config.immuneRecordIds[recordId] then
        return true
    end

    if config.immuneSleeperRecordIds[recordId] then
        return true
    end

    local npcRecord = types.NPC.record(recordId)
    if npcRecord and config.immuneClasses[npcRecord.class] then
        return true
    end

    for _, factionId in pairs(types.NPC.getFactions(actor)) do
        if config.immuneFactions[factionId] then
            return true
        end
    end

    return false
end

function M.canInfect(actor, storageApi)
    if not M.isNpcActor(actor) then
        return false
    end
    if M.isImmune(actor) then
        return false
    end
    local plagueKey = actorRef.getPlagueKey(actor)
    if not plagueKey then
        return false
    end
    if storageApi.isInfected(plagueKey) or storageApi.isTransformed(plagueKey) then
        return false
    end
    return true
end

return M
