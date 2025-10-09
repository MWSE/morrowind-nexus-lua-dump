---@diagnostic disable: undefined-doc-name
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local player = require('openmw.self')
local async = require('openmw.async')
local storage = require('openmw.storage')

local common = require("scripts.proximityTool.common")

local log = require("scripts.proximityTool.utils.log")
local uniqueId = require("scripts.proximityTool.uniqueId")
local activeObjects = require("scripts.proximityTool.activeObjects")
local hudmHandler = require("scripts.proximityTool.hudmHandler")
local cellLib = require("scripts.proximityTool.cell")

local getObject = require("scripts.proximityTool.utils.getObject")
local tableLib = require("scripts.proximityTool.utils.table")

local icons = require("scripts.proximityTool.icons")

local mainMenu = require("scripts.proximityTool.ui.mainMenu")
local activeMarkers = require("scripts.proximityTool.activeMarkers")
local safeUIContainers = require("scripts.proximityTool.ui.safeContainer")

local mapData = require("scripts.proximityTool.data.mapDataHandler")

local realTimer = require("scripts.proximityTool.realTimer")

local config = require("scripts.proximityTool.config")

local settingStorage = storage.playerSection(common.settingStorageId)


---@class proximityTool.cellData
---@field id string?
---@field gridX integer?
---@field gridY integer?
---@field isExterior boolean

---@class proximityTool.position
---@field cell proximityTool.cellData
---@field position {x: number, y: number, z: number}

---@class proximityTool.activeMarkerData
---@field type integer 1 - object id, 2 - game object, 4 - position, 8 - group of objects, 16 - text
---@field marker proximityTool.markerData
---@field id string?
---@field recordId string?
---@field record proximityTool.markerRecord
---@field name string?
---@field proximity number?
---@field priority number?
---@field noteId string?
---@field cellWhereRegistered any?
---@field isValid boolean?

---@class proximityTool.markerData
---@field record proximityTool.markerRecord|string?
---@field HUDMRecord proximityTool.HUDMarkersRecord|string?
---@field id string?
---@field groupId string?
---@field groupName string?
---@field positions proximityTool.position[]?
---@field objectId string?
---@field object any?
---@field objects any[]?
---@field objectIds string[]?
---@field itemId string?
---@field temporary boolean? if true, this marker will not be saved to the save file
---@field shortTerm boolean? if true, this marker will be deleted after the cell has changed
---@field userData table?
---@field invalid boolean?

---@class proximityTool.markerRecord.options
---@field showGroupIcon boolean? *true* by default
---@field showNoteIcon boolean? *true* by default
---@field enableGroupEvent boolean? *true* by default
---@field trackAllTypesTogether boolean? *false* by default
---@field hideDead boolean? *false* by default

---@class proximityTool.markerRecord
---@field id string?
---@field name string?
---@field description string|string[]?
---@field note string?
---@field nameColor number[]?
---@field descriptionColor number[]|number[][]?
---@field noteColor number[]?
---@field icon string?
---@field iconColor number[]?
---@field iconRatio number? image height to width ratio
---@field hidden boolean?
---@field alpha number?
---@field proximity number?
---@field priority number?
---@field temporary boolean? if true, this record will not be saved to the save file
---@field events table<string, string>?
---@field userData table?
---@field options proximityTool.markerRecord.options?
---@field invalid boolean?

---@class proximityTool.HUDMarker
---@field modName string required
---@field id string?
---@field objects any[]? list of object references that this marker should track
---@field objectIds string[]? list of object record ids that this marker should track
---@field itemId string? markers will be removed for objects that do not have this item. Unresolved containers are considered as having it
---@field params table required. HUDM parameters
---@field version number HUDM version for this marker
---@field hideDead boolean? hide markers for dead actors
---@field isHUDM boolean true
---@field hidden boolean? if true, this marker will not be shown
---@field temporary boolean? if true, this marker will not be saved to the save file
---@field shortTerm boolean? if true, this marker will be removed after one of the tracked objects is removed
---@field invalid boolean?


local lastUIMode


if config.data.enabled then
    mainMenu.create{showBorder = false}
end

local function updateTimer()
    mainMenu.update()
end

local stopTimer = time.runRepeatedly(updateTimer, config.data.updateInterval / 1000 * time.second, { type = time.SimulationTime })

settingStorage:subscribe(async:callback(function(section, key)
    local enabled = settingStorage:get("enabled")
    if enabled then
        mainMenu.create{showBorder = false}
        if stopTimer then
            stopTimer()
        end
        stopTimer = time.runRepeatedly(updateTimer, config.data.updateInterval / 1000 * time.second, { type = time.SimulationTime })
    else
        if stopTimer then
            stopTimer()
            stopTimer = nil
        end
        mainMenu.destroy()
    end
end))


I.Settings.registerGroup{
    key = common.settingStorageToRemoveId,
    page = common.settingPage,
    l10n = common.l10nKey,
    name = "removeAllGroup",
    permanentStorage = false,
    order = 1,
    settings = {
        {
            key = "removeAll",
            renderer = "checkbox",
            name = "removeAllMarkers",
            description = "removeAllMarkersDescription",
            default = false,
        }
    },
}

local isStorageTimerRunning = false
local storageToRemove = storage.playerSection(common.settingStorageToRemoveId)
storageToRemove:subscribe(async:callback(function(section, key)
    local remove = storageToRemove:get("removeAll")
    if remove == true and not isStorageTimerRunning then
        isStorageTimerRunning = true
        async:newUnsavableSimulationTimer(0.1, function ()
            isStorageTimerRunning = false
            if storageToRemove:get("removeAll") then
                mapData.removeAll()
                activeMarkers.update()
                hudmHandler.update()
                storageToRemove:set("removeAll", false)
            end
        end)
    end
end))



---@param params proximityTool.markerRecord
---@return string?
local function addRecord(params)
    ---@type proximityTool.markerRecord
    local record = tableLib.deepcopy(params)
    record.id = uniqueId.get()
    mapData.addRecord(record.id, params)
    return record.id
end


---@param markerData proximityTool.markerData
local function registerMarker(markerData)
    if markerData.invalid then return end
    local valid = false
    if markerData.groupId == common.textMarkerLabel then
        valid = true
    else
        if markerData.positions and cellLib.isContainValidPosition(markerData.positions) then
            valid = true
        end
        if markerData.objectId and activeObjects.isContainValidRecordId(markerData.objectId) then
            valid = true
        end
        if markerData.object and activeObjects.isContainRefId(markerData.object.recordId, markerData.object.id) then
            valid = true
        end
        if markerData.objects and activeObjects.isCointainValidRefs(markerData.objects) then
            valid = true
        end
        if markerData.objectIds and activeObjects.isContainValidRecordIds(markerData.objectIds) then
            valid = true
        end
    end

    if not valid then return end

    local marker = activeMarkers.register(markerData)
    if not marker then return end

    mainMenu.registerMarker(marker)
end


local function registerTextMarkers()
    for id, data in mapData.iterMarkerGroup(common.textMarkerLabel) do
        registerMarker(data)
    end
end


local function registerMarkersForCell()
    mainMenu.update()
    local cellId = player.cell.isExterior and common.worldCellLabel or player.cell.id
    for id, data in mapData.iterMarkerGroup(cellId) do
        registerMarker(data)
    end
    activeMarkers.update()
end


---@param data proximityTool.markerData
---@return string? id
---@return string? groupId
local function addMarker(data)
    if not data then
        log("addMarker: Error: data not provided.")
        return
    end
    if not data.record then
        log("addMarker: Error: record parameter not provided.")
        return
    end

    ---@type proximityTool.markerData
    local markerData = tableLib.deepcopy(data)

    markerData.id = uniqueId.get()
    local groupId

    if markerData.objectIds then
        local markerDataCopy = tableLib.deepcopy(markerData)
        markerDataCopy.groupId = common.objectsLabel
        for _, objId in pairs(markerDataCopy.objectIds) do
            local dt = tableLib.deepcopy(markerDataCopy)
            dt.groupId = objId
            mapData.addMarker(markerDataCopy.id, dt.groupId, dt)
        end
        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
        groupId = markerDataCopy.groupId
    end

    if markerData.positions then
        local markerDataCopy = tableLib.deepcopy(markerData)
        markerDataCopy.groupId = common.positionsLabel
        for _, posData in pairs(markerDataCopy.positions) do
            local dt = tableLib.deepcopy(markerDataCopy)
            dt.groupId = posData.cell.isExterior and common.worldCellLabel or posData.cell.id
            if dt.groupId then
                mapData.addMarker(markerDataCopy.id, dt.groupId, dt)
            end
        end
        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
        groupId = markerDataCopy.groupId
    end

    if markerData.object then
        local markerDataCopy = tableLib.deepcopy(markerData)
        markerDataCopy.groupId = markerData.object.id

        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
        groupId = markerDataCopy.groupId
    end

    if markerData.objects then
        local markerDataCopy = tableLib.deepcopy(markerData)
        markerDataCopy.groupId = common.referencesLabel
        for _, obj in pairs(markerDataCopy.objects) do
            local dt = tableLib.deepcopy(markerDataCopy)
            dt.groupId = obj.id
            mapData.addMarker(markerDataCopy.id, dt.groupId, dt)
        end
        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
        groupId = markerDataCopy.groupId
    end

    if markerData.objectId then
        local markerDataCopy = tableLib.deepcopy(markerData)
        markerDataCopy.groupId = markerData.objectId

        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
        groupId = markerDataCopy.groupId
    end

    markerData.groupId = groupId or common.textMarkerLabel
    mapData.addMarker(markerData.id, markerData.groupId, markerData)

    registerMarker(markerData)

    return markerData.id, markerData.groupId
end


---@param id string
---@param data proximityTool.markerRecord
---@return boolean?
local function updateRecord(id, data)
    if not id then
        log("updateRecord: Error: id not provided.")
    end
    if not data then data = {} end

    local recordData = mapData.getRecord(id)
    if not recordData then
        log("updateRecord: Error: record data not found.")
        return
    end

    local dt = tableLib.deepcopy(data)
    dt.id = nil

    tableLib.applyChanges(recordData, dt)

    return true
end


---@param id string
---@param groupId string?
---@param val boolean
---@return boolean?
local function setVisibility(id, groupId, val)

    if groupId then
        local markersData = mapData.getMarkers(id, groupId)
        if not markersData then
            log(string.format("setVisibility: Error: marker data not found. id %s, groupId %s", tostring(id), tostring(groupId)))
            return false
        end

        for _, markerData in pairs(markersData) do
            local record = mapData.getRecordData(markerData)
            if record then
                record.hidden = not val
            end
        end
    else
        local record = mapData.getRecord(id)
        if not record then
            log(string.format("setVisibility: Error: record data not found. id %s", tostring(id)))
            return false
        end

        record.hidden = not val
    end

    return true
end


local function setUserData(id, groupId, newUserData)
    if groupId then
        local markersData = mapData.getMarkers(id, groupId)
        if not markersData then
            log(string.format("updateUserData: Error: marker data not found. id %s, groupId %s", tostring(id), tostring(groupId)))
            return false
        end

        for _, markerData in pairs(markersData) do
            if markerData.userData then
                tableLib.clear(markerData.userData)
                tableLib.deepcopy(newUserData, markerData.userData)
            else
                markerData.userData = tableLib.deepcopy(newUserData)
            end
        end
    else
        local record = mapData.getRecord(id)
        if not record then
            log(string.format("updateUserData: Error: record data not found. id %s", tostring(id)))
            return false
        end

        if record.userData then
            tableLib.clear(record.userData)
            tableLib.deepcopy(newUserData, record.userData)
        else
            record.userData = tableLib.deepcopy(newUserData)
        end
    end

    return true
end


---@param id string
---@param groupId string?
local function getMarkerData(id, groupId)
    if not id then
        log("getMarkerData: Error: id parameter not provided.")
        return
    end
    local markerData
    if groupId then
        markerData = mapData.getMarker(id, groupId)
    else
        markerData = mapData.getRecord(id)
    end

    if markerData then
        markerData = tableLib.deepcopy(markerData)
    else
        return
    end

    markerData.invalid = nil
    if markerData.record and type(markerData.record) == "table" then
        markerData.record.invalid = nil
    end

    return markerData
end


---@param data proximityTool.HUDMarker
---@return string?
local function addHUDMarker(data)
    if not data or not data.modName or not data.params then
        log("addHUDMarker: Error: modName or params fields not found.")
        return
    end

    ---@type proximityTool.HUDMarker
    local markerData = tableLib.deepcopy(data)

    markerData.id = uniqueId.get()
    markerData.version = markerData.version or hudmHandler.version or 5
    markerData.isHUDM = true

    if markerData.version < 5 then
        log("addHUDMarker: Error: HUDMarkers version must be at least 5.")
        return
    end

    if markerData.objects then
        for _, objectRef in pairs(markerData.objects) do
            mapData.addHUDMarker(objectRef.id, markerData)
            hudmHandler.addObject(objectRef)
        end
    end

    if markerData.objectIds then
        for _, objectId in pairs(markerData.objectIds) do
            mapData.addHUDMarker(objectId, markerData)

            local objs = activeObjects.getValidObjects(objectId)
            for _, obj in pairs(objs or {}) do
                hudmHandler.addObject(obj)
            end
        end
    end

    mapData.addHUDMarker(markerData.id, markerData)
    return markerData.id
end


---@param id string
---@return proximityTool.HUDMarker?
local function getHUDMdata(id)
    if not id then
        log("getHUDMdata: Error: parameter not provided.")
        return
    end
    local markers = mapData.getHUDMarkers(id)
    if not markers then return end

    local markerData = markers[id]

    if markerData then
        markerData = tableLib.deepcopy(markerData)
    end
    markerData.invalid = nil

    return markerData
end


---@param id string
---@param val boolean
---@return boolean?
local function setHUDMvisibility(id, val)
    if not id then
        log("setHUDMvisibility: Error: id parameter not provided.")
        return
    end

    local markers = mapData.getHUDMarkersByMarkerId(id)
    if not markers then return end

    for i, markerData in pairs(markers) do
        markerData.hidden = not val
    end

    return true
end


local function removeHUDMarker(id)
    if not id then
        log("removeHUDMarker: Error: id parameter not provided.")
        return
    end
    return mapData.removeHUDMarker(id)
end


local function updateHUDMarkers()
    hudmHandler.update()
end


local function updateMarkers()
    activeMarkers.update()
end


local function removeAllMarkersAndRecords()
    mapData.removeAll()
end


---@param groupName string
local function removeGroupNameMarkers(groupName)
    mapData.removeMarkersByGroupName(groupName)
end


---@param modName string
local function removeHUDMModMarkers(modName)
    mapData.removeAllHUDMarkers(modName)
end



return {
    interfaceName = "proximityTool",
    interface = {
        version = 1,
        addMarker = addMarker,
        addRecord = addRecord,
        addHUDM = addHUDMarker,
        removeHUDM = removeHUDMarker,
        update = updateMarkers,
        updateHUDM = updateHUDMarkers,
        updateRecord = updateRecord,
        setUserData = setUserData,
        getMarkerData = getMarkerData,
        getHUDMdata = getHUDMdata,
        setVisibility = setVisibility,
        setHUDMvisibility = setHUDMvisibility,
        removeRecord = function (recordId)
            return mapData.removeRecord(recordId)
        end,
        removeMarker = function (id, groupId)
            return mapData.removeMarker(id, groupId)
        end,
        -- removeAllMarkersAndRecords = removeAllMarkersAndRecords,
        removeGroupNameMarkers = removeGroupNameMarkers,
        removeHUDMModMarkers = removeHUDMModMarkers,

        newRealTimer = realTimer.newTimer,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if not config.data.enabled then return end

            if data.newMode == nil and (lastUIMode ~= nil and lastUIMode ~= "Loading" or mainMenu.element == nil) then
                mainMenu.create{showBorder = false}
            elseif data.newMode == "Interface" then
                mainMenu.create{showBorder = true}
                for i = 1, 3 do
                    mainMenu.update{force = true}
                end
            elseif data.newMode ~= nil and config.data.ui.hideHUDInMenus then
                mainMenu.destroy()
            end

            lastUIMode = data.newMode
        end,
        ["proximityTool:addActiveObject"] = function(object)
            activeObjects.add(object)
            local registered = false
            for id, data in mapData.iterMarkerGroup(object.id) do
                registerMarker(data)
                registered = true
            end
            for id, data in mapData.iterMarkerGroup(object.recordId) do
                registerMarker(data)
                registered = true
            end

            hudmHandler.addObject(object)
        end,
        ["proximityTool:removeActiveObject"] = function(objectData)
            local refId = objectData[2]
            local recordId = objectData[3]
            activeObjects.remove(refId, recordId)
            activeMarkers.update(recordId)

            hudmHandler.removeObject(refId)
        end,
    },
    engineHandlers = {
        onFrame = function(dt)
            realTimer.updateTimers()
        end,
        onSave = function()
            local data = {}

            uniqueId.save()
            mapData.save(data)

            return data
        end,
        onLoad = function (data)
            mapData.load(data)
            registerTextMarkers()
        end,
        onTeleported = function ()
            async:newUnsavableSimulationTimer(0.5, function () -- delay for the player cell data to be updated
                registerMarkersForCell()
            end)
        end,
        onActive = function ()
            registerMarkersForCell()
        end,
        onMouseWheel = function (value)
            if not mainMenu.element or I.UI.getMode() == nil then return end

            local function onMouseWheelCallback(content)
                for _, dt in pairs(content) do
                    if not type(dt) == "table" then goto continue end
                    if dt.userData and dt.userData.onMouseWheel then
                        dt.userData.onMouseWheel(dt, value)
                    end

                    if dt.content then
                        onMouseWheelCallback(dt.content)
                    end

                    ::continue::
                end
            end

            local layout = mainMenu.element.layout
            onMouseWheelCallback(layout.content)
        end,
    },
}