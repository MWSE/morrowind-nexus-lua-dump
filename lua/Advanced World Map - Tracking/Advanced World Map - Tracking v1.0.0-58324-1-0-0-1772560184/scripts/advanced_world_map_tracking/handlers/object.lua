local Actor = require("openmw.types").Actor
local inventoryLib = require("scripts.advanced_world_map_tracking.utils.inventory")


local this = {}

---@class advWMap_tracking.objectHandler
---@field cell Cell
---@field position Vector3


---@class advWMap_tracking.objectHandler
local objectHandler = {}

objectHandler.__type = "objHandler"

local objectHandlerProps = {}

objectHandlerProps.cell = function (table)
    return table.object.cell
end

objectHandlerProps.position = function (table)
    return table.object.position
end


objectHandler.__index = function (table, key)
    local val = objectHandler[key]
    if val then return val end
    local property = objectHandlerProps[key]
    return property and property(table) or nil
end
objectHandler.invalid = false

function objectHandler:getPos()
    return self.object.position
end

function objectHandler:hasItem(itemId, countUnresolved)
    return inventoryLib.countOf(self.object, itemId, countUnresolved, 1) > 0
end

function objectHandler:isInMapCell(cellId)
    local cell = self.object.cell
    if not cell then return false end
    return not cellId and cell.isExterior or cellId == cell.id
end

function objectHandler:isAlive()
    return Actor.objectIsInstance(self.object) and not Actor.isDead(self.object)
end

function objectHandler:isActive()
    return self.active
end

function objectHandler:isEnabled()
    return self.object:isValid() and self.object.enabled and self.object.count > 0 and true
end

function objectHandler:isVisible()
    return self.object.scale > 0 and self.object.enabled and self.object.count > 0 and true
end

function objectHandler:isValid()
    return self.active or not self.invalid and self.object:isValid()
end


---@class advWMap_tracking.objectHandlerParams
---@field object GameObject

---@param params advWMap_tracking.objectHandlerParams
function this.new(params)
    ---@class advWMap_tracking.objectHandler
    local objHandler = setmetatable({}, objectHandler)
    objHandler.object = params.object
    objHandler.recordId = params.object.recordId
    objHandler.id = params.object.id
    objHandler.type = params.object.type
    objHandler.active = false

    return objHandler
end


return this