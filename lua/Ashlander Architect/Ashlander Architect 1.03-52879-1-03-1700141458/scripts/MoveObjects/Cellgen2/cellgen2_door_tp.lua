local structureData = require("scripts.MoveObjects.StructureData")
local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local doorData = {}
local cellGenStorage = storage.globalSection("AACellGen2")

local function registerDoorPair(door1Data, door2Data)
    doorData[door1Data.sourceObj] = door1Data
    doorData[door2Data.sourceObj] = door2Data
    cellGenStorage:set("doorData", doorData)
end
local function registerDoor(door1Data)
    doorData[door1Data.sourceObj] = door1Data
    cellGenStorage:set("doorData", doorData)

end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        return rotate
    end
end
local directionOverride = {
    ["meshes\\x\\ex_ashl_door_01.nif" ] = {
        dir = "north",
        distance = 400
    },
    ["meshes\\x\\ex_ashl_door_02.nif"]= {
        dir = "north",
        distance = 400
    },
    ["meshes\\d\\ex_velothi_loaddoor_01.nif"] = {
        dir = "west",
        rotOffset = 90
    },
    ["meshes\\d\\ex_redoran_barracks_01_a.nif"] = {
        dir = "west",
        rotOffset = 90

    },
    ["meshes\\d\\ex_s_door_double.nif"] = {
        dir = "south",
        rotOffset = 180
    },["meshes\\d\\ex_s_door_rounded.nif"] = {

        dir = "south",
        rotOffset = 180
    }
}
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
local function doorCheck(object, actor)
    if not actor then actor = world.players[1] end
    --return false
    if doorData[object.id] then
        local zPos = doorData[object.id].targetPosition.z
        local destCell = world.getCellByName(doorData[object.id].targetCell)
        if destCell and destCell.isExterior then
            zPos = zPos + 100
        end
        local pos = util.vector3(doorData[object.id].targetPosition.x, doorData[object.id].targetPosition.y,
           zPos) 
        actor:teleport(doorData[object.id].targetCell, pos,
            {
                rotation = createRotation(0, 0, doorData[object.id].targetRotation),
                onGround = true
            })
        return false
    end
end
I.Activation.addHandlerForType(types.Door, doorCheck)
local function getDirectionOverride()
return directionOverride
end

local function updateDoorPos(door, newPos, newRotZ)
    for index, data in pairs(doorData) do
        local targObj = data.targObj
        if targObj == door.id then
            local direction = "north"
            local dist = 150
            local rotOffset = 0
            local override = I.AA_CellGen_2_CellCopy_DoorTP.getDirectionOverride()[door.type.record(door).model:lower()]
            if override then
                if override.rotOffset then
                    rotOffset = override.rotOffset
                end
                if override.dir then
                    direction = override.dir
                end
                if override.distance then
                    dist = override.distance
                end
            end
            local Pos = getPositionBehind(newPos, newRotZ, dist,direction)
            local Rot = newRotZ + math.rad(180) + math.rad(rotOffset)
            doorData[index].targetPosition = Pos
            doorData[index].targetRotation = Rot
        end
    end
end
return {
    interfaceName = "AA_CellGen_2_CellCopy_DoorTP",
    interface = {
        version = 1,
        registerDoorPair = registerDoorPair,
        updateDoorPos = updateDoorPos,
        getDirectionOverride = getDirectionOverride,
        registerDoor = registerDoor,
    },
    eventHandlers = {
        doorCheck = doorCheck,
    },
    engineHandlers = {
        onSave = function() return { doorData = doorData } end,
        onLoad = function(data)
            if not data then
                cellGenStorage:set("doorData", doorData)
                return
            end
            doorData = data.doorData
            cellGenStorage:set("doorData", doorData)
        end
    }
}
