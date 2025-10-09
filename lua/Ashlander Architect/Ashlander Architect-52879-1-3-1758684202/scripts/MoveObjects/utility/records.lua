local data = require("scripts.MoveObjects.utility.record_data")
local types = require("openmw.types")
local world = require("openmw.world")
local storage = require("openmw.storage")

local config = require("scripts.MoveObjects.config")
local cellGenStorage = storage.globalSection("AACellGen2")
local RecordStorage = storage.globalSection("RecordStorage")
local vtype = nil
local createdRecords = {}
local doorSoundMap = {}
RecordStorage:set("createdRecords",createdRecords)
cellGenStorage:set("doorSoundMap",doorSoundMap)
local function getRecordSafe(recordId, type)
    recordId = recordId
    if not type then
        for key, xtype in pairs(types) do
            vtype = xtype
            local success, result = pcall(function()
                return vtype.records[recordId]
            end)

            if success then
                return result
            end
        end
        return nil
    end
    
    return type.records[recordId]
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
local function getRecord(recordId, type)
    
    local existingRecord = getRecordSafe(recordId)
    if existingRecord then
        return existingRecord.id
    end
    local tempRecord = createdRecords[recordId:lower()]
    if tempRecord ~= nil then
        print(tempRecord)
        return tempRecord
    end
    local dataValue = data[recordId:lower()]
    if dataValue then
        local draft = getRecordDraft(dataValue)
        local newRecord = world.createRecord(draft)
        createdRecords[recordId:lower()] = newRecord.id
        RecordStorage:set("createdRecords",createdRecords)
        return newRecord.id
    end
end
local function getDoorActivatorRecord(recordId)
    local existingRecord = createdRecords[recordId]
    if existingRecord then
        return types.Activator.records[existingRecord]
    end
    local baseRecord = types.Door.records[recordId]
    local dataValue = {model = baseRecord.model}
    if dataValue then
        local draft = types.Activator.createRecordDraft(dataValue)
        local newRecord = world.createRecord(draft)
        createdRecords[recordId:lower()] = newRecord.id
        RecordStorage:set("createdRecords",createdRecords)
        doorSoundMap[newRecord.id] = baseRecord.openSound
        cellGenStorage:set("doorSoundMap",doorSoundMap)
        return newRecord
    end
end
local function getDoorOrigID(doorId)
for index, value in pairs(createdRecords) do
    if value == doorId then
        return index,createdRecords
    end
end
return nil
end
local function renameRecord(recordId,newName,newType)


end
local function onSave()
return {createdRecords = createdRecords,doorSoundMap = doorSoundMap}
end
local function onLoad(data)

createdRecords = data.createdRecords
RecordStorage:set("createdRecords",createdRecords)
if data.doorSoundMap then
    
doorSoundMap = data.doorSoundMap
cellGenStorage:set("doorSoundMap",doorSoundMap)
end
end
return {
    interfaceName = "AA_Records",
    interface = {
        version = 1,
        getRecordSafe = getRecordSafe,
        getRecord = getRecord,
        getDoorActivatorRecord = getDoorActivatorRecord,
        getDoorOrigID = getDoorOrigID
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
    },
}
