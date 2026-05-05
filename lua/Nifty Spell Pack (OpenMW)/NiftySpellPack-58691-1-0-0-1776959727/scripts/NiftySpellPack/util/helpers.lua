local H = {}

H.getSize = function(obj)
    if not obj then return 0 end
    local size = 0
    for _ in pairs(obj) do size = size + 1 end
    return size
end

H.roundToPlaces = function(num, places)
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

H.deepPrint = function(tbl, indent)
    indent = indent or 0
    local str = ""
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            str = str .. formatting .. "\n" .. H.deepPrint(v, indent + 1)
        else
            str = str .. formatting .. tostring(v) .. "\n"
        end
    end
    return str
end

H.range = function(from, to)
    local result = {}
    for i = from, to do
        table.insert(result, i)
    end
    return result
end

return H