local world = require("openmw.world")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local anim = require('openmw.animation')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')

local createdLightOffRecords = {}
local createdLightOnRecords = {}
local createdLightOffObjects = {}
local createdLightOnObjects = {}
local lightState = {}
local originalRecordIds = {}
local function getNearbyById(cell, objId)
    for index, value in ipairs(cell:getAll(types.Light)) do
        if value.id == objId then
            return value
        end
    end
end
local function getOffRecord(recordId)
    if createdLightOffRecords[recordId] then
        return createdLightOffRecords[recordId]
    end
    local newRecordDraft = types.Light.createRecordDraft({ template = types.Light.records[recordId], isOffByDefault = true })
    local newRecord = world.createRecord(newRecordDraft)
    originalRecordIds[newRecord.id] = recordId
    createdLightOffRecords[recordId] = newRecord.id
    createdLightOnRecords[newRecord.id] = recordId
    return newRecord.id
end
local function getOnRecord(recordId)
    if createdLightOnRecords[recordId] then
        return createdLightOnRecords[recordId]
    end
    local newRecordDraft = types.Light.createRecordDraft({ template = types.Light.records[recordId], isOffByDefault = false })
    local newRecord = world.createRecord(newRecordDraft)
    originalRecordIds[newRecord.id] = recordId
    createdLightOnRecords[recordId] = newRecord.id
    createdLightOffRecords[newRecord.id] = recordId
    return newRecord.id
end
local function turnLightOff(obj)
    local record = obj.type.records[obj.recordId]
    if obj.recordId == "light_dae_brazier00" then
        return
    end
    if record.isOffByDefault then
        return
    end
    if createdLightOffObjects[obj.id] then
        local offObj = getNearbyById(obj.cell, createdLightOffObjects[obj.id])
        if not offObj then
            error("Unable to find " .. createdLightOffObjects[obj.id])
        end
        offObj.enabled = true
        offObj:setScale(obj.scale)
        obj.enabled = false
    else
        local newRecord = getOffRecord(obj.recordId)
        local newObject = world.createObject(newRecord)
        createdLightOffObjects[obj.id] = newObject.id
        createdLightOnObjects[newObject.id] = obj.id
        newObject:setScale(obj.scale)
        newObject:teleport(obj.cell, obj.position, obj.rotation)
        obj.enabled = false
    end
end
local function turnLightOn(obj)
    local record = obj.type.records[obj.recordId]
    if not record.isOffByDefault then
        return
    end
    if createdLightOnObjects[obj.id] then
        local onObj = getNearbyById(obj.cell, createdLightOnObjects[obj.id])
        if not onObj then
            error("Unable to find " .. createdLightOnObjects[obj.id])
        end
        onObj.enabled = true
        obj.enabled = false
    else
        --    local newRecord = getOffRecord(obj.recordId)
        --    local newObject = world.createObject(newRecord)
        --     createdLightOffObjects[obj.id] = newObject.id
        --     createdLightOnObjects[newObject.id] = obj.id
        --     newObject:teleport(obj.cell,obj.position,obj.rotation)
    end
end
local function turnCellLightsOff(cell)
    if not cell.getAll then
        cell = world.getCellById(cell)
    end
    lightState[cell.id] = false
    for index, value in ipairs(cell:getAll(types.Light)) do
        local shouldShow = I.roomLayers.objectShouldBeShown(value)
        if not shouldShow then
            value.enabled = false
        else
            turnLightOff(value)
            
        end
    end
end
local function getCellLightState(cellId)
    return lightState[cellId]
end
local function turnCellLightsOn(cell)
    if not cell.getAll then
        cell = world.getCellById(cell)
    end
    lightState[cell.id] = true
    for index, value in ipairs(cell:getAll(types.Light)) do
        turnLightOn(value)
    end
end
local function getOriginalRecordId(recordId)
    return originalRecordIds[recordId]
end
return
{
    interfaceName = "Hestatur_Light",
    interface = {
        turnLightOff = turnLightOff,
        turnLightOn = turnLightOn,
        turnCellLightsOn = turnCellLightsOn,
        turnCellLightsOff = turnCellLightsOff,
        getOriginalRecordId = getOriginalRecordId,
        getCellLightState = getCellLightState,
    },
    engineHandlers = {
        onSave = function()
            return {
                createdLightOffObjects = createdLightOffObjects,
                createdLightOffRecords = createdLightOffRecords,
                createdLightOnObjects = createdLightOnObjects,
                originalRecordIds = originalRecordIds,
                lightState = lightState,
            }
        end,
        onLoad = function(data)
            if data then
                createdLightOffObjects = data.createdLightOffObjects
                createdLightOffRecords = data.createdLightOffRecords
                createdLightOnObjects = data.createdLightOnObjects
                originalRecordIds = data.originalRecordIds
                lightState = data.lightState or {}
            end
        end
    },
    eventHandlers = {
        turnLightOff_Hest = turnLightOff,
        turnLightOn_Hest = turnLightOn,
        turnCellLightsOn_Hest = turnCellLightsOn,
        turnCellLightsOff_Hest = turnCellLightsOff,
    }
}
