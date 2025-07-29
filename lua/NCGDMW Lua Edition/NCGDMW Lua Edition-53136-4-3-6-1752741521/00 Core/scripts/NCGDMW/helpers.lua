local util = require('openmw.util')

local module = {}

-- UI

local function mixColors(color1, color2, ratio)
    return util.color.rgb(
            color1.r * ratio + color2.r * (1 - ratio),
            color1.g * ratio + color2.g * (1 - ratio),
            color1.b * ratio + color2.b * (1 - ratio)
    )
end
module.mixColors = mixColors

-- Strings

local function capitalize(s)
    -- THANKS: https://stackoverflow.com/a/2421843
    return s:sub(1, 1):upper() .. s:sub(2)
end
module.capitalize = capitalize

-- Numbers

local function randInt(rangeStart, rangeEnd)
    return math.random(rangeStart, rangeEnd)
end
module.randInt = randInt

local function round(num, numDecimal)
    if numDecimal and numDecimal > 0 then
        local mult = 10 ^ numDecimal
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end
module.round = round

-- Arrays

local function indexOf(value, array)
    for i = 1, #array do
        if array[i] == value then
            return i
        end
    end
end
module.indexOf = indexOf

local function isInArray(value, array)
    for _, otherValue in ipairs(array) do
        if otherValue == value then
            return true
        end
    end
    return false
end
module.isInArray = isInArray

local function insertMultipleInArray(sourceArray, array)
    for _, value in ipairs(array) do
        table.insert(sourceArray, value)
    end
end
module.insertMultipleInArray = insertMultipleInArray

local function insertAtMultipleInArray(sourceArray, pos, array)
    for i, value in ipairs(array) do
        table.insert(sourceArray, pos + i - 1, value)
    end
end
module.insertAtMultipleInArray = insertAtMultipleInArray

-- Tables

local function initNewTable(value, sourceTable)
    local table = {}
    for k, _ in pairs(sourceTable) do
        table[k] = value
    end
    return table
end
module.initNewTable = initNewTable

local function overrideTableValues(target, source)
    for k, v in pairs(source) do
        target[k] = v
    end
end
module.overrideTableValues = overrideTableValues

local function replaceAllTableValues(target, source)
    for k, _ in pairs(target) do
        target[k] = nil
    end
    for k, v in pairs(source) do
        target[k] = v
    end
end
module.replaceAllTableValues = replaceAllTableValues

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
module.tableOfTablesToString = tableOfTablesToString

local function areFloatEqual(f1, f2, precision)
    precision = precision or 4
    return math.floor(f1 * 10 ^ precision + 0.5) == math.floor(f2 * 10 ^ precision + 0.5)
end
module.areFloatEqual = areFloatEqual

-- loop over sorted and optionally filtered values
local function spairs(t, order, filter)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        while (keys[i + 1]) do
            i = i + 1
            if keys[i] and ((not filter) or filter(t[keys[i]])) then
                return keys[i], t[keys[i]]
            end
        end
    end
end
module.spairs = spairs

-- Geometry

local function v3xy(vector)
    return util.vector2(vector.x, vector.y)
end
module.v3xy = v3xy

module.groundDist = function(v1, v2)
    return (v3xy(v1) - v3xy(v2)):length()
end

module.ordinal = function(number)
    local unit = number % 10
    return tostring(number) .. (unit == 1 and "st" or (unit == 2 and "nd" or "th"))
end

return module
