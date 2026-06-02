local storage = require('openmw.storage')
local config = require('scripts.corprus_plague.config')

local SAVE_VERSION = 7

-- Per-save state (round-tripped via global.lua onSave/onLoad). Not in Persistent storage.
local state = {
    infections = {},
    transformed = {},
    pendingTransforms = {},
    firstRestDreamTriggered = false,
    cured = false,
    curePending = false,
    countedInfections = {},
    dispositionPenalties = {},
    dispositionBaselines = {},
    dispositionPeakPenalties = {},
    stats = {
        infections = 0,
    },
}

local legacySection = storage.globalSection(config.storageSection)

local M = {}

local function copyTable(t)
    if type(t) ~= 'table' then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = copyTable(v)
    end
    return copy
end

local function countTable(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function resetInfectionStats()
    state.countedInfections = {}
    state.stats = {
        infections = 0,
    }
end

local function trackUniqueInfection(plagueKey)
    if not plagueKey or state.countedInfections[plagueKey] then
        return false
    end

    state.countedInfections[plagueKey] = true
    state.stats.infections = state.stats.infections + 1
    return true
end

local function rebuildInfectionStats()
    resetInfectionStats()
    for plagueKey in pairs(state.transformed) do
        trackUniqueInfection(plagueKey)
    end
    for plagueKey in pairs(state.infections) do
        trackUniqueInfection(plagueKey)
    end
end

function M.isInfected(plagueKey)
    return plagueKey ~= nil and state.infections[plagueKey] ~= nil
end

function M.isTransformed(plagueKey)
    return M.getTransformEntry(plagueKey) ~= nil
end

function M.getTransformEntry(plagueKey)
    if not plagueKey then
        return nil
    end
    return state.transformed[plagueKey]
end

function M.isTransformPending(plagueKey)
    return plagueKey ~= nil and state.pendingTransforms[plagueKey] ~= nil
end

function M.getInfection(plagueKey)
    if not plagueKey then
        return nil
    end
    return state.infections[plagueKey]
end

function M.markInfected(plagueKey, gameTime)
    if not plagueKey then
        return false
    end
    local wasNew = trackUniqueInfection(plagueKey)
    state.infections[plagueKey] = { infectedAt = gameTime }
    return wasNew
end

function M.clearInfection(plagueKey)
    if not plagueKey then
        return
    end
    state.infections[plagueKey] = nil
end

function M.claimTransform(plagueKey)
    if not plagueKey or M.isTransformed(plagueKey) or M.isTransformPending(plagueKey) then
        return false
    end
    state.pendingTransforms[plagueKey] = true
    return true
end

function M.releaseTransform(plagueKey)
    if not plagueKey then
        return
    end
    state.pendingTransforms[plagueKey] = nil
end

function M.markTransformed(plagueKey, entry)
    if not plagueKey then
        return false
    end
    local wasNew = trackUniqueInfection(plagueKey)
    M.clearInfection(plagueKey)
    M.releaseTransform(plagueKey)
    state.transformed[plagueKey] = entry or {}
    return wasNew
end

function M.getInfectionCount()
    return state.stats.infections
end

function M.isCured()
    return state.cured == true
end

function M.markCured()
    if state.cured then
        return false
    end
    state.cured = true
    return true
end

function M.isCurePending()
    return state.curePending == true
end

function M.setCurePending(pending)
    state.curePending = pending == true
end

function M.clearCurePending()
    state.curePending = false
end

function M.getDispositionPenalty(plagueKey)
    if not plagueKey then
        return 0
    end
    local penalty = state.dispositionPenalties[plagueKey]
    if type(penalty) ~= 'number' then
        return 0
    end
    return penalty
end

function M.setDispositionPenalty(plagueKey, penalty)
    if not plagueKey then
        return
    end
    if type(penalty) ~= 'number' or penalty <= 0 then
        state.dispositionPenalties[plagueKey] = nil
        return
    end
    state.dispositionPenalties[plagueKey] = penalty
end

function M.getDispositionBaseline(plagueKey)
    if not plagueKey then
        return nil
    end
    local baseline = state.dispositionBaselines[plagueKey]
    if type(baseline) ~= 'number' then
        return nil
    end
    return baseline
end

function M.setDispositionBaseline(plagueKey, baseline)
    if not plagueKey then
        return
    end
    if type(baseline) ~= 'number' then
        state.dispositionBaselines[plagueKey] = nil
        return
    end
    state.dispositionBaselines[plagueKey] = baseline
end

function M.hasDispositionHistory(plagueKey)
    if not plagueKey then
        return false
    end
    return state.dispositionBaselines[plagueKey] ~= nil
        or state.dispositionPenalties[plagueKey] ~= nil
        or state.dispositionPeakPenalties[plagueKey] ~= nil
end

-- Upper bound on how much penalty was ever targeted for this NPC (modifier can go down later).
function M.getDispositionPeakPenalty(plagueKey)
    if not plagueKey then
        return 0
    end
    local peak = state.dispositionPeakPenalties[plagueKey]
    if type(peak) ~= 'number' then
        peak = 0
    end
    local penalty = state.dispositionPenalties[plagueKey]
    if type(penalty) == 'number' and penalty > peak then
        peak = penalty
    end
    return peak
end

function M.raiseDispositionPeakPenalty(plagueKey, target)
    if not plagueKey or type(target) ~= 'number' or target <= 0 then
        return
    end
    local peak = M.getDispositionPeakPenalty(plagueKey)
    if target > peak then
        state.dispositionPeakPenalties[plagueKey] = target
    elseif state.dispositionPeakPenalties[plagueKey] == nil and peak > 0 then
        state.dispositionPeakPenalties[plagueKey] = peak
    end
end

-- Best-effort recovery when saves only recorded a low penalty after lowering the modifier.
function M.getPandemicDispositionEstimate()
    if state.stats.infections <= 0 then
        return 0
    end
    return state.stats.infections * config.defaultDispositionModifier
end

function M.getStats()
    return copyTable(state.stats)
end

function M.clearAllPendingTransforms()
    state.pendingTransforms = {}
end

function M.hasFirstRestDreamTriggered()
    return state.firstRestDreamTriggered == true
end

function M.markFirstRestDreamTriggered()
    state.firstRestDreamTriggered = true
end

function M.clearAll()
    state.infections = {}
    state.transformed = {}
    state.pendingTransforms = {}
    state.firstRestDreamTriggered = false
    state.cured = false
    state.curePending = false
    state.dispositionPenalties = {}
    state.dispositionBaselines = {}
    state.dispositionPeakPenalties = {}
    resetInfectionStats()
end

function M.exportForSave()
    return {
        version = SAVE_VERSION,
        infections = copyTable(state.infections),
        transformed = copyTable(state.transformed),
        firstRestDreamTriggered = state.firstRestDreamTriggered,
        cured = state.cured,
        curePending = state.curePending,
        countedInfections = copyTable(state.countedInfections),
        dispositionPenalties = copyTable(state.dispositionPenalties),
        dispositionBaselines = copyTable(state.dispositionBaselines),
        dispositionPeakPenalties = copyTable(state.dispositionPeakPenalties),
        stats = copyTable(state.stats),
    }
end

-- Wipe obsolete Persistent bucket (Pandemic data is per-save via global.lua onSave/onLoad).
function M.purgeLegacyPersistent()
    legacySection:reset({})
end

function M.importFromSave(savedData)
    M.clearAll()
    M.purgeLegacyPersistent()

    if config.clearPlagueDataOnLoad then
        return
    end

    if savedData and type(savedData.version) == 'number' and savedData.version >= 1 and savedData.version <= SAVE_VERSION then
        if type(savedData.infections) == 'table' then
            state.infections = copyTable(savedData.infections)
        end
        if type(savedData.transformed) == 'table' then
            state.transformed = copyTable(savedData.transformed)
        end
        if savedData.version >= 3 and type(savedData.dispositionPenalties) == 'table' then
            state.dispositionPenalties = copyTable(savedData.dispositionPenalties)
        end
        -- v7: drop inflated baselines from the re-anchor bug; they are re-captured once per NPC.
        if savedData.version >= 7 and type(savedData.dispositionBaselines) == 'table' then
            state.dispositionBaselines = copyTable(savedData.dispositionBaselines)
        end
        if savedData.version >= 6 and type(savedData.dispositionPeakPenalties) == 'table' then
            state.dispositionPeakPenalties = copyTable(savedData.dispositionPeakPenalties)
        elseif savedData.version >= 3 and type(savedData.dispositionPenalties) == 'table' then
            for plagueKey, penalty in pairs(savedData.dispositionPenalties) do
                if type(penalty) == 'number' and penalty > 0 then
                    state.dispositionPeakPenalties[plagueKey] = penalty
                end
            end
        end

        if savedData.version >= 4 then
            state.cured = savedData.cured == true
            state.curePending = savedData.curePending == true
        end

        if savedData.version >= 2 and type(savedData.countedInfections) == 'table' then
            state.countedInfections = copyTable(savedData.countedInfections)
            state.stats = {
                infections = countTable(state.countedInfections),
            }
        else
            rebuildInfectionStats()
        end

        state.firstRestDreamTriggered = savedData.firstRestDreamTriggered == true

        local estimate = M.getPandemicDispositionEstimate()
        if estimate > 0 then
            for plagueKey in pairs(state.dispositionPenalties) do
                M.raiseDispositionPeakPenalty(plagueKey, estimate)
            end
            for plagueKey in pairs(state.dispositionBaselines) do
                M.raiseDispositionPeakPenalty(plagueKey, estimate)
            end
        end
    end
end

-- Drop stale cross-save data left from builds before onSave roundtrip.
M.purgeLegacyPersistent()

return M
