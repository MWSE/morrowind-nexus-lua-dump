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

module.sum = function(array)
    local sum = 0
    for _, value in ipairs(array) do
        sum = sum + value
    end
    return sum
end

-- Arrays

module.insertMultipleInArray = function(sourceArray, array)
    for _, value in ipairs(array) do
        table.insert(sourceArray, value)
    end
end

-- Maps

module.newTable = function(value, sourceTable)
    local table = {}
    for k, _ in pairs(sourceTable) do
        table[k] = value
    end
    return table
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

module.mapToString = function(map)
    local items = {}
    for key, value in pairs(map) do
        items[#items + 1] = string.format("%s=%s", key, value)
    end
    return string.format("{ %s }", table.concat(items, ", "))
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
