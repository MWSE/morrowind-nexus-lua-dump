local module = {}

module.objectId = function(object)
    if object == nil then
        return "<nil object>"
    elseif not object or not object.id or not object.recordId then
        return "<invalid object>"
    else
        return string.format("<%s, %s>", object.id, object.recordId)
    end
end

module.insertMultipleInArray = function(sourceArray, array)
    for _, value in ipairs(array) do
        table.insert(sourceArray, value)
    end
end

module.copyMap = function(map)
    local copy = {}
    for k, v in pairs(map) do
        copy[k] = v
    end
    return copy
end

module.statsToString = function(stats)
    local parts = {}
    for statId, value in pairs(stats) do
        table.insert(parts, string.format("%s=%d", statId, value))
    end
    return table.concat(parts, ", ")
end

return module