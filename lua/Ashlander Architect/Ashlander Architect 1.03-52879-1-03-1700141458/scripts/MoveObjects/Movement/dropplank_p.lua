local interfaces = require("openmw.interfaces")

local nearby = require("openmw.nearby")
local util = require("openmw.util")
local core = require("openmw.core")

local function getPositionBehind(pos, rot, distance, direction)
    local currentRotation = -rot
    local angleOffset = 0

    if direction == "north" then
        angleOffset = math.rad(90)
    elseif direction == "south" then
        angleOffset = math.rad(-90)
    elseif direction == "east" then
        angleOffset = 0
    elseif direction == "west" then
        angleOffset = math.rad(180)
    else
        error("Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
    end

    currentRotation = currentRotation - angleOffset
    local obj_x_offset = distance * math.cos(currentRotation)
    local obj_y_offset = distance * math.sin(currentRotation)
    local obj_x_position = pos.x + obj_x_offset
    local obj_y_position = pos.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, pos.z)
end
local function dropPlank(plank)
    local plankHalfLength = plank:getBoundingBox().halfSize.x
    local plankEnd1 = getPositionBehind(plank.position, plank.rotation:getAnglesZYX(), plankHalfLength, "east")
    local plankEnd2 = getPositionBehind(plank.position, plank.rotation:getAnglesZYX(), plankHalfLength, "west")

    local rayCastPos1 = nearby.castRay(plankEnd1, util.vector3(plankEnd1.x,plankEnd1.y,plankEnd1.z - 10000),{ignore = plank}).hitPos
    local rayCastPos2 = nearby.castRay(plankEnd2, util.vector3(plankEnd2.x,plankEnd2.y,plankEnd2.z - 10000),{ignore = plank}).hitPos
    core.sendGlobalEvent("dropPlank",{plankOb = plank,dockPos = rayCastPos1, shipPos = rayCastPos2})
end
return {
    interfaceName = "AA_DropPlank",
    interface = {
        version = 1,
        dropPlank = dropPlank,
    },
    eventHandlers = {
    },
    engineHandlers = {}
}
