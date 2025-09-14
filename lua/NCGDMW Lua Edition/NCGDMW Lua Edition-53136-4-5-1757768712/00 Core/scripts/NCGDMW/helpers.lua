local util = require('openmw.util')

local module = {}

-- UI

module.mixColors = function(color1, color2, ratio)
    return util.color.rgb(
            color1.r * ratio + color2.r * (1 - ratio),
            color1.g * ratio + color2.g * (1 - ratio),
            color1.b * ratio + color2.b * (1 - ratio)
    )
end

-- Numbers

module.avg = function(sum, count)
    return count == 0 and 0 or sum / count
end

module.randInt = function(rangeStart, rangeEnd)
    return math.random(rangeStart, rangeEnd)
end

-- Arrays

module.isInArray = function(value, array)
    for _, otherValue in ipairs(array) do
        if otherValue == value then
            return true
        end
    end
    return false
end

module.insertMultipleInArray = function(sourceArray, array)
    for _, value in ipairs(array) do
        table.insert(sourceArray, value)
    end
end

-- Maps

module.initNewTable = function(value, sourceTable)
    local table = {}
    for k, _ in pairs(sourceTable) do
        table[k] = value
    end
    return table
end

module.tableOfTablesToString = function(_table)
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

module.areFloatEqual = function(f1, f2, precision)
    precision = precision or 4
    return math.floor(f1 * 10 ^ precision + 0.5) == math.floor(f2 * 10 ^ precision + 0.5)
end

-- loop over sorted and optionally filtered values
module.spairs = function(t, order, filter)
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

-- Geometry

local function v3xy(vector)
    return util.vector2(vector.x, vector.y)
end

module.groundDist = function(v1, v2)
    return (v3xy(v1) - v3xy(v2)):length()
end

module.ordinal = function(number)
    local unit = number % 10
    return tostring(number) .. (unit == 1 and "st" or (unit == 2 and "nd" or "th"))
end

module.angle = function(z1, z2, x1, x2)
    return math.atan((z1 - z2) / (x1 - x2))
end

return module
