local M = {}

function M.clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function M.round(value)
    return math.floor(value + 0.5)
end

function M.trim(value)
    return value:match('^%s*(.-)%s*$')
end

function M.normalizePath(value)
    if type(value) ~= 'string' then
        return ''
    end

    return string.lower(value:gsub('\\', '/'))
end

function M.normalizeKey(value)
    if type(value) ~= 'string' then
        return ''
    end

    return string.lower(M.trim(value))
end

function M.tryGetEnumValue(enumTable, enumName)
    if enumTable == nil or enumName == nil then
        return nil
    end
    local ok, value = pcall(function()
        return enumTable[enumName]
    end)
    if not ok then
        return nil
    end
    return value
end

function M.normalizeWeatherKey(value)
    local normalized = M.normalizeKey(value)
    if normalized == '' then
        return ''
    end

    normalized = normalized:gsub('[%s_%-]+', '')
    return normalized
end

return M
