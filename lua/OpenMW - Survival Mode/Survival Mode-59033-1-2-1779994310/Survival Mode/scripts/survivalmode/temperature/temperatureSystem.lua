local core = require('openmw.core')
local temperatureBalanceConfig = require('scripts.survivalmode.temperature.temperatureBalanceConfig')
local tempRaceModifiers = require('scripts.survivalmode.temperature.tempRaceModifiers')
local l10n = core.l10n('SurvivalMode', 'en')

local function localize(key, data)
    if data == nil then
        return l10n(key)
    end

    return l10n(key, data)
end

local systemBalanceConfig = temperatureBalanceConfig.system
assert(type(systemBalanceConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.system must be a table.')

local stageThresholdConfig = temperatureBalanceConfig.stageThresholds
assert(type(stageThresholdConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.stageThresholds must be a table.')

local TEMPERATURE_MIN = tonumber(systemBalanceConfig.min)
assert(TEMPERATURE_MIN ~= nil, '[SurvivalMode] temperatureBalanceConfig.system.min must be a number.')
local TEMPERATURE_MAX = tonumber(systemBalanceConfig.max)
assert(TEMPERATURE_MAX ~= nil, '[SurvivalMode] temperatureBalanceConfig.system.max must be a number.')
local TEMPERATURE_TICK_SECONDS = tonumber(systemBalanceConfig.tickSeconds)
assert(TEMPERATURE_TICK_SECONDS ~= nil, '[SurvivalMode] temperatureBalanceConfig.system.tickSeconds must be a number.')
local TEMPERATURE_RATE_DIVISOR = tonumber(systemBalanceConfig.tickDivisor)
assert(TEMPERATURE_RATE_DIVISOR ~= nil, '[SurvivalMode] temperatureBalanceConfig.system.tickDivisor must be a number.')
assert(TEMPERATURE_RATE_DIVISOR ~= 0, '[SurvivalMode] temperatureBalanceConfig.system.tickDivisor cannot be 0.')
local TEMPERATURE_multiplier_MAX_TICKS_PER_ADVANCE = tonumber(systemBalanceConfig.multiplierMaxTicksPerAdvance)
assert(
    TEMPERATURE_multiplier_MAX_TICKS_PER_ADVANCE ~= nil,
    '[SurvivalMode] temperatureBalanceConfig.system.multiplierMaxTicksPerAdvance must be a number.'
)
if TEMPERATURE_multiplier_MAX_TICKS_PER_ADVANCE < 1 then
    TEMPERATURE_multiplier_MAX_TICKS_PER_ADVANCE = 1
else
    TEMPERATURE_multiplier_MAX_TICKS_PER_ADVANCE = math.floor(TEMPERATURE_multiplier_MAX_TICKS_PER_ADVANCE)
end
local TEMPERATURE_TICK_MIN_STEP = tonumber(systemBalanceConfig.tickMinStep)
assert(TEMPERATURE_TICK_MIN_STEP ~= nil, '[SurvivalMode] temperatureBalanceConfig.system.tickMinStep must be a number.')
local TEMPERATURE_TICK_SNAP_THRESHOLD = tonumber(systemBalanceConfig.tickSnapThreshold)
assert(
    TEMPERATURE_TICK_SNAP_THRESHOLD ~= nil,
    '[SurvivalMode] temperatureBalanceConfig.system.tickSnapThreshold must be a number.'
)

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local STAGES = {
    {
        id = 'freezing',
        min = -400,
        max = -301,
        displayName = localize('temperature_stage_freezing_name'),
        spellName = localize('temperature_stage_freezing_name'),
        weaknessSpellName = localize('temperature_stage_freezing_name'),
        weaknessFrostPct = 90,
        hungerIncreasePct = 90,
        thirstIncreasePct = 0,
        staminiaDrainPct = 125,
        slownessPct = 40,
        healthDrainPerSecond = 1,
        healthDrainMinLossPct = 75,
        healthDrainMaxLossPct = 95,
        temperatureIconKey = 'cold_4',
    },
    {
        id = 'very_cold',
        min = -300,
        max = -201,
        displayName = localize('temperature_stage_very_cold_name'),
        spellName = localize('temperature_stage_very_cold_name'),
        weaknessSpellName = localize('temperature_stage_very_cold_name'),
        weaknessFrostPct = 60,
        hungerIncreasePct = 60,
        thirstIncreasePct = 0,
        staminiaDrainPct = 75,
        slownessPct = 25,
        healthDrainPerSecond = 1,
        healthDrainMinLossPct = 25,
        healthDrainMaxLossPct = 50,
        temperatureIconKey = 'cold_3',
    },
    {
        id = 'cold',
        min = -200,
        max = -101,
        displayName = localize('temperature_stage_cold_name'),
        spellName = localize('temperature_stage_cold_name'),
        weaknessSpellName = localize('temperature_stage_cold_name'),
        weaknessFrostPct = 30,
        hungerIncreasePct = 30,
        thirstIncreasePct = 0,
        staminiaDrainPct = 50,
        slownessPct = 15,
        temperatureIconKey = 'cold_2',
    },
    {
        id = 'chilly',
        min = -100,
        max = -26,
        displayName = localize('temperature_stage_chilly_name'),
        spellName = localize('temperature_stage_chilly_name'),
        weaknessSpellName = localize('temperature_stage_chilly_name'),
        weaknessFrostPct = 10,
        hungerIncreasePct = 15,
        thirstIncreasePct = 0,
        staminiaDrainPct = 15,
        slownessPct = 0,
        temperatureIconKey = 'cold_1',
    },
    {
        id = 'neutral',
        min = -25,
        max = 25,
        displayName = localize('temperature_stage_neutral_name'),
        spellName = localize('temperature_stage_neutral_name'),
        thirstIncreasePct = 0,
        staminiaDrainPct = 0,
        slownessPct = 0,
        temperatureIconKey = 'temp_neutral',
    },
    {
        id = 'warm',
        min = 26,
        max = 100,
        displayName = localize('temperature_stage_warm_name'),
        spellName = localize('temperature_stage_warm_name'),
        weaknessSpellName = localize('temperature_stage_warm_name'),
        weaknessFirePct = 0,
        thirstIncreasePct = 10,
        staminiaDrainPct = 0,
        slownessPct = 0,
        temperatureIconKey = 'heat_1',
    },
    {
        id = 'hot',
        min = 101,
        max = 200,
        displayName = localize('temperature_stage_hot_name'),
        spellName = localize('temperature_stage_hot_name'),
        weaknessSpellName = localize('temperature_stage_hot_name'),
        weaknessFirePct = 30,
        thirstIncreasePct = 30,
        staminiaDrainPct = 50,
        slownessPct = 0,
        temperatureIconKey = 'heat_2',
    },
    {
        id = 'very_hot',
        min = 201,
        max = 300,
        displayName = localize('temperature_stage_very_hot_name'),
        spellName = localize('temperature_stage_very_hot_name'),
        weaknessSpellName = localize('temperature_stage_very_hot_name'),
        weaknessFirePct = 60,
        thirstIncreasePct = 60,
        staminiaDrainPct = 75,
        slownessPct = 0,
        temperatureIconKey = 'heat_3',
    },
    {
        id = 'scorching',
        min = 301,
        max = 400,
        displayName = localize('temperature_stage_scorching_name'),
        spellName = localize('temperature_stage_scorching_name'),
        weaknessSpellName = localize('temperature_stage_scorching_name'),
        weaknessFirePct = 90,
        thirstIncreasePct = 90,
        staminiaDrainPct = 125,
        slownessPct = 0,
        healthDrainPerSecond = 1,
        healthDrainMinLossPct = 25,
        healthDrainMaxLossPct = 75,
        temperatureIconKey = 'heat_4',
    },
}

for _, stage in ipairs(STAGES) do
    if type(stage) == 'table' and type(stage.id) == 'string' then
        local configured = stageThresholdConfig[stage.id]
        assert(type(configured) == 'table', string.format(
            '[SurvivalMode] temperatureBalanceConfig.stageThresholds.%s must be a table.',
            tostring(stage.id)
        ))
        local configuredMin = tonumber(configured.min)
        local configuredMax = tonumber(configured.max)
        assert(configuredMin ~= nil, string.format(
            '[SurvivalMode] temperatureBalanceConfig.stageThresholds.%s.min must be a number.',
            tostring(stage.id)
        ))
        assert(configuredMax ~= nil, string.format(
            '[SurvivalMode] temperatureBalanceConfig.stageThresholds.%s.max must be a number.',
            tostring(stage.id)
        ))
        stage.min = configuredMin
        stage.max = configuredMax
    end
end

for _, stage in ipairs(STAGES) do
    if type(stage) == 'table' then
        if type(stage.displayName) ~= 'string' or stage.displayName == '' then
            stage.displayName = type(stage.spellName) == 'string' and stage.spellName or tostring(stage.id or '')
        end
        if type(stage.spellName) ~= 'string' or stage.spellName == '' then
            stage.spellName = stage.displayName
        end

        local weaknessFirePct = math.max(0, math.floor((tonumber(stage.weaknessFirePct) or 0) + 0.5))
        local weaknessFrostPct = math.max(0, math.floor((tonumber(stage.weaknessFrostPct) or 0) + 0.5))
        stage.weaknessFirePct = weaknessFirePct
        stage.weaknessFrostPct = weaknessFrostPct
        stage.hungerIncreasePct = math.max(0, math.floor((tonumber(stage.hungerIncreasePct) or 0) + 0.5))
        stage.thirstIncreasePct = math.max(0, math.floor((tonumber(stage.thirstIncreasePct) or 0) + 0.5))
        stage.staminiaDrainPct = math.max(0, math.floor((tonumber(stage.staminiaDrainPct) or 0) + 0.5))
        stage.slownessPct = math.max(0, math.floor((tonumber(stage.slownessPct) or 0) + 0.5))
        stage.healthDrainPerSecond = math.max(0, tonumber(stage.healthDrainPerSecond) or 0)
        stage.healthDrainMinLossPct = clamp(tonumber(stage.healthDrainMinLossPct) or 0, 0, 100)
        stage.healthDrainMaxLossPct = clamp(
            tonumber(stage.healthDrainMaxLossPct) or stage.healthDrainMinLossPct,
            stage.healthDrainMinLossPct,
            100
        )

        if (weaknessFirePct > 0 or weaknessFrostPct > 0)
            and (type(stage.weaknessSpellName) ~= 'string' or stage.weaknessSpellName == '') then
            stage.weaknessSpellName = stage.displayName
        end
    end
end

local STAGE_MESSAGES = {
    freezing = localize('temperature_stage_freezing_message'),
    very_cold = localize('temperature_stage_very_cold_message'),
    cold = localize('temperature_stage_cold_message'),
    chilly = localize('temperature_stage_chilly_message'),
    neutral = localize('temperature_stage_neutral_message'),
    warm = localize('temperature_stage_warm_message'),
    hot = localize('temperature_stage_hot_message'),
    very_hot = localize('temperature_stage_very_hot_message'),
    scorching = localize('temperature_stage_scorching_message'),
}

local ICON_PATHS = {
    temp_neutral = 'icons/TEMP-NEUTRAL.png',
    cold_1 = 'icons/COLD-1.png',
    cold_2 = 'icons/COLD-2.png',
    cold_3 = 'icons/COLD-3.png',
    cold_4 = 'icons/COLD-4.png',
    heat_1 = 'icons/HEAT-1.png',
    heat_2 = 'icons/HEAT-2.png',
    heat_3 = 'icons/HEAT-3.png',
    heat_4 = 'icons/HEAT-4.png',
}

local function getEffectiveStageTemperature(value)
    return tempRaceModifiers.getEffectiveTemperatureForPlayer(value)
end

local function getStageByValue(value)
    local stageCount = type(STAGES) == 'table' and #STAGES or 0
    if stageCount == 0 then
        return nil
    end

    local numericValue = getEffectiveStageTemperature(value)
    local firstStage = STAGES[1]
    local firstMin = tonumber(firstStage.min) or 0
    if numericValue < firstMin then
        return firstStage
    end

    for index, stage in ipairs(STAGES) do
        local stageMin = tonumber(stage.min) or 0
        local nextStage = STAGES[index + 1]
        local nextMin = nextStage ~= nil and tonumber(nextStage.min) or nil
        if numericValue >= stageMin and (nextMin == nil or numericValue < nextMin) then
            return stage
        end
    end

    return STAGES[stageCount]
end

local function getTotalModifier(warmModifier, coldModifier)
    return (tonumber(warmModifier) or 0) + (tonumber(coldModifier) or 0)
end

local function getTickAmount(warmModifier, coldModifier)
    return getTotalModifier(warmModifier, coldModifier) / TEMPERATURE_RATE_DIVISOR
end

local function getTickAmountForCurrentTemperature(currentValue, warmModifier, coldModifier)
    local currentTemperature = tonumber(currentValue) or 0
    local targetValue = clamp(getTotalModifier(warmModifier, coldModifier), TEMPERATURE_MIN, TEMPERATURE_MAX)
    local rawTickAmount = getTickAmount(warmModifier, coldModifier)
    local tickMagnitude = math.abs(tonumber(rawTickAmount) or 0)
    if tickMagnitude <= 0 then
        return 0
    end
    -- enforce configured minimum tick magnitude
    if TEMPERATURE_TICK_MIN_STEP > 0 and tickMagnitude < TEMPERATURE_TICK_MIN_STEP then
        tickMagnitude = TEMPERATURE_TICK_MIN_STEP
    end

    if currentTemperature < targetValue then
        return tickMagnitude
    end
    if currentTemperature > targetValue then
        return -tickMagnitude
    end

    return 0
end

local function advanceTemperature(value, remainder, elapsedSeconds, warmModifier, coldModifier, multiplier, maxTicksPerAdvance)
    local elapsed = tonumber(elapsedSeconds) or 0
    if elapsed <= 0 then
        return value, remainder
    end

    local scale = tonumber(multiplier) or 1
    if scale <= 0 then
        return value, remainder
    end

    local nextRemainder = (tonumber(remainder) or 0) + (elapsed * scale)
    local ticks = math.floor(nextRemainder / TEMPERATURE_TICK_SECONDS)
    local tickCap = math.floor(tonumber(maxTicksPerAdvance) or 0)
    if tickCap > 0 then
        ticks = math.min(ticks, tickCap)
    elseif scale > 1.0 then
        ticks = math.min(ticks, TEMPERATURE_multiplier_MAX_TICKS_PER_ADVANCE)
    end
    if ticks <= 0 then
        return value, nextRemainder
    end

    nextRemainder = nextRemainder - (ticks * TEMPERATURE_TICK_SECONDS)

    local currentValue = tonumber(value) or 0
    local totalModifier = getTotalModifier(warmModifier, coldModifier)
    local tickAmount = getTickAmountForCurrentTemperature(currentValue, warmModifier, coldModifier)
    if tickAmount == 0 then
        return clamp(currentValue, TEMPERATURE_MIN, TEMPERATURE_MAX), nextRemainder
    end

    local targetValue = clamp(totalModifier, TEMPERATURE_MIN, TEMPERATURE_MAX)
    local nextValue = currentValue + (tickAmount * ticks)

    if tickAmount > 0 then
        nextValue = math.min(nextValue, targetValue)
    else
        nextValue = math.max(nextValue, targetValue)
    end

    -- snap to target if within configured threshold
    if TEMPERATURE_TICK_SNAP_THRESHOLD > 0 and math.abs(targetValue - nextValue) <= TEMPERATURE_TICK_SNAP_THRESHOLD then
        nextValue = targetValue
    end

    nextValue = clamp(nextValue, TEMPERATURE_MIN, TEMPERATURE_MAX)
    return nextValue, nextRemainder
end

return {
    TEMPERATURE_MIN = TEMPERATURE_MIN,
    TEMPERATURE_MAX = TEMPERATURE_MAX,
    TEMPERATURE_TICK_SECONDS = TEMPERATURE_TICK_SECONDS,
    STAGES = STAGES,
    STAGE_MESSAGES = STAGE_MESSAGES,
    ICON_PATHS = ICON_PATHS,
    getStageByValue = getStageByValue,
    getEffectiveStageTemperature = getEffectiveStageTemperature,
    getTotalModifier = getTotalModifier,
    getTickAmount = getTickAmount,
    getTickAmountForCurrentTemperature = getTickAmountForCurrentTemperature,
    advanceTemperature = advanceTemperature,
}
