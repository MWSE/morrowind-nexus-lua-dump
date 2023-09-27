local core = require('openmw.core')
if not core.contentFiles.has(require("scripts.an_unexpected_start.modData").addonFileName) then
    return
end

local async = require('openmw.async')
local types = require('openmw.types')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')

local function randomPointInRadius(vector, radius)
    local angle = math.random() * math.pi / 2
    local newX = vector.x + radius * math.cos(angle)
    local newY = vector.y + radius * math.sin(angle)
    local new = util.vector3(newX, newY, vector.z)
    return new
end

local function getRotation(vector1, vector2)
    if not vector1 or not vector2 then return end
    local angle = math.atan2(vector2.x - vector1.x, vector2.y - vector1.y)
    return util.transform.rotateZ(angle)
end

local function usbd_teleportToAndRotate(data)
    local ref = data.reference
    if not ref then return end
    local point = randomPointInRadius(self.position, 50)
    local rotSelfToRot = getRotation(point, self.position)
    local rotToSelfRot = getRotation(self.position, point)
    core.sendGlobalEvent("usbd_teleport", {
        {reference = self, position = point, rotation = rotSelfToRot,
            cell = {isExterior = self.cell.isExterior, gridX = self.cell.gridX, gridY = self.cell.gridY, name = self.cell.name}},
        {reference = ref, position = self.position, rotation = rotToSelfRot,
            cell = {isExterior = self.cell.isExterior, gridX = self.cell.gridX, gridY = self.cell.gridY, name = self.cell.name}},
    })
end

return {
    engineHandlers = {
    },
    eventHandlers = {
        usbd_teleportToAndRotate = async:callback(usbd_teleportToAndRotate),
    },
}