local self = require('openmw.self')
local types = require('openmw.types')

local temperatureBalanceConfig = require('scripts.survivalmode.temperature.temperatureBalanceConfig')

local racialAbilityConfig = temperatureBalanceConfig.racialAbilities
assert(type(racialAbilityConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.racialAbilities must be a table.')
local defaultRacialAbilityConfig = racialAbilityConfig.default
assert(
    type(defaultRacialAbilityConfig) == 'table',
    '[SurvivalMode] temperatureBalanceConfig.racialAbilities.default must be a table.'
)

local raceAliases = {
    dunmer = 'dark_elf',
}

local function normalizeKey(value)
    if type(value) ~= 'string' then
        return ''
    end

    local normalized = string.lower(value)
    normalized = normalized:gsub('^%s+', '')
    normalized = normalized:gsub('%s+$', '')
    normalized = normalized:gsub('[%s%-]+', '_')
    return normalized
end

local function resolveRaceConfig(raceId)
    local normalizedRaceId = normalizeKey(raceId)
    if normalizedRaceId == '' then
        return nil, ''
    end

    local configured = racialAbilityConfig[normalizedRaceId]
    if type(configured) == 'table' then
        return configured, normalizedRaceId
    end

    local aliasRaceId = raceAliases[normalizedRaceId]
    if aliasRaceId ~= nil then
        configured = racialAbilityConfig[aliasRaceId]
        if type(configured) == 'table' then
            return configured, aliasRaceId
        end
    end

    return defaultRacialAbilityConfig, normalizedRaceId
end

local function resolveStageMultiplier(configured, fieldName)
    local multiplier = tonumber(configured[fieldName])
    assert(multiplier ~= nil, string.format(
        '[SurvivalMode] Missing numeric racial stage multiplier "%s".',
        tostring(fieldName)
    ))
    assert(multiplier > 0, string.format(
        '[SurvivalMode] Racial stage multiplier "%s" must be greater than 0.',
        tostring(fieldName)
    ))
    return multiplier
end

local function getTemperatureStageMultipliersForRace(raceId)
    local configured = select(1, resolveRaceConfig(raceId))
    return {
        heat = resolveStageMultiplier(configured, 'heatStageMultiplier'),
        cold = resolveStageMultiplier(configured, 'coldStageMultiplier'),
    }
end

local function getPlayerRaceId()
    local raceId = ''
    if types.NPC.objectIsInstance(self) then
        local record = types.NPC.record(self)
        if record ~= nil and record.race ~= nil then
            raceId = normalizeKey(tostring(record.race))
        end
    end

    return raceId
end

local function getEffectiveTemperature(value, raceId)
    local numericValue = tonumber(value) or 0
    if numericValue == 0 then
        return 0
    end

    local multipliers = getTemperatureStageMultipliersForRace(raceId)
    local stageMultiplier = numericValue > 0 and multipliers.heat or multipliers.cold
    if stageMultiplier <= 0 then
        return numericValue
    end

    return numericValue / stageMultiplier
end

local function getEffectiveTemperatureForPlayer(value)
    return getEffectiveTemperature(value, getPlayerRaceId())
end

return {
    getPlayerRaceId = getPlayerRaceId,
    getTemperatureStageMultipliersForRace = getTemperatureStageMultipliersForRace,
    getEffectiveTemperature = getEffectiveTemperature,
    getEffectiveTemperatureForPlayer = getEffectiveTemperatureForPlayer,
}
