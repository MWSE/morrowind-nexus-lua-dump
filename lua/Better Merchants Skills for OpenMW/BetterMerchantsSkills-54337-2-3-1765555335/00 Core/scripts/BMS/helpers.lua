local module = {}

module.copyMap = function(map)
    local copy = {}
    for k, v in pairs(map) do
        copy[k] = v
    end
    return copy
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

module.statsToString = function(stats)
    local parts = {}
    for statId, value in pairs(stats) do
        table.insert(parts, string.format("%s=%d", statId, value))
    end
    return table.concat(parts, ", ")
end

return module