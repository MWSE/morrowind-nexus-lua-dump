local Helpers = {}

Helpers.deepCopy = function(table)
    if type(table) ~= "table" then return table end
    local copy = {}
    for k, v in pairs(table) do
        copy[k] = Helpers.deepCopy(v)
    end
    return copy
end

Helpers.toLookup = function(list)
    local lookup = {}
    for _, v in ipairs(list) do
        lookup[v] = true
    end
    return lookup
end

Helpers.matchesAny = function(str, patterns)
    for _, pattern in ipairs(patterns) do
        if string.find(str:lower(), pattern:lower(), 1, true) then
            return true
        end
    end
    return false
end

return Helpers