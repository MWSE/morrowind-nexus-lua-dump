local world = require('openmw.world')
local util = require('openmw.util')

---@class fdr.doorDataStorage
local this = {}

---@class vector3
---@field x number
---@field y number
---@field z number

---@class cellData
---@field name string
---@field gridX integer
---@field gridY integer

---@class fdr.doorStorageObject
---@field pos vector3
---@field rotAngle number
---@field cell cellData
---@field timestamp integer

---@type table<string, fdr.doorStorageObject>
this.data = {}

function this.getRawData(doorId)
    return this.data[doorId]
end

---@return fdr.doorStorageObject|nil
function this.getData(doorId)
    local data = this.data[doorId]
    if data then
        local cell = data.cell.name == "" and world.getExteriorCell(data.cell.gridX, data.cell.gridY) or world.getCellByName(data.cell.name)
        local pos = util.vector3(data.pos.x, data.pos.y, data.pos.z)
        local rot = util.transform.rotateZ(data.rotAngle)
        local timestamp = data.timestamp
        return {cell = cell, pos = pos, rotAngle = rot, timestamp = timestamp}
    end
    return nil
end

---@param doorId string
---@param pos vector3
---@param rotAngle number
---@param cell cellData
---@param timestamp integer
function this.setRawData(doorId, pos, rotAngle, cell, timestamp)
    ---@type fdr.doorStorageObject
    local data = {cell = cell, pos = pos, rotAngle = rotAngle, timestamp = timestamp}
    this.data[doorId] = data
end

function this.setData(doorId, pos, rot, cell)
    ---@type fdr.doorStorageObject
    local data = {cell = {name = cell.name, gridX = cell.gridX, gridY = cell.gridY}, pos = {x = pos.x, y = pos.y, z = pos.z},
        rotAngle = rot:getYaw(), timestamp = world.getGameTime()}
    this.data[doorId] = data
end

function this.clearData(doorId)
    this.data[doorId] = nil
end

return this