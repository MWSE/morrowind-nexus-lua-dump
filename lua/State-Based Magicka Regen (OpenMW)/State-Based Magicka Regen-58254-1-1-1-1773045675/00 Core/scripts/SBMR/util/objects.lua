local log = require("scripts.SBMR.util.log")

local module = {}

module.objectId = function(object)
    return string.format("<%s (%s)>", object.recordId, object.id)
end

module.isObjectInvalid = function(object)
    return not object or not object:isValid() or object.count == 0
end

module.fixObjects = function(dataLists)
    for key, dataList in pairs(dataLists) do
        local invalidCt, changedIdCt = 0, 0
        for id, data in pairs(dataList) do
            if module.isObjectInvalid(data.object) then
                invalidCt = invalidCt + 1
                dataList[id] = nil
            elseif id ~= data.object.id then
                changedIdCt = changedIdCt + 1
                dataList[id] = nil
                dataList[data.object.id] = data
            end
        end
        if invalidCt + changedIdCt > 0 then
            log(string.format("Cleared %d invalid references and fixed %d changed IDs for %s", invalidCt, changedIdCt, key))
        end
    end
end

return module