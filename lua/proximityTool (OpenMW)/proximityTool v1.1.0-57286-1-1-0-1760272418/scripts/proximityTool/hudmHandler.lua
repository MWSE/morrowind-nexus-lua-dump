local I = require('openmw.interfaces')
local Actor = require("openmw.types").Actor
local vfs = require('openmw.vfs')

local tableLib = require("scripts.proximityTool.utils.table")

local common = require("scripts.proximityTool.common")
local activeObjects = require("scripts.proximityTool.activeObjects")
local inventoryLib = require("scripts.proximityTool.utils.inventory")
local mapData = require("scripts.proximityTool.data.mapDataHandler")
local realTimer = require("scripts.proximityTool.realTimer")
local config = require("scripts.proximityTool.config")

local getHealth = Actor.stats.dynamic.health


local hudm

local this = {}

this.version = -1

this.initialized = false


---@type table<string, any[]> by mod name
this.activeData = {}

---@alias proximityTool.HUDMarker.activeObjectMarkerData {object : any, modName : string, marker : proximityTool.HUDMarker}

---@type table<string, table<string, proximityTool.HUDMarker.activeObjectMarkerData>> by ref.id; by marker id
this.activeByObject = {}


---@type table<string, table<string, proximityTool.HUDMarker.activeObjectMarkerData>> by objectId; by markerId
this.filteredObjects = {}


local function getHashVal(refId, markerId)
    return refId..markerId
end


---@param modName string
---@param objectData table[]
local function setMarkers(modName, objectData)
    hudm.setMarkers(modName, objectData)
end


---@param refId string
---@param markerId string
---@param data proximityTool.HUDMarker.activeObjectMarkerData
local function addItemFilteredObject(refId, markerId, data)
    if not this.filteredObjects[refId] then
        this.filteredObjects[refId] = {}
    end
    this.filteredObjects[refId][markerId] = data
end


---@param refId string
---@param markerId string
local function removeItemFilteredObject(refId, markerId)
    if not this.filteredObjects[refId] then return end
    this.filteredObjects[refId][markerId] = nil
end


local function filterTimer()
    for refId, dt in pairs(this.filteredObjects) do
        for markerId, data in pairs(dt) do
            if data.marker.itemId then
                local itemCount = inventoryLib.countOf(data.object, data.marker.itemId, true, 0)
                if itemCount <= 0 then
                    (this.activeData[data.modName or ""] or {})[getHashVal(refId, markerId)] = nil

                    this.activeByObject[refId][markerId] = nil
                    removeItemFilteredObject(refId, markerId)
                end
            elseif data.marker.hideDead and Actor.objectIsInstance(data.object) then
                local health = getHealth(data.object).current
                if health <= 0 then
                    (this.activeData[data.modName or ""] or {})[getHashVal(refId, markerId)] = nil

                    this.activeByObject[refId][markerId] = nil
                    removeItemFilteredObject(refId, markerId)
                end
            else
                removeItemFilteredObject(refId, markerId)
            end
        end
    end

    this.filterTimer = realTimer.newTimer(this.timerInterval, filterTimer)
end


---@return boolean
function this.init()
    if this.initialized then return true end
    if not I.HUDMarkers then return false end

    if this.filterTimer then
        this.filterTimer()
    end
    this.timerInterval = config.data.objectPosUpdateInterval + math.random() * 0.1
    this.filterTimer = realTimer.newTimer(this.timerInterval, filterTimer)

    hudm = I.HUDMarkers
    this.version = hudm.version
    this.initialized = true

    return true
end


function this.update()
    if not this.init() then return end

    for refId, dt in pairs(this.activeByObject) do
        for markerId, data in pairs(dt) do
            local activeData = this.activeData[data.modName]
            if not activeData then goto continue end

            if data.marker.invalid or not data.object:isValid() then
                activeData[getHashVal(refId, markerId)] = nil

                dt[markerId] = nil

            elseif data.marker.hidden then
                activeData[getHashVal(refId, markerId)] = nil

            elseif not data.marker.hidden and not activeData[getHashVal(refId, markerId)] then
                local params = tableLib.deepcopy(data.marker.params)
                params.object = data.object

                activeData[getHashVal(refId, markerId)] = params

            end

            ::continue::
        end
    end

end


---@param marker proximityTool.HUDMarker
---@param ref any
---@return boolean?
local function addMarkers(marker, ref)
    if (marker.version or 0) > this.version or marker.invalid
            or not marker.params.icon or not vfs.fileExists(marker.params.icon) then return end

    if this.activeByObject[ref.id] and this.activeByObject[ref.id][marker.id] then return end

    local modName = marker.modName
    local modData = this.activeData[modName]
    if not modData then
        modData = {}
        setMarkers(modName, modData)
    end

    if not marker.hidden then
        local params = tableLib.deepcopy(marker.params)
        params.object = ref

        -- table.insert(modData, params)
        modData[getHashVal(ref.id, marker.id)] = params

        this.activeData[modName] = modData
    end

    ---@type proximityTool.HUDMarker.activeObjectMarkerData
    local objectMarkerData = {object = ref, modName = modName, marker = marker}
    this.activeByObject[ref.id] = this.activeByObject[ref.id] or {}
    this.activeByObject[ref.id][marker.id] = objectMarkerData

    if marker.itemId or marker.hideDead then
        addItemFilteredObject(ref.id, marker.id, objectMarkerData)
    end

    return true
end


---@return boolean?
function this.addObject(ref)
    if not this.init() or not ref or not ref:isValid() then return end

    local res = false

    local markersByRecordId = mapData.getHUDMarkers(ref.recordId)
    if markersByRecordId then
        for id, marker in pairs(markersByRecordId) do
            res = addMarkers(marker, ref) or res
        end
    end

    local markersByObjectID = mapData.getHUDMarkers(ref.id)
    if markersByObjectID then
        for id, marker in pairs(markersByObjectID) do
            res = addMarkers(marker, ref) or res
        end
    end

    return res
end


function this.removeObject(refId)
    if not this.init() or not refId then return end

    local found = false
    for id, data in pairs(this.activeByObject[refId] or {}) do
        local hudmData = this.activeData[data.modName]

        if hudmData then
            hudmData[getHashVal(refId, id)] = nil
        end

        if data.marker.shortTerm then
            data.marker.invalid = true
            local markerMain = (mapData.getHUDMarkers(data.marker.id) or {})[data.marker.id]
            if markerMain then
                markerMain.invalid = true
            end
        end

        this.activeByObject[refId][id] = nil
        removeItemFilteredObject(refId, id)

        found = true
    end

    return found
end


return this