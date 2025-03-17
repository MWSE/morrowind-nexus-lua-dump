local module = {}

module.mapSize = function(table)
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

module.arraysToMap = function(arrays, getKey)
    local map = {}
    for _, array in ipairs(arrays) do
        map[getKey(array)] = array
    end
    return map
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

module.addAllMapsToMap = function(target, sources, filter)
    if not sources or #sources == 0 then return target end
    for _, source in ipairs(sources) do
        for k, v in pairs(source) do
            if not filter or filter(k, v) then
                target[k] = v
            end
        end
    end
    return target
end

module.addAllToArray = function(target, source, filter)
    if not source then return target end
    for _, v in ipairs(source) do
        if not filter or filter(v) then
            table.insert(target, v)
        end
    end
    return target
end

module.addAllToHashset = function(target, source)
    for _, v in ipairs(source) do
        target[v] = true
    end
    return target
end

module.tableToString = function(val, level)
    local subLevel = (level or 1) - 1
    local ok, iter, t = pcall(function() return pairs(val) end)
    if subLevel < 0 or not ok then
        return tostring(val)
    end
    local strings = { tostring(val) .. '{ ' }
    for k, v in iter, t do
        strings[#strings + 1] = " " .. tostring(k) .. ' = ' .. module.tableToString(v, subLevel) .. ', '
    end
    strings[#strings + 1] = ' }'
    return table.concat(strings)
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