local module = {}

module.round = function(value, decimals)
    local factor = 10 ^ decimals
    return math.floor(0.5 + value * factor) / factor
end

module.areFloatEqual = function(f1, f2, precision)
    precision = precision or 5
    return math.floor(f1 * 10 ^ precision + 0.5) == math.floor(f2 * 10 ^ precision + 0.5)
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