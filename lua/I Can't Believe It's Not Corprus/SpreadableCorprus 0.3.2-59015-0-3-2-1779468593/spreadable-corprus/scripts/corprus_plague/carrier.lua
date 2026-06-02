local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local config = require('scripts.corprus_plague.config')

local M = {}

-- Older builds used these instead of the custom carrier ability.
local legacyCarrierSpellIds = {
    'corprus immunity',
    'spreadable corprus',
}

-- Renamed spell from an earlier cure build; stripped on sync.
local legacyCarrierSpellName = 'Pandemic (Cured)'

local carrierEffectIds = {
    [config.carrierEffectId] = true,
    [config.carrierCuredEffectId] = true,
}

local function removeSpell(spells, spellId)
    pcall(function()
        spells:remove(spellId)
    end)
end

local function normalizeInfectionCount(infectionCount)
    infectionCount = tonumber(infectionCount) or 0
    if infectionCount < 0 then
        return 0
    end
    return math.floor(infectionCount)
end

local function getCarrierEffectId(cured)
    if cured then
        return config.carrierCuredEffectId
    end
    return config.carrierEffectId
end

local function hasCarrierEffect(spell)
    return M.getCarrierEffect(spell) ~= nil
end

function M.getCarrierEffect(spell)
    if not spell or not spell.effects then
        return nil
    end
    for _, effect in pairs(spell.effects) do
        if carrierEffectIds[effect.id] then
            return effect
        end
    end
    return nil
end

local function isLegacyCarrierId(spellId)
    for _, legacyId in ipairs(legacyCarrierSpellIds) do
        if spellId == legacyId then
            return true
        end
    end
    return false
end

local function isCarrierSpell(spell)
    return spell ~= nil
        and (
            spell.id == config.carrierSpellId
            or isLegacyCarrierId(spell.id)
            or (spell.name == config.carrierSpellName and hasCarrierEffect(spell))
            or (spell.name == legacyCarrierSpellName and hasCarrierEffect(spell))
        )
end

local function removeCarrierSpells(player)
    local spells = types.Actor.spells(player)
    local spellIds = {}
    for _, spell in pairs(spells) do
        if isCarrierSpell(spell) then
            spellIds[#spellIds + 1] = spell.id
        end
    end

    for _, spellId in ipairs(spellIds) do
        removeSpell(spells, spellId)
    end
end

local function removeCarrierActiveSpellInstances(player)
    local ok, activeSpells = pcall(function()
        return types.Actor.activeSpells(player)
    end)
    if not ok or not activeSpells then
        return
    end

    local activeSpellIds = {}
    for activeSpellId, activeSpell in pairs(activeSpells) do
        if isCarrierSpell(activeSpell) then
            activeSpellIds[#activeSpellIds + 1] = activeSpell.activeSpellId or activeSpellId
        end
    end

    for _, activeSpellId in ipairs(activeSpellIds) do
        pcall(function()
            activeSpells:remove(activeSpellId)
        end)
    end
end

local function createCarrierSpellRecord(infectionCount, cured)
    local baseRecord = core.magic.spells.records[config.carrierSpellId]
    if not baseRecord then
        return nil
    end

    local effectId = getCarrierEffectId(cured)
    infectionCount = normalizeInfectionCount(infectionCount)

    for _, spell in pairs(core.magic.spells.records) do
        local effect = M.getCarrierEffect(spell)
        if spell.name == config.carrierSpellName
            and effect
            and effect.id == effectId
            and normalizeInfectionCount(effect.magnitudeMin) == infectionCount
            and normalizeInfectionCount(effect.magnitudeMax) == infectionCount
        then
            return spell
        end
    end

    local recordDraft = core.magic.spells.createRecordDraft({
        template = baseRecord,
        name = config.carrierSpellName,
        type = core.magic.SPELL_TYPE.Ability,
        cost = 0,
        effects = {
            {
                id = effectId,
                range = core.magic.RANGE.Self,
                duration = 0,
                magnitudeMin = infectionCount,
                magnitudeMax = infectionCount,
            },
        },
    })
    return world.createRecord(recordDraft)
end

function M.syncInfectionCount(player, infectionCount, cured)
    if not player or not player:isValid() then
        return
    end

    infectionCount = normalizeInfectionCount(infectionCount)
    removeCarrierActiveSpellInstances(player)
    removeCarrierSpells(player)

    local spells = types.Actor.spells(player)
    local ok, carrierSpell = pcall(createCarrierSpellRecord, infectionCount, cured)
    if ok and carrierSpell and carrierSpell.id then
        spells:add(carrierSpell.id)
    else
        spells:add(config.carrierSpellId)
    end
end

function M.ensure(player, infectionCount, cured)
    if not player or not player:isValid() then
        return
    end
    if not core.magic.spells.records[config.carrierSpellId] then
        error('[corprus_plague] carrier spell missing; requires OpenMW 0.51+ with LOAD script')
    end

    M.syncInfectionCount(player, infectionCount, cured)
end

return M
