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

module.newAvg = function(props)
    local avg = { sum = 0, count = 0 }
    if props then
        for k, v in pairs(props) do
            avg[k] = v
        end
    end
    return avg
end

module.addToAvg = function(avg, value)
    avg.sum = avg.sum + value
    avg.count = avg.count + 1
end

module.avg = function(stats)
    return stats.count == 0 and 0 or stats.sum / stats.count
end

module.sum = function(array)
    local sum = 0
    for i = 1, #array do
        sum = sum + array[i]
    end
    return sum
end

-- Arrays

module.insertMultipleInArray = function(sourceArray, array)
    for i = 1, #array do
        table.insert(sourceArray, array[i])
    end
end

module.indexOf = function(array, value)
    for i = 1, #array do
        if array[i] == value then
            return i
        end
    end
    return false
end

-- Maps

module.copyMap = function(source)
    local target = {}
    for k, v in pairs(source) do
        target[k] = v
    end
    return target
end

module.newMap = function(value, source)
    local table = {}
    local isFactory = type(value) == "function"
    for k, _ in pairs(source) do
        table[k] = isFactory and value() or value
    end
    return table
end

module.filterMap = function(source, filter)
    local target = {}
    for k, v in pairs(source) do
        if filter(k) then
            target[k] = v
        end
    end
    return target
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

module.addToSortedTable = function(newItem, getter, getId, list, size)
    local id = getId(newItem)
    local newValue = getter(newItem)
    local insertIndex, duplicateIndex
    for i = 1, #list do
        local item = list[i]
        if not insertIndex and newValue > getter(item) then
            insertIndex = i
        end
        if id and not duplicateIndex and getId(item) == id then
            duplicateIndex = i
        end
    end

    -- The new item is not better than any existing one
    if not insertIndex then
        -- List is full or a duplicate exists: ignore
        if #list == size or duplicateIndex then
            return
        end
        table.insert(list, newItem)
        return
    end
    -- The new item is better than any existing item
    if not duplicateIndex then
        table.insert(list, insertIndex, newItem)
        if #list > size then
            table.remove(list, size + 1)
        end
        return
    end
    -- Duplicate found: replace only if the new item is better
    if insertIndex <= duplicateIndex then
        table.remove(list, duplicateIndex)
        table.insert(list, insertIndex, newItem)
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
