local async = require('openmw.async')
local storage = require('openmw.storage')
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')

local runtimeSection = storage.globalSection('Runtime_Throwing')
local NEVER = -1000000000

local paralyzeState = setmetatable({}, { __mode = 'k' })
local bleedState = setmetatable({}, { __mode = 'k' })

local PARALYZE_SPELL_CANDIDATES = {
    'paralysis',
    'scrib_paralysis',
}

local BLEED_EFFECT_ID = 'damagehealth'
local bleedSpellCache = {}

local function debugEnabled()
    return runtimeSection:get('debugMessages') == true
end

local function debugLog(msg)
    if debugEnabled() then
        print('[Throwing!] ' .. msg)
    end
end

local function findNewestActiveSpellId(target, recordId, previousIds)
    local newest = nil
    for _, spell in pairs(types.Actor.activeSpells(target)) do
        if spell.id == recordId and spell.temporary then
            local activeId = spell.activeSpellId
            if activeId ~= nil and not previousIds[activeId] then
                newest = activeId
            end
        end
    end
    return newest
end

local function addTemporarySpell(target, attacker, recordId, displayName, opts)
    local previousIds = {}
    for _, spell in pairs(types.Actor.activeSpells(target)) do
        if spell.id == recordId and spell.activeSpellId ~= nil then
            previousIds[spell.activeSpellId] = true
        end
    end

    opts = opts or {}
    local effectIndex = tonumber(opts.effectIndex) or 0

    types.Actor.activeSpells(target):add({
        id = recordId,
        effects = { effectIndex },
        name = displayName or recordId,
        caster = attacker,
        stackable = true,
        ignoreReflect = opts.ignoreReflect == true,
        ignoreResistances = opts.ignoreResistances == true,
        ignoreSpellAbsorption = opts.ignoreSpellAbsorption == true,
    })

    return findNewestActiveSpellId(target, recordId, previousIds)
end

local function removeTrackedState(stateTable, data, label)
    if not data or not data.target or not types.Actor.objectIsInstance(data.target) then return end

    local state = stateTable[data.target]
    if state and data.token and state.token ~= data.token then
        return
    end

    if state and state.activeSpellId ~= nil then
        local ok, err = pcall(function()
            types.Actor.activeSpells(data.target):remove(state.activeSpellId)
        end)
        if not ok then
            debugLog('Failed to remove ' .. label .. ' active spell id=' .. tostring(state.activeSpellId) .. ' reason=' .. tostring(err))
        else
            debugLog('Removed ' .. label .. ' active spell id=' .. tostring(state.activeSpellId))
        end
    end

    stateTable[data.target] = nil
end

local clearParalyzeTimer = async:registerTimerCallback('Throwing_ClearParalyze', function(data)
    removeTrackedState(paralyzeState, data, 'paralyze')
end)

local clearBleedTimer = async:registerTimerCallback('Throwing_ClearBleed', function(data)
    removeTrackedState(bleedState, data, 'bleed')
end)

local function getParalyzeSpellId()
    for _, id in ipairs(PARALYZE_SPELL_CANDIDATES) do
        if core.magic.spells.records[id] then
            return id
        end
    end
    return nil
end

local function getBleedSpellData(requestedMin, requestedMax, requestedDuration)
    local desiredMin = tonumber(requestedMin) or 1
    local desiredMax = tonumber(requestedMax) or desiredMin
    local desiredDuration = tonumber(requestedDuration) or 3
    local cacheKey = table.concat({ desiredMin, desiredMax, desiredDuration }, ':')
    local cached = bleedSpellCache[cacheKey]
    if cached ~= nil then
        return cached or nil
    end

    local bestMatch = nil
    local bestScore = math.huge

    local function scoreRecord(recordId, recordName, effect, index, sourcePenalty)
        local magMin = tonumber(effect.magnitudeMin) or 0
        local magMax = tonumber(effect.magnitudeMax) or magMin
        local duration = tonumber(effect.duration) or 0
        local score = (sourcePenalty or 0)
            + math.abs(duration - desiredDuration) * 12
            + math.abs(magMin - desiredMin) * 6
            + math.abs(magMax - desiredMax) * 6
        if bestMatch == nil or score < bestScore then
            bestMatch = {
                id = recordId,
                name = recordName,
                effectIndex = index - 1,
                magnitudeMin = magMin,
                magnitudeMax = magMax,
                duration = duration,
            }
            bestScore = score
        end
    end

    for _, spell in pairs(core.magic.spells.records) do
        if spell.type == core.magic.SPELL_TYPE.Spell and spell.effects and #spell.effects > 0 then
            for index, effect in ipairs(spell.effects) do
                if effect.id == BLEED_EFFECT_ID then
                    scoreRecord(spell.id, spell.name, effect, index, 0)
                end
            end
        end
    end

    for _, potion in pairs(types.Potion.records) do
        if potion.effects and #potion.effects > 0 then
            for index, effect in ipairs(potion.effects) do
                if effect.id == BLEED_EFFECT_ID then
                    scoreRecord(potion.id, potion.name, effect, index, 50)
                end
            end
        end
    end

    bleedSpellCache[cacheKey] = bestMatch or false
    return bestMatch
end

local function restoreThrowable(data)
    if not data or not data.actor or not data.recordId then return end
    if not types.Actor.objectIsInstance(data.actor) then return end

    local item = world.createObject(data.recordId, data.count or 1)
    item:moveInto(types.Actor.inventory(data.actor))
end

local function applyParalyze(data)
    if not data or not data.target or not types.Actor.objectIsInstance(data.target) then return end

    local duration = math.max(0.05, tonumber(data.duration) or 1)
    local state = paralyzeState[data.target] or { token = 0 }
    state.token = (state.token or 0) + 1
    paralyzeState[data.target] = state

    local spellId = getParalyzeSpellId()
    if not spellId then
        debugLog('No built-in paralyze spell record found; paralyze perk disabled for this proc.')
        return
    end

    local addedOk, addedErr = pcall(function()
        state.activeSpellId = addTemporarySpell(data.target, data.attacker, spellId, 'Throwing Paralyze', {
            ignoreResistances = true,
            ignoreSpellAbsorption = true,
        })
    end)
    if not addedOk then
        debugLog('Failed to add paralyze active spell reason=' .. tostring(addedErr))
        return
    end

    state.spellId = spellId
    state.duration = duration

    debugLog('Applied built-in paralyze spell record=' .. tostring(spellId)
        .. ' activeSpellId=' .. tostring(state.activeSpellId)
        .. ' requestedDuration=' .. tostring(duration))

    async:newSimulationTimer(duration, clearParalyzeTimer, {
        target = data.target,
        token = state.token,
    })
end

local function applyBleed(data)
    if not data or not data.target or not types.Actor.objectIsInstance(data.target) then return end

    local duration = math.max(0.05, tonumber(data.duration) or 3)
    local magnitudeMin = tonumber(data.magnitudeMin) or 1
    local magnitudeMax = tonumber(data.magnitudeMax) or magnitudeMin
    local state = bleedState[data.target] or { token = 0 }
    state.token = (state.token or 0) + 1
    bleedState[data.target] = state

    local spellData = getBleedSpellData(magnitudeMin, magnitudeMax, duration)
    if not spellData then
        debugLog('No built-in bleed spell record found; bleed perk skipped.')
        return
    end

    local addedOk, addedErr = pcall(function()
        state.activeSpellId = addTemporarySpell(data.target, data.attacker, spellData.id, 'Throwing Bleed', {
            effectIndex = spellData.effectIndex,
            ignoreResistances = true,
            ignoreSpellAbsorption = true,
        })
    end)
    if not addedOk then
        debugLog('Failed to add bleed active spell reason=' .. tostring(addedErr))
        return
    end

    state.spellId = spellData.id
    state.duration = duration
    state.magnitudeMin = spellData.magnitudeMin
    state.magnitudeMax = spellData.magnitudeMax

    debugLog('Applied built-in bleed spell record=' .. tostring(spellData.id)
        .. ' effectIndex=' .. tostring(spellData.effectIndex)
        .. ' activeSpellId=' .. tostring(state.activeSpellId)
        .. ' requested=' .. tostring(magnitudeMin) .. '-' .. tostring(magnitudeMax) .. 'x' .. tostring(duration)
        .. ' matched=' .. tostring(spellData.magnitudeMin) .. '-' .. tostring(spellData.magnitudeMax) .. 'x' .. tostring(spellData.duration))

    async:newSimulationTimer(duration, clearBleedTimer, {
        target = data.target,
        token = state.token,
    })
end



local playDelayedSoundTimer = async:registerTimerCallback('Throwing_PlayDelayedSound', function(data)
    if not data or not data.target or not data.sound then return end
    if not types.Actor.objectIsInstance(data.target) then return end
    local ok, err = pcall(function()
        data.target:sendEvent('PlaySound3d', { sound = data.sound })
    end)
    if not ok then
        debugLog('Failed delayed sound sound=' .. tostring(data.sound) .. ' reason=' .. tostring(err))
    end
end)

local function playDelayedSound(data)
    if not data or not data.target or not data.sound then return end
    local delay = math.max(0, tonumber(data.delay) or 0)
    async:newSimulationTimer(delay, playDelayedSoundTimer, {
        target = data.target,
        sound = data.sound,
    })
end

local function updatePendingThrow(data)
    if not data then return end
    runtimeSection:set('token', data.token)
    runtimeSection:set('releasedAt', data.releasedAt)
    runtimeSection:set('recordId', data.recordId)
    runtimeSection:set('weight', data.weight)
    runtimeSection:set('throwingSkill', data.throwingSkill)
    runtimeSection:set('effectiveSkill', data.effectiveSkill)
    runtimeSection:set('strength', data.strength)
    runtimeSection:set('active', data.active)
end

local function clearPendingThrow()
    runtimeSection:set('releasedAt', NEVER)
    runtimeSection:set('recordId', nil)
    runtimeSection:set('weight', 0)
    runtimeSection:set('throwingSkill', 5)
    runtimeSection:set('effectiveSkill', 5)
    runtimeSection:set('strength', 0)
    runtimeSection:set('active', false)
end

local function updateRuntimeSettings(data)
    if not data then return end
    runtimeSection:set('enabled', data.enabled)
    runtimeSection:set('quickThrowEnabled', data.quickThrowEnabled)
    runtimeSection:set('shortRangeBonusEnabled', data.shortRangeBonusEnabled)
    runtimeSection:set('criticalEnabled', data.criticalEnabled)
    runtimeSection:set('twinFlightEnabled', data.twinFlightEnabled)
    runtimeSection:set('bleedEnabled', data.bleedEnabled)
    runtimeSection:set('paralyzeEnabled', data.paralyzeEnabled)
    runtimeSection:set('debugMessages', data.debugMessages)
end

return {
    eventHandlers = {
        Throwing_RestoreThrowable = restoreThrowable,
        Throwing_ApplyParalyze = applyParalyze,
        Throwing_ApplyBleed = applyBleed,
        Throwing_PlayDelayedSound = playDelayedSound,
        Throwing_UpdatePendingThrow = updatePendingThrow,
        Throwing_ClearPendingThrow = clearPendingThrow,
        Throwing_UpdateRuntimeSettings = updateRuntimeSettings,
    },
}
