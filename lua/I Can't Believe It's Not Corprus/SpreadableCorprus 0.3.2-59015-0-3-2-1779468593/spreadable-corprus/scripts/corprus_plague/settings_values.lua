local config = require('scripts.corprus_plague.config')

local M = {}

function M.resolveDispositionModifier(value)
    if type(value) ~= 'number' then
        value = tonumber(value)
    end
    if value == nil then
        return config.defaultDispositionModifier
    end
    value = math.floor(value * 10 + 0.5) / 10
    if value < config.minDispositionModifier then
        return config.minDispositionModifier
    end
    if value > config.maxDispositionModifier then
        return config.maxDispositionModifier
    end
    return value
end

function M.resolveIncubationDays(value)
    if type(value) ~= 'number' then
        value = tonumber(value)
    end
    if value == nil then
        return config.defaultIncubationDays
    end
    value = math.floor(value)
    if value < config.minIncubationDays then
        return config.minIncubationDays
    end
    if value > config.maxIncubationDays then
        return config.maxIncubationDays
    end
    return value
end

return M
