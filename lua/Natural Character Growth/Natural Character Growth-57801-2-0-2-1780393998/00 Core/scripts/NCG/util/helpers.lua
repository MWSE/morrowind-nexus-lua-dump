local module = {}

-- Numbers

module.round = function(value, decimals)
    decimals = decimals or 5
    local factor = 10 ^ decimals
    return math.floor(0.5 + value * factor) / factor
end

module.avg = function(sum, count)
    return count == 0 and 0 or sum / count
end

-- Arrays

module.insertMultipleInArray = function(sourceArray, array)
    for i = 1, #array do
        sourceArray[#sourceArray + 1] = array[i]
    end
end

-- Maps

module.copyMap = function(source)
    local target = {}
    for k, v in pairs(source) do
        target[k] = v
    end
    return target
end

module.initNewTable = function(value, sourceTable)
    local table = {}
    for k, _ in pairs(sourceTable) do
        table[k] = value
    end
    return table
end

module.mapToString = function(map)
    local items = {}
    for key, value in pairs(map) do
        items[#items + 1] = string.format("%s=%s", key, value)
    end
    return string.format("{ %s }", table.concat(items, ", "))
end

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

return module
