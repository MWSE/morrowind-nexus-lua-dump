local types = require('openmw.types')
local dispositionModifier = require('scripts.corprus_plague.disposition_modifier')
local storageApi = require('scripts.corprus_plague.storage')
local actorRef = require('scripts.corprus_plague.actor_ref')

local M = {}

local function roundDisposition(value)
    return math.floor(value + 0.5)
end

local function targetPenalty(modifierOverride)
    local infections = storageApi.getInfectionCount()
    if infections <= 0 then
        return 0
    end
    return infections * dispositionModifier.getPerInfection(modifierOverride)
end

local function recordTemplateBaseline(actor)
    local record = types.NPC.record(actor.recordId)
    if record and type(record.baseDisposition) == 'number' then
        return record.baseDisposition
    end
    return nil
end

-- One-time natural disposition before plague penalty (stored permanently per NPC).
local function inferInitialBaseline(actor, current, plagueKey, target)
    local peak = storageApi.getDispositionPeakPenalty(plagueKey)
    local hasHistory = storageApi.hasDispositionHistory(plagueKey)

    if hasHistory and (peak > 0 or target > 0) then
        -- At 0: recover using historical peak penalty; otherwise undo the last target we applied.
        if current <= target then
            return current + math.max(peak, target)
        end
        return current + target
    end

    local baseline = current
    local templateBase = recordTemplateBaseline(actor)
    if templateBase and templateBase > baseline then
        baseline = templateBase
    end
    return baseline
end

local function ensureBaseline(actor, player, plagueKey, target)
    local stored = storageApi.getDispositionBaseline(plagueKey)
    if stored ~= nil then
        return stored
    end

    local current = types.NPC.getBaseDisposition(actor, player)
    local baseline = inferInitialBaseline(actor, current, plagueKey, target)
    storageApi.setDispositionBaseline(plagueKey, baseline)
    return baseline
end

function M.applyInfectionPenalty(actor, player, modifierOverride)
    if not actor or not actor:isValid() or not player or not player:isValid() then
        return
    end
    local plagueKey = actorRef.getPlagueKey(actor)
    if not plagueKey then
        return
    end

    local target = targetPenalty(modifierOverride)
    storageApi.raiseDispositionPeakPenalty(plagueKey, target)

    local baseline = ensureBaseline(actor, player, plagueKey, target)
    if baseline == nil then
        return
    end

    local desired = math.max(0, roundDisposition(baseline - target))
    local current = roundDisposition(types.NPC.getBaseDisposition(actor, player))

    if current ~= desired then
        types.NPC.setBaseDisposition(actor, player, desired)
    end

    storageApi.setDispositionPenalty(plagueKey, target)
end

return M
