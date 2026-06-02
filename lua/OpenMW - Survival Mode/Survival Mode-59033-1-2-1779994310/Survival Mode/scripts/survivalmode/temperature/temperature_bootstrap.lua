local core = require('openmw.core')
local l10n = core.l10n('SurvivalMode', 'en')

local function loadOptionalModule(modulePaths)
    local lastError = nil
    for _, modulePath in ipairs(modulePaths) do
        local ok, loaded = pcall(require, modulePath)
        if ok and type(loaded) == 'table' then
            return loaded, modulePath
        end
        if not ok then
            lastError = loaded
        end
    end

    return nil, tostring(lastError or 'module not found')
end

local temperatureSystem, temperatureSystemPath = loadOptionalModule({
    'scripts.survivalmode.temperature.temperatureSystem',
    'temperature.temperatureSystem',
    'temperatureSystem',
})
if temperatureSystem == nil then
    local fallbackMin = -400
    local fallbackMax = 400
    local fallbackNeutralMin = -25
    local fallbackNeutralMax = 40

    local balanceConfig = select(1, loadOptionalModule({
        'scripts.survivalmode.temperature.temperatureBalanceConfig',
        'temperature.temperatureBalanceConfig',
        'temperatureBalanceConfig',
    }))
    if type(balanceConfig) == 'table' then
        if type(balanceConfig.system) == 'table' then
            fallbackMin = tonumber(balanceConfig.system.min) or fallbackMin
            fallbackMax = tonumber(balanceConfig.system.max) or fallbackMax
        end
        if type(balanceConfig.stageThresholds) == 'table' and type(balanceConfig.stageThresholds.neutral) == 'table' then
            fallbackNeutralMin = tonumber(balanceConfig.stageThresholds.neutral.min) or fallbackNeutralMin
            fallbackNeutralMax = tonumber(balanceConfig.stageThresholds.neutral.max) or fallbackNeutralMax
        end
    end

    print(string.format(
        '[SurvivalMode] Temperature system module failed to load (%s). Temperature will be disabled.',
        temperatureSystemPath
    ))
    temperatureSystem = {
        TEMPERATURE_MIN = fallbackMin,
        TEMPERATURE_MAX = fallbackMax,
        STAGES = {
            {
                id = 'neutral',
                min = fallbackNeutralMin,
                max = fallbackNeutralMax,
                temperatureIconKey = 'temp_neutral',
            },
        },
        STAGE_MESSAGES = {
            neutral = l10n('temperature_stage_neutral_message'),
        },
        ICON_PATHS = {
            temp_neutral = 'icons/TEMP-NEUTRAL.png',
        },
        getStageByValue = function()
            return {
                id = 'neutral',
                min = fallbackNeutralMin,
                max = fallbackNeutralMax,
                temperatureIconKey = 'temp_neutral',
            }
        end,
        advanceTemperature = function(value, remainder)
            return tonumber(value) or 0, tonumber(remainder) or 0
        end,
    }
end

local temperatureConfig, temperatureConfigPath = loadOptionalModule({
    'scripts.survivalmode.temperature.temperatureConfig',
    'temperature.temperatureConfig',
    'temperatureConfig',
})
if temperatureConfig == nil then
    print(string.format(
        '[SurvivalMode] Temperature config module failed to load (%s). Temperature regions will be neutral.',
        temperatureConfigPath
    ))
    temperatureConfig = {
        getModifiersForCell = function()
            return {
                warmModifier = 0,
                coldModifier = 0,
                totalModifier = 0,
                category = 'neutral',
                matchedRegionName = nil,
            }
        end,
    }
end

return {
    system = temperatureSystem,
    config = temperatureConfig,
}
