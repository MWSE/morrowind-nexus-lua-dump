local util = require('openmw.util')

math.randomseed(os.time())

-- UI

local function mixColors(color1, color2, ratio)
    return util.color.rgb(
            color1.r * ratio + color2.r * (1 - ratio),
            color1.g * ratio + color2.g * (1 - ratio),
            color1.b * ratio + color2.b * (1 - ratio)
    )
end

-- Strings

local function capitalize(s)
    -- THANKS: https://stackoverflow.com/a/2421843
    return s:sub(1, 1):upper() .. s:sub(2)
end

-- Numbers

local function randInt(rangeStart, rangeEnd)
    return math.random(rangeStart, rangeEnd)
end

local function round(num, numDecimal)
    if numDecimal and numDecimal > 0 then
        local mult = 10 ^ numDecimal
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end

-- Arrays

local function indexOf(value, array)
    for i = 1, #array do
        if array[i] == value then
            return i
        end
    end
end

local function isInArray(value, array)
    for _, otherValue in ipairs(array) do
        if otherValue == value then
            return true
        end
    end
    return false
end

local function insertMultipleInArray(sourceArray, array)
    for _, value in ipairs(array) do
        table.insert(sourceArray, value)
    end
end

local function insertAtMultipleInArray(sourceArray, pos, array)
    for i, value in ipairs(array) do
        table.insert(sourceArray, pos + i - 1, value)
    end
end

-- Tables

local function initNewTable(value, sourceTable)
    local table = {}
    for k, _ in pairs(sourceTable) do
        table[k] = value
    end
    return table
end

local function overrideTableValues(target, source)
    for k, v in pairs(source) do
        target[k] = v
    end
end

local function replaceAllTableValues(target, source)
    for k, _ in pairs(target) do
        target[k] = nil
    end
    for k, v in pairs(source) do
        target[k] = v
    end
end

local function tableOfTablesToString(_table)
    local strs = {}
    for key, subTable in pairs(_table) do
        strs[#strs + 1] = key .. " = { "
        for subKey, subValue in pairs(subTable) do
            strs[#strs + 1] = subKey .. " = " .. subValue .. ", "
        end
        strs[#strs + 1] = "}, "
    end
    return table.concat(strs)
end

local function areFloatEqual(f1, f2, precision)
    precision = precision or 4
    return math.floor(f1 * 10 ^ precision + 0.5) == math.floor(f2 * 10 ^ precision + 0.5)
end

return {
    mixColors = mixColors,
    capitalize = capitalize,
    randInt = randInt,
    round = round,
    indexOf = indexOf,
    isInArray = isInArray,
    insertMultipleInArray = insertMultipleInArray,
    insertAtMultipleInArray = insertAtMultipleInArray,
    initNewTable = initNewTable,
    replaceAllTableValues = replaceAllTableValues,
    overrideTableValues = overrideTableValues,
    tableOfTablesToString = tableOfTablesToString,
    areFloatEqual = areFloatEqual,
}
