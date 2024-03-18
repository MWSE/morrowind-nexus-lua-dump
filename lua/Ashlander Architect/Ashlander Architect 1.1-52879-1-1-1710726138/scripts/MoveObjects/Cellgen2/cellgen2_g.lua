local structureData = require("scripts.MoveObjects.StructureData")
local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local async = require("openmw.async")

local cellGenStorage = storage.globalSection("AACellGen2")
local cellGenData = {}

local function processNewStructure(objectList, templateName, markerList)
    --Process the list of exterior objects, copy the interior cell.
    --Find the doors, link them.

    async:newUnsavableSimulationTimer(0.1, function()
        I.AA_CellGen_2_CellCopy.copyCell(templateName, objectList,markerList)
    end

    )
end
local function saveCellGenData(cdata)
    if not cellGenData then
        cellGenData = {}
    end
    table.insert(cellGenData, cdata)
    cellGenStorage:set("CellGenData", cellGenData)
end
local function getCellGenData()
    return cellGenData
end
local function getSurroundCellObjects(cell)
    if not cell then cell = world.players[1].cell end
    if not cell.isExterior then return cell:getAll() end
    local north = world.getExteriorCell(cell.gridX, cell.gridY + 1)
    local south = world.getExteriorCell(cell.gridX, cell.gridY - 1)
    local west = world.getExteriorCell(cell.gridX + 1, cell.gridY)
    local east = world.getExteriorCell(cell.gridX - 1, cell.gridY)
    local cellList = { north, south, west, east, cell }
    local objectList = {}
    for index, value in ipairs(cellList) do
        for index, obj in ipairs(value:getAll()) do
            table.insert(objectList, obj)
        end
    end
    return objectList
end

local function findDoorPair(door)
    --TODO: Check for rotation
    if door.type ~= types.Door then return end
    if not types.Door.isTeleport(door) then return end
    local doorDestCell = types.Door.destCell(door)
    local doorDestPos = types.Door.destPosition(door)
    for index, value in ipairs(getSurroundCellObjects(doorDestCell)) do
        if value.type == types.Door and value.enabled == true then
            if types.Door.isTeleport(value) and types.Door.destCell(value).worldSpaceId == door.cell.worldSpaceId then
                local destCheck = I.ZackUtilsAA.distanceBetweenPos(value.position, doorDestPos)
                if destCheck < 200 then
                    return { value, door }
                end
            end
        end
    end
    for index, value in ipairs(getSurroundCellObjects(doorDestCell)) do
        if value.type == types.Door and value.enabled == true then
            if types.Door.isTeleport(value) and types.Door.destCell(value).worldSpaceId == door.cell.worldSpaceId then
                local destCheck = I.ZackUtilsAA.distanceBetweenPos(value.position, doorDestPos)
                if destCheck < 400 then
                    return { value, door }
                end
            end
        end
    end
    for index, value in ipairs(getSurroundCellObjects(doorDestCell)) do
        if value.type == types.Door and value.enabled == true then
            if types.Door.isTeleport(value) and types.Door.destCell(value).worldSpaceId == door.cell.worldSpaceId then
                local destCheck = I.ZackUtilsAA.distanceBetweenPos(value.position, doorDestPos)
                if destCheck < 600 then
                    return { value, door }
                end
            end
        end
    end
    for index, value in ipairs(getSurroundCellObjects(doorDestCell)) do
        if value.type == types.Door and value.enabled == true then
            if types.Door.isTeleport(value) and types.Door.destCell(value).worldSpaceId == door.cell.worldSpaceId then
                local destCheck = I.ZackUtilsAA.distanceBetweenPos(value.position, doorDestPos)
                if destCheck < 1600 then
                    return { value, door }
                end
                print(destCheck)
            end
        end
    end
    error("Unable to find door!")
end
return {
    interfaceName = "AA_CellGen_2",
    interface = {
        version                = 1,
        findDoorPair           = findDoorPair,
        processNewStructure    = processNewStructure,
        saveCellGenData        = saveCellGenData,
        getCellGenData         = getCellGenData,
        getSurroundCellObjects = getSurroundCellObjects,
    },
    eventHandlers = {
    },
    engineHandlers = {
        onSave = function() return { cellGenData = cellGenData } end,
        onLoad = function(data)
            if not data then
                cellGenStorage:set("CellGenData", cellGenData)
                return
            end
            cellGenData = data.cellGenData
            cellGenStorage:set("CellGenData", cellGenData)
        end
    }
}
