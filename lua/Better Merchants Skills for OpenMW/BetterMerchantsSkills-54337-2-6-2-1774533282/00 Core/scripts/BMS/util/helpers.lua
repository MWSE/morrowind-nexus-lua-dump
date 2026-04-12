local module = {}

module.round = function(value, decimals)
    decimals = decimals or 5
    local factor = 10 ^ decimals
    return math.floor(0.5 + value * factor) / factor
end

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