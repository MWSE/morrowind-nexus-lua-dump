local core = require("openmw.core")


local tableLib = require("scripts.advanced_world_map_tracking.utils.table")
local inventoryLib = require("scripts.advanced_world_map_tracking.utils.inventory")
local objectHandler = require("scripts.advanced_world_map_tracking.handlers.object")



local this = {}

---@type table<string, advWMap_tracking.activeRecordObjectsHandler> by record id
this.data = {}


---@class advWMap_tracking.activeRecordObjectsHandler
local objectGroupHandler = {}
objectGroupHandler.__index = objectGroupHandler
---@type table<string, advWMap_tracking.objectHandler>
objectGroupHandler.objects = {}



function objectGroupHandler:add(objHandler)
    if not self.objects[objHandler.id] then
        self.count = self.count + 1
    end
    self.objects[objHandler.id] = objHandler
end

function objectGroupHandler:get(refId)
    local ref = self.objects[refId]
    if not ref then return end

    if not ref:isValid() then
        self.objects[refId] = nil
        return
    end

    return ref
end

function objectGroupHandler:remove(refId)
    if self.objects[refId] then
        self.count = self.count - 1
    end
    self.objects[refId] = nil
end


---@param object GameObject
---@param isActive boolean?
---@return advWMap_tracking.objectHandler
---@return boolean
function this.add(object, isActive)
    local recordId = object.recordId

    local recordHandler = this.data[recordId]
    if not recordHandler then
        ---@class advWMap_tracking.activeRecordObjectsHandler
        recordHandler = setmetatable({}, objectGroupHandler)
        ---@type string
        recordHandler.id = recordId
        ---@type integer
        recordHandler.count = 0
        ---@type string
        recordHandler.recordId = recordId
        ---@type table<string, any> by object id
        recordHandler.objects = {}

        this.data[recordId] = recordHandler
    end

    local isNew = false
    local objHandler = recordHandler:get(object.id)
    if not objHandler then
        objHandler = objectHandler.new{object = object}
        isNew = true

        local tp = tostring(object.type)
        local cellId = object.cell.id

        ---@class advWMap_tracking.activeRecordObjectsHandler
        local typeHandler = this.data[tp]
        if not typeHandler then
            typeHandler = setmetatable({}, objectGroupHandler)
            typeHandler.id = tp
            typeHandler.count = 0
            typeHandler.type = tp
            typeHandler.objects = {}

            this.data[tp] = typeHandler
        end

        ---@class advWMap_tracking.activeRecordObjectsHandler
        local cellHandler = this.data[cellId]
        if not cellHandler then
            cellHandler = setmetatable({}, objectGroupHandler)
            cellHandler.id = cellId
            cellHandler.count = 0
            cellHandler.cellId = cellId
            cellHandler.objects = {}

            this.data[cellId] = cellHandler
        end

        recordHandler:add(objHandler)
        typeHandler:add(objHandler)
        cellHandler:add(objHandler)
    end

    if isActive then
        objHandler.active = true
        objHandler.object = object
    end

    return objHandler, isNew
end


local function removeFromData(handler, refId)
    handler:remove(refId)
    if handler.count == 0 then
        this.data[handler.id] = nil
    end
end


function this.remove(refId, recordId, cellId, typeId)
    if recordId then
        local objHandler = this.data[recordId]
        if objHandler then
            removeFromData(objHandler, refId)
        end
    end

    if typeId then
        local objHandler = this.data[typeId]
        if objHandler then
            removeFromData(objHandler, refId)
        end
    end

    if cellId then
        local objHandler = this.data[cellId]
        if objHandler then
            removeFromData(objHandler, refId)
        end
    end
end


function this.removeActiveFlag(recordId, refId)
    local handler = this.data[recordId]
    if not handler then return end
    local objHandler = handler:get(refId)
    if not objHandler then return end

    objHandler.active = false
end


---@params recordId string
---@return advWMap_tracking.objectHandler[]?
function this.getValidObjectHandlers(recordId)
    local data = this.data[recordId]
    if not data then return end

    local out = {}
    for _, obj in pairs(data.objects) do
        if obj:isValid() then
            table.insert(out, obj)
        end
    end

    return out
end


---@param groupId string
function this.getHandler(groupId)
    return this.data[groupId]
end


---@param groupId string
---@return fun(): (string, advWMap_tracking.objectHandler)
function this.getObjectIterator(groupId)
    local data = this.data[groupId]
    if not data then return function() end end ---@diagnostic disable-line: missing-return

    local function iterator(tbl, key)
        local nextKey, obj = next(tbl, key)
        while nextKey do
            if obj:isValid() and obj.cell then
                return nextKey, obj
            end
            nextKey, obj = next(tbl, nextKey)
        end
        return nil
    end

    return iterator, data.objects, nil ---@diagnostic disable-line: redundant-return-value
end


---@param cellId string
---@return fun(): (string, advWMap_tracking.objectHandler)
function this.getObjectByCellIdIterator(cellId)
    local data = this.data[cellId]
    if not data then
        core.sendGlobalEvent("advWMap_tracking:requestObjects", {cellId = cellId})
        return function() end ---@diagnostic disable-line: missing-return
    end

    local function iterator(tbl, key)
        local nextKey, obj = next(tbl, key)
        while nextKey do
            if obj:isValid() then
                return nextKey, obj
            end
            nextKey, obj = next(tbl, nextKey)
        end
        return nil
    end

    return iterator, data.objects, nil ---@diagnostic disable-line: redundant-return-value
end


function this.requestCellObjects(cellId)
    local data = this.data[cellId]
    if not data then
        core.sendGlobalEvent("advWMap_tracking:requestObjects", {cellId = cellId})
    end
end


function this.clearInactive()
    for recordId, handler in pairs(this.data) do
        for objId, objHandler in pairs(handler.objects) do
            if not objHandler:isActive() then
                handler:remove(objId)
            end
        end
        if handler.count == 0 then
            this.data[recordId] = nil
        end
    end
end


return this