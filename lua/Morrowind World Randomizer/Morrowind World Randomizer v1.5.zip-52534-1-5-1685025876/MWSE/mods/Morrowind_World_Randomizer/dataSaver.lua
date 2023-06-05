local this = {}

local fieldName = "MWRandomizerByDiject"

function this.getObjectTempData(object)
    if object == nil or object.tempData == nil then
        return nil
    end
    local data = object.tempData
    if data[fieldName] == nil then
        data[fieldName] = {}
    end
    return data[fieldName]
end

function this.getObjectData(object)
    if object == nil or object.data == nil then
        return nil
    end
    local data = object.data
    if data[fieldName] == nil then
        data[fieldName] = {}
    end
    if object.modified ~= nil then object.modified = true end
    return data[fieldName]
end

return this