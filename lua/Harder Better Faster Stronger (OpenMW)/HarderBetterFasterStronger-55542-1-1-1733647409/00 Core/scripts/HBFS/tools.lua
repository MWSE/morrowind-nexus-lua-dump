local mSettings = require('scripts.HBFS.settings')

local module = {}

local function debugPrint(str)
    if mSettings.globalSection():get("debugMode") then
        print("DEBUG: " .. str)
    end
end
module.debugPrint = debugPrint

local function getRecord(item)
    if item.type and item.type.record then
        return item.type.record(item)
    end
    return nil
end
module.getRecord = getRecord

local function actorId(actor)
    return string.format("<%s (%s)>", getRecord(actor).id, actor.id)
end
module.actorId = actorId

local function actorIds(actors)
    local ids = {}
    if #actors ~= 0 then
        for _, actor in ipairs(actors) do
            table.insert(ids, actorId(actor))
        end
    else
        for _, actor in pairs(actors) do
            table.insert(ids, actorId(actor))
        end
    end
    return table.concat(ids, ", ")
end
module.actorIds = actorIds

local function isObjectInvalid(obj)
    return not obj:isValid() or obj.count == 0
end
module.isObjectInvalid = isObjectInvalid

local function areObjectEquals(obj1, obj2)
    return (obj1 and obj1.id or "") == (obj2 and obj2.id or "")
end
module.areObjectEquals = areObjectEquals

local aux_util = require('openmw_aux.util')
-- loop over sorted and optionally filtered values
local spairs = function(t, order, filter)
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
module.spairs = spairs

local function average(list, getter)
    if #list == 0 then return 0 end
    if #list == 1 then return getter(list[1]) end
    local sum = 0
    for _, element in ipairs(list) do
        sum = sum + getter(element)
    end
    return sum / #list
end
module.average = average

return module