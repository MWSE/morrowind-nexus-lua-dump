local module = {}

local goldIds = { gold_001 = true, gold_005 = true, gold_010 = true, gold_025 = true, gold_100 = true }

module.isObjectInvalid = function(obj)
    return not obj:isValid() or obj.count == 0
end

module.areObjectEquals = function(obj1, obj2)
    return (obj1 and obj1.id or "") == (obj2 and obj2.id or "")
end

local function actorId(actor)
    return string.format("<%s (%s)>", actor.recordId, actor.id)
end
module.actorId = actorId

local function isGold(recordId)
    return goldIds[recordId]
end
module.isGold = isGold

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

module.average = function(list, getter)
    if #list == 0 then return 0 end
    if #list == 1 then return getter(list[1]) end
    local sum = 0
    for _, element in ipairs(list) do
        sum = sum + getter(element)
    end
    return sum / #list
end

module.areObjectEquals = function(obj1, obj2)
    return (obj1 and obj1.id or "") == (obj2 and obj2.id or "")
end

return module