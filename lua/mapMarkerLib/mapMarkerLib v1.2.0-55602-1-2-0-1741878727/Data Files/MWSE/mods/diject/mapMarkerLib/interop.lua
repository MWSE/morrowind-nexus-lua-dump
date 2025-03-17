include("diject.mapMarkerLib.entry")
local markers = include("diject.mapMarkerLib.marker")

local this = {}

this.version = 3 -- API version. *nil* for the first version

this.event = {
    initialized = "mapMarkerLib:initialized",
    markerRemoved = "mapMarkerLib:markerDataRemoved",
    recordRemoved = "mapMarkerLib:recordDataRemoved"
}

---@class markerLib.event.markerDataRemoved.params
---@field id string
---@field cellId string?
---@field data markerLib.markerData

---@class markerLib.event.recordDataRemoved.params
---@field id string
---@field data markerLib.markerRecord

---@class eventlib
---@field register fun(eventId: '"mapMarkerLib:initialized"', callback: (fun(): boolean?), options: nil)
---@field register fun(eventId: '"mapMarkerLib:markerDataRemoved"', callback: (fun(e: markerLib.event.markerDataRemoved.params): boolean?), options: {filter : string}?)
---@field register fun(eventId: '"mapMarkerLib:recordDataRemoved"', callback: (fun(e: markerLib.event.recordDataRemoved.params): boolean?), options: {filter : string}?)

---@param params markerLib.addLocalMarker.params
---@return string|nil, string|nil ret returns record id and cell id if added. Or nil if not
function this.addLocalMarker(params)
    local ret = markers.addLocal(params)
    return ret
end

---@param id string marker id
---@param cellId string id of cell where marker was placed
---@return boolean ret returns true if the marker is found and removed. Or false if not found
function this.removeLocalMarker(id, cellId)
    local ret = markers.removeLocal(id, cellId)
    return ret
end

---@param params markerLib.addWorldMarker.params
---@return string|nil ret returns marker id if added. Or nil if not
function this.addWorldMarker(params)
    return markers.addWorld(params)
end

---@param id string marker id
---@return boolean ret returns true if the marker is found and removed. Or false if not found
function this.removeWorldMarker(id)
    return markers.removeWorld(id)
end

---@param params markerLib.markerRecord
---@return string|nil ret returns record id if added. Or nil if not
function this.addRecord(params)
    return markers.addRecord(nil, params)
end

---@param id string record id
---@param params markerLib.markerRecord
---@return string|nil ret returns record id if found and updated. Or nil if not
function this.updateRecord(id, params)
    return markers.addRecord(id, params)
end

--- creates a new record with data from an existing
---@param id string|nil
---@return string|nil id, markerLib.markerRecord? data returns new record id and record data if successfuly duplicated. Or nil if not
function this.duplicateRecord(id)
    return markers.duplicateRecord(id)
end

---Returns record data. You can change the data on the fly.
---@param id string
---@return markerLib.markerRecord|nil
function this.getRecord(id)
    return markers.getRecord(id)
end

---@param id string record id
---@return boolean ret returns true if the record found and removed. Or false if unfound
function this.removeRecord(id)
    return markers.removeRecord(id)
end

---@param updateImages boolean|nil if true, images on markers will be forced to update
function this.updateWorldMarkers(updateImages)
    markers.createWorldMarkers()
    markers.updateWorldMarkers(updateImages)
end

---@param updateImages boolean|nil if true, images on markers will be forced to update 
function this.updateLocalMarkers(updateImages)
    markers.createLocalMarkers()
    markers.updateLocalMarkers(updateImages)
end

---Updates all markers
---@param force boolean|nil if true, all markers will be forced to update, even if they should not be
function this.updateMarkers(force)
    this.updateLocalMarkers(force)
    this.updateWorldMarkers(force)
end

function this.updateMapMenu()
    markers.updateMapMenu()
end

---Returns data about world bounds and pixel cell size
---@return markerLib.worldBounds
function this.getWorldBounds()
    return table.copy(markers.worldBounds)
end

---Returns true if the lib is ready to work
---@return boolean
function this.isReady()
    return markers.isReady()
end

-- OOP style

this.record = {}

---@class markerLib.recordOOP
local recordOOP = {}
recordOOP.__index = recordOOP

---@param params markerLib.markerRecord
---@return markerLib.recordOOP?
function this.record.new(params)
    local recordId = markers.addRecord(nil, params)
    if recordId then
        ---@class markerLib.recordOOP
        local self = setmetatable({}, recordOOP)
        self.id = recordId

        return self
    end
end

---@param id string record id
---@return markerLib.recordOOP?
function this.record.get(id)
    if markers.getRecord(id) then
        ---@class markerLib.recordOOP
        local self = setmetatable({}, recordOOP)
        self.id = id
        return self
    end
    return nil
end

---Hides or shows all markers with this record. Requires updateMarkers(true) to apply changes
---@param value boolean? default: *true*. true - hide all markers with this record. false - show all markers with this record
---@return boolean? ret returns true if the record found and removed. Or false if it was removed early
function recordOOP:hide(value)
    if value == nil then value = true end
    markers.getRecord(self.id).hide = value
end

---Registers a callback function that will be called when a marker with the record is clicked. Returning false will prevent any lower priority callbacks on the same marker from being called
---@param func fun(e: markerLib.markerRecord.onClickCallbackData):boolean?
function recordOOP:registerOnClick(func)
    markers.getRecord(self.id).onClickCallback = func
end

---@return boolean? ret returns true if the record found and removed. Or false if it was removed early
function recordOOP:remove()
    return markers.removeRecord(self.id)
end

---@param params markerLib.markerRecord
---@return boolean? ret returns record id if found and updated. Or nil if not
function recordOOP:update(params)
    return markers.addRecord(self.id, params)
end

---Returns record data. You can change the data on the fly. Dangerous method!!!
---@return markerLib.markerRecord?
function recordOOP:getData()
    return markers.getRecord(self.id)
end

---@return boolean
function recordOOP:isExists()
    return markers.getRecord(self.id) and true or false
end

--- creates a new record with data from an existing
---@return markerLib.recordOOP|nil ret returns new record if successfuly duplicated. Or nil if not
function recordOOP:duplicate()
    local newId = markers.duplicateRecord(self.id)
    if not newId then return end

    local newSelf = setmetatable({}, recordOOP)
    newSelf.id = newId

    return newSelf
end

--- returns record id
---@return string recordId
function recordOOP:getId()
    return self.id
end



this.localMarker = {}

---@class markerLib.localMarkerOOP
local localMarkerOOP = {}
localMarkerOOP.__index = localMarkerOOP

---@param params markerLib.addLocalMarker.params
---@return markerLib.localMarkerOOP?
function this.localMarker.new(params)
    local markerId, markerCellId = markers.addLocal(params)
    if markerId then
        ---@class markerLib.localMarkerOOP
        local self = setmetatable({}, localMarkerOOP)
        self.id = markerId
        self.cellId = markerCellId

        return self
    end
end

---@param id string
---@param cellId string
---@return markerLib.localMarkerOOP?
function this.localMarker.get(id, cellId)
    if markers.getLocal(id, cellId) then
        local self = setmetatable({}, localMarkerOOP)
        self.id = id
        self.cellId = cellId
        return self
    end
    return nil
end

---@return boolean? ret returns true if the marker has been removed
function localMarkerOOP:remove()
    return markers.removeLocal(self.id, self.cellId)
end

---@return boolean
function localMarkerOOP:isExists()
    return markers.getLocal(self.id, self.cellId) and true or false
end

---@return string id
---@return string cellId
function localMarkerOOP:getId()
    return self.id, self.cellId
end


this.worldMarker = {}

---@class markerLib.worldMarkerOOP
local worldMarkerOOP = {}
worldMarkerOOP.__index = worldMarkerOOP

---@param params markerLib.addWorldMarker.params
---@return markerLib.worldMarkerOOP?
function this.worldMarker.new(params)
    local markerId = markers.addWorld(params)
    if markerId then
        ---@class markerLib.worldMarkerOOP
        local self = setmetatable({}, worldMarkerOOP)
        self.id = markerId

        return self
    end
end

---@param id string
---@return markerLib.worldMarkerOOP?
function this.worldMarker.get(id)
    if markers.getWorld(id) then
        local self = setmetatable({}, worldMarkerOOP)
        self.id = id
        return self
    end
    return nil
end

---@return boolean? ret returns true if the marker is found and removed. Or false if not found
function worldMarkerOOP:remove()
    return markers.removeWorld(self.id)
end

---@return boolean
function worldMarkerOOP:isExists()
    return markers.getWorld(self.id) and true or false
end

---@return string
function worldMarkerOOP:getId()
    return self.id
end


return this