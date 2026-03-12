
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local time = require("openmw_aux.time")
local player = require("openmw.self")
local async = require("openmw.async")
local storage = require("openmw.storage")
local input = require("openmw.input")
local core = require("openmw.core")

local common = require("scripts.advanced_world_map_tracking.common")

local log = require("scripts.advanced_world_map_tracking.utils.log")
local uniqueId = require("scripts.advanced_world_map_tracking.uniqueId")
local activeObjects = require("scripts.advanced_world_map_tracking.handlers.activeObjects")
local mapHandler = require("scripts.advanced_world_map_tracking.handlers.mapHandler")

local getObject = require("scripts.advanced_world_map_tracking.utils.getObject")
local tableLib = require("scripts.advanced_world_map_tracking.utils.table")


local activeMarkers = require("scripts.advanced_world_map_tracking.handlers.activeMarkers")

local mapData = require("scripts.advanced_world_map_tracking.data.dataHandler")

local config = require("scripts.advanced_world_map_tracking.config.configLib")

-- local l10n = core.l10n(common.l10nKey)


---@class advWMap_tracking.position
---@field id string?
---@field pos Vector3


---@class advWMap_tracking.markerTemplateData
---@field id string?
---@field path string
---@field pathA string?
---@field pathB string?
---@field layer string?
---@field size Vector2
---@field color Color?
---@field anchor Vector2?
---@field tText string|string[]|nil -- tooltip text
---@field tEvent boolean?
---@field temp boolean? -- Default: true
---@field short boolean?
---@field userData any?
---@field visible boolean? -- Default: true
---@field onClick fun(e: {button: integer, marker: advWMap_tracking.markerData, template: advWMap_tracking.markerTemplateData, object: GameObject?})|string|nil
---@field invalid boolean?

---@class advWMap_tracking.markerData
---@field id string?
---@field groupId string?
---@field template advWMap_tracking.markerTemplateData|string
---@field positions advWMap_tracking.position[]?
---@field objects GameObject[]?
---@field records string[]?
---@field types string[]?
---@field zoomOut boolean?
---@field alive boolean?
---@field item string?
---@field distance number?
---@field priority number?
---@field temp boolean? -- Default: true
---@field short boolean?
---@field single boolean?
---@field active boolean?
---@field activeEx boolean?
---@field userData any?
---@field invalid boolean?
---@field isVisibleFn fun(marker: advWMap_tracking.markerData, template: advWMap_tracking.markerTemplateData, object: GameObject?):boolean
---@field objValidateFn fun(marker: advWMap_tracking.markerData, template: advWMap_tracking.markerTemplateData, object: GameObject):boolean


I.Settings.registerGroup{
    key = common.settingStorageToRemoveId,
    page = common.settingPage,
    l10n = common.l10nKey,
    name = "RemoveAllGroup",
    permanentStorage = false,
    order = 1,
    settings = {
        {
            key = "removeAll",
            renderer = "checkbox",
            name = "RemoveAllMarkers",
            description = "RemoveAllMarkersDescription",
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
                storageToRemove:set("removeAll", false)
            end
        end)
    end
end))



async:newUnsavableSimulationTimer(0.01, function ()
    mapHandler.init()
end)



---@param params advWMap_tracking.markerTemplateData
---@return string?
local function addTemplate(params)
    params.id = params.id or uniqueId.get()
    mapData.addTemplate(params.id, params)

    return params.id
end


---@param markerData advWMap_tracking.markerData
local function registerMarker(markerData, object)
    if markerData.invalid then return end

    activeMarkers.register(markerData, object)
end


---@param objHandler advWMap_tracking.objectHandler
local function addMarkersForObject(objHandler)
    for id, data in mapData.iterMarkerGroup(objHandler.id) do
        registerMarker(data, objHandler)
    end
    for id, data in mapData.iterMarkerGroup(objHandler.recordId) do
        registerMarker(data, objHandler)
    end
    for id, data in mapData.iterMarkerGroup(tostring(objHandler.type)) do
        registerMarker(data, objHandler)
    end
end


---@param data advWMap_tracking.markerData
---@return string? id
---@return string? groupId
local function addMarker(data)
    if not data then
        log("addMarker: Error: data not provided.")
        return
    end
    if not data.template then
        log("addMarker: Error: template parameter not provided.")
        return
    end

    ---@type advWMap_tracking.markerData
    local markerData = data

    markerData.id = uniqueId.get()

    if markerData.records then
        local markerDataCopy = tableLib.copy(markerData)
        markerDataCopy.positions = nil
        markerDataCopy.records = nil
        markerDataCopy.objects = nil
        markerDataCopy.types = nil
        markerDataCopy.groupId = common.recordsLabel
        for _, recId in pairs(markerData.records) do
            local dt = tableLib.copy(markerDataCopy)
            dt.groupId = recId
            dt.records = {recId}
            mapData.addMarker(markerDataCopy.id, dt.groupId, dt)
            for _, obj in activeObjects.getObjectIterator(recId) do
                if mapHandler.activeCells[obj.cell.id] then
                    registerMarker(dt, obj)
                end
            end
        end
        markerDataCopy.records = markerData.records
        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
    end

    if markerData.positions then
        local markerDataCopy = tableLib.copy(markerData)
        markerDataCopy.positions = nil
        markerDataCopy.records = nil
        markerDataCopy.objects = nil
        markerDataCopy.types = nil
        markerDataCopy.groupId = common.positionsLabel
        local worldGr = markerDataCopy.zoomOut and common.worldCellLabel or nil

        local cellGroups = {}
        for _, posData in pairs(markerData.positions) do
            local grId = posData.id or worldGr or common.getCellIdByPos(posData.pos)
            local dt = cellGroups[grId] or tableLib.copy(markerDataCopy)
            dt.groupId = grId
            if not dt.positions then dt.positions = {} end
            table.insert(dt.positions, posData)
            cellGroups[grId] = dt
        end

        for grId, dt in pairs(cellGroups) do
            mapData.addMarker(markerDataCopy.id, dt.groupId, dt)
            if mapHandler.activeCells[grId] then
                registerMarker(dt)
            end
        end

        markerDataCopy.positions = markerData.positions
        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
    end

    if markerData.objects then
        local markerDataCopy = tableLib.copy(markerData)
        markerDataCopy.positions = nil
        markerDataCopy.records = nil
        markerDataCopy.objects = nil
        markerDataCopy.types = nil
        markerDataCopy.groupId = common.objectsLabel

        for _, obj in pairs(markerData.objects) do
            if obj:isValid() then
                local dt = tableLib.copy(markerDataCopy)
                dt.objects = {obj}
                dt.groupId = obj.id
                mapData.addMarker(markerDataCopy.id, dt.groupId, dt)
                if mapHandler.activeCells[obj.cell.id] then
                    registerMarker(dt, obj)
                end
            end
        end

        markerDataCopy.objects = markerData.objects

        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
    end

    if markerData.types then
        local markerDataCopy = tableLib.copy(markerData)
        markerDataCopy.positions = nil
        markerDataCopy.records = nil
        markerDataCopy.objects = nil
        markerDataCopy.types = nil
        markerDataCopy.groupId = common.typesLabel

        for _, typeId in pairs(markerData.types) do
            local dt = tableLib.copy(markerDataCopy)
            dt.groupId = typeId
            dt.types = {typeId}
            mapData.addMarker(markerDataCopy.id, dt.groupId, dt)
            for _, obj in activeObjects.getObjectIterator(typeId) do
                if mapHandler.activeCells[obj.cell.id] then
                    registerMarker(dt, obj)
                end
            end
        end

        markerDataCopy.types = markerData.types

        mapData.addMarker(markerDataCopy.id, markerDataCopy.groupId, markerDataCopy)
    end

    markerData.groupId = common.defaultMarkerLabel
    mapData.addMarker(markerData.id, markerData.groupId, markerData)

    return markerData.id
end


local function removeMarker(markerId)
    return mapData.removeMarker(markerId, common.defaultMarkerLabel)
end


local function removeTemplate(templateId)
    return mapData.removeTemplate(templateId)
end


---@param templateId string
---@param visible boolean
---@return boolean
local function setTemplateVisibility(templateId, visible)
    local template = mapData.getTemplate(templateId)
    if not template then return false end

    template.visible = visible

    return true
end


---@param templateId string
---@return advWMap_tracking.markerTemplateData?
local function getTemplate(templateId)
    return mapData.getTemplate(templateId)
end


---@param markerId string
---@return advWMap_tracking.markerData?
local function getMarker(markerId)
    return mapData.getMarker(markerId, common.defaultMarkerLabel)
end


local function isMarkerValid(id)
    local marker = mapData.getMarker(id, common.defaultMarkerLabel)
    if marker and not marker.invalid then return true end

    local template = mapData.getTemplate(id)
    if template and not template.invalid then return true end
    return false
end


local function updateMarkers()
    activeMarkers.update()
end


local function getMarkers(groupId)
    local markers = {}
    for _, markerData in mapData.iterMarkerGroup(groupId) do
        table.insert(markers, markerData)
    end

    return markers
end


local function isInitialized()
    return mapHandler.isInitialized()
end


return {
    interfaceName = "AdvWMap_tracking",
    interface = {
        version = 1,
        addMarker = addMarker,
        addTemplate = addTemplate,
        removeMarker = removeMarker,
        removeTemplate = removeTemplate,
        setTemplateVisibility = setTemplateVisibility,
        getTemplate = getTemplate,
        getMarker = getMarker,
        isValid = isMarkerValid,
        update = updateMarkers,
        getMarkers = getMarkers,
        isInitialized = isInitialized,
    },
    eventHandlers = {
        ["advWMap_tracking:addActiveObject"] = function(object)
            local handler, isNew = activeObjects.add(object, true)
            addMarkersForObject(handler)
        end,
        ["advWMap_tracking:removeActiveObject"] = function(objectData)
            activeObjects.removeActiveFlag(objectData[3], objectData[2])
            activeMarkers.updateObjMarker(objectData[4], objectData[2])
        end,

        ["advWMap_tracking:tempObjectRequest"] = function (object)
            local handler, isNew = activeObjects.add(object)
            if isNew then
                addMarkersForObject(handler)
            end
        end
    },
    engineHandlers = {
        onSave = function()
            local data = {}

            uniqueId.save(data)
            mapData.save(data)

            return data
        end,
        onLoad = function (data)
            uniqueId.load(data)
            mapData.load(data)
        end,
    },
}