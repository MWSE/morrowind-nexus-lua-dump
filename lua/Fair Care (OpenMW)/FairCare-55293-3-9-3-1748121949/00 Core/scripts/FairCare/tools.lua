local mSettings = require('scripts.FairCare.settings')

local module = {}

local function debugPrint(str)
    if mSettings.getSection(mSettings.globalKey):get("debugMode") then
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

local function objectId(object)
    return string.format("<%s (%s)>", getRecord(object).id, object.id)
end
module.objectId = objectId

local function objectsIds(objects)
    local ids = {}
    if #objects ~= 0 then
        for _, actor in ipairs(objects) do
            table.insert(ids, objectId(actor))
        end
    else
        for _, actor in pairs(objects) do
            table.insert(ids, objectId(actor))
        end
    end
    return table.concat(ids, ", ")
end
module.objectsIds = objectsIds

local function isObjectInvalid(obj)
    return not obj:isValid() or obj.count == 0
end
module.isObjectInvalid = isObjectInvalid

local function areObjectEquals(obj1, obj2)
    return (obj1 and obj1.id or "") == (obj2 and obj2.id or "")
end
module.areObjectEquals = areObjectEquals

local function clamp(value, min, max)
    return math.min(max, math.max(min, value))
end
module.clamp = clamp

local function pick(list)
    return list[math.random(1, #list)]
end
module.pick = pick

local function insertAllInList(sourceList, list)
    for _, value in ipairs(list) do
        table.insert(sourceList, value)
    end
    return sourceList
end
module.insertAllInList = insertAllInList

-- loop over sorted values
local function spairs(t, order)
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
module.spairs = spairs

-- loop over multiple tables
local function mpairs(t, ...)
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
module.mpairs = mpairs

local function shuffle(array)
    local shuffledArray = {}
    while #array > 0 do
        local rand = math.random(#array)
        table.insert(shuffledArray, array[rand])
        table.remove(array, rand)
    end
    return shuffledArray
end
module.shuffle = shuffle

return module