local module = {}

module.getRecord = function(item)
    if item.type and item.type.record then
        return item.type.record(item)
    end
    return nil
end

module.objectId = function(object)
    return string.format("<%s (%s)>", object.recordId, object.id)
end

module.objectsIds = function(objects)
    local ids = {}
    if #objects ~= 0 then
        for _, actor in ipairs(objects) do
            table.insert(ids, module.objectId(actor))
        end
    else
        for _, actor in pairs(objects) do
            table.insert(ids, module.objectId(actor))
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

module.clamp = function(value, min, max)
    return math.min(max, math.max(min, value))
end

module.pick = function(list)
    return list[math.random(1, #list)]
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

-- loop over multiple tables
module.mpairs = function(t, ...)
    local i, a, k, v = 1, { ... }
    return
    function()
        repeat
            k, v = next(t, k)
            if k == nil then
                i, t = i + 1, a[i]
            end
        until k ~= nil or not t
        return k, v
    end
end

module.shuffle = function(array)
    local shuffledArray = {}
    while #array > 0 do
        local rand = math.random(#array)
        table.insert(shuffledArray, array[rand])
        table.remove(array, rand)
    end
    return shuffledArray
end

return module