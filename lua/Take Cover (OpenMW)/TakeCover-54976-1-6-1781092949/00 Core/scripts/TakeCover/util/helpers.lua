local module = {}

module.objectId = function(object)
    if not object then
        return "<invalid object>"
    else
        return string.format("<%s, %s>", object.id, object.recordId)
    end
end

module.objectIds = function(objects)
    if type(objects) ~= "table" then return "<invalid>" end
    local ids = {}
    if #objects ~= 0 then
        for i = 1, #objects do
            ids[#ids + 1] = module.objectId(objects[i])
        end
    else
        for _, actor in pairs(objects) do
            ids[#ids + 1] = module.objectId(actor)
        end
    end
    return table.concat(ids, ", ")
end

-- loop over sorted values
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