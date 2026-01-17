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

module.objectsIds = function(objects)
    local ids = {}
    if #objects ~= 0 then
        for _, actor in ipairs(objects) do
            table.insert(ids, tostring(actor))
        end
    else
        for _, actor in pairs(objects) do
            table.insert(ids, tostring(actor))
        end
    end
    return table.concat(ids, ", ")
end

module.isObjectInvalid = function(obj)
    return not obj:isValid() or obj.count == 0
end

module.areObjectEquals = function(obj1, obj2)
    return (obj1 and obj1.id or "") == (obj2 and obj2.id or "")
end

module.addAllToMap = function(target, source, filter)
    if not source then return target end
    for k, v in pairs(source) do
        if not filter or filter(k, v) then
            target[k] = v
        end
    end
    return target
end

-- loop over sorted values
module.spairs = function(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

module.clamp = function(value, min, max)
    return math.min(max, math.max(min, value))
end

module.pick = function(list)
    return list[math.random(1, #list)]
end

return module