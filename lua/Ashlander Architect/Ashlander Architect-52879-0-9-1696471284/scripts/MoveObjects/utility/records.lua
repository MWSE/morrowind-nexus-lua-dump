local data = require("scripts.MoveObjects.utility.record_data")
local types = require("openmw.types")
local world = require("openmw.world")
local vtype = nil
local createdRecords = {}
local function getRecordSafe(recordID, type)
    recordID = recordID
    if not type then
        for key, xtype in pairs(types) do
            vtype = xtype
            local success, result = pcall(function()
                return vtype.record(recordID)
            end)

            if success then
                return result
            end
        end
        return nil
    end
    local success, result = pcall(function()
        return type.record(recordID)
    end)

    if success then
        return result
    else
        return nil
    end
end
local function getRecordDraft(data)
    local ret = {}
    local type = data.type
    if type == "MiscItem" then
        type = types.Miscellaneous
    end
    ret.name = data.name

    if data.data then
        ret.value = data.data.value
        ret.weight = data.data.weight

    end
    ret.model = "meshes\\" ..data.mesh
    ret.icon = "icons\\" .. data.icon
return type.createRecordDraft(ret)
end
local function getRecord(recordName, type)
    local existingRecord = getRecordSafe(recordName)
    if existingRecord then
        return existingRecord
    end
    local tempRecord = createdRecords[recordName:lower()]
    if tempRecord ~= nil then
        print(tempRecord)
        return getRecordSafe(tempRecord)
    end
    local dataValue = data[recordName:lower()]
    if dataValue then
        local draft = getRecordDraft(dataValue)
        local newRecord = world.createRecord(draft)
        createdRecords[recordName:lower()] = newRecord.id
        print(newRecord.id)
        return newRecord
    end
end
local function onSave()
return {createdRecords = createdRecords}
end
local function onLoad(data)

createdRecords = data.createdRecords
end
return {
    interfaceName = "AA_Records",
    interface = {
        version = 1,
        getRecordSafe = getRecordSafe,
        getRecord = getRecord,
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
    },
}
