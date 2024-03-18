local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")


local config = require("scripts.MoveObjects.config")
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        local rotatey = util.transform.rotateY(y)
        rotate = rotate:__mul(rotatey)
        return rotate
    end
end
local function calculateYRotationAngle(dockPos, shipPos, plankPos)
    local directionVector =util.vector3(shipPos.x - dockPos.x, 0, shipPos.z - dockPos.z)
    
    -- Calculate the Y rotation angle for the plank in the XZ plane
    local angleRadians = math.atan2(directionVector.z, directionVector.x)
    local plankYRotation = math.deg(angleRadians)

    -- Ensure the angle is between 0 and 360 degrees
    plankYRotation = (plankYRotation + 360) % 360

    return angleRadians
end
local function dropPlank(data)
    -- Example usage
    local dockPos = data.dockPos
    local shipPos = data.shipPos
    print(dockPos)
    print(shipPos)
    local plankOb = data.plankOb
    local dockToShip = shipPos - dockPos
    local zOffset = dockToShip.z / 2
    local plankZ = shipPos.z - zOffset
    local newPlankPos = util.vector3(plankOb.position.x, plankOb.position.y, plankZ)
    local z, y, x = plankOb.rotation:getAnglesZYX()
    local angle = calculateYRotationAngle(dockPos, shipPos, newPlankPos)
   -- angle = math.abs(angle)
    plankOb:teleport(plankOb.cell, newPlankPos, createRotation(0, angle, z))
end
return {
    interfaceName = "AA_DropPlank",
    interface = {
        version = 1,
    },
    eventHandlers = {
        dropPlank = dropPlank,
    },
    engineHandlers = { onSave = onSave, onUpdate = onUpdate }
}
