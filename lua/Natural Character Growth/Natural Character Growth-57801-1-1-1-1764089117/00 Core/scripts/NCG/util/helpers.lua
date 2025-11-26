local util = require('openmw.util')

local module = {}

-- Numbers

module.avg = function(sum, count)
    return count == 0 and 0 or sum / count
end

-- Arrays

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

module.mapToString = function(map)
    local items = {}
    for key, value in pairs(map) do
        items[#items + 1] = string.format("%s=%s", key, value)
    end
    return string.format("{ %s }", table.concat(items, ", "))
end

return module
