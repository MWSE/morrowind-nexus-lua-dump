local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local interfaces = require("openmw.interfaces")
local vfs = require("openmw.vfs")
local objectList = {}
local idList = {}
local function addObject(obj)
    if not objectList then
        objectList = {}
    end
    if not idList then
        idList = {}
    end
    table.insert(objectList, obj)
    table.insert(idList, obj.id)
    obj.enabled = false
end
local function getIDs(structureID)
    local lsString = ""
    local retstring = ""
    local interioresStr = "interiors ={ "
    local addedInteriors = {}
    local destInteriors = {}
    local gridX, gridY
    local exteriorCells = {}
    local startingCell = objectList[1].cell
    local zOffset = world.players[1].position.z - objectList[1].position.z
    for index, value in ipairs(objectList) do
        value.enabled = true
    end
    async:newUnsavableSimulationTimer(0.1, function()
    for index, value in ipairs(objectList) do
        if value.type == types.Door and types.Door.destCell(value) then
            local cell = types.Door.destCell(value)
            if not addedInteriors[cell.name] then
                table.insert(destInteriors, cell.name)
                addedInteriors[cell.name] = true
            end
        end
        local found = false
        for index, cell in ipairs(exteriorCells) do
            if cell.gridX == value.cell.gridX and cell.gridY == value.cell.gridY then
                found = true
            end
        end
        if not found then
            table.insert(exteriorCells, value.cell)
        end
        gridX = value.cell.gridX
        gridY = value.cell.gridY
    end
        -- lsString = lsString .. "'" .. value.id .. "',"

    for index, value in pairs(addedInteriors) do
        local cell = world.getCellByName(index)
        for index, value in ipairs(cell:getAll(types.Door)) do
            if value.type == types.Door and types.Door.destCell(value) and types.Door.destCell(value).worldSpaceId ~= cell.worldSpaceId and types.Door.destCell(value).worldSpaceId ~= startingCell.worldSpaceId then
                local destCell = types.Door.destCell(value)
                if not addedInteriors[destCell.name] then
                    table.insert(destInteriors, destCell.name)
                    addedInteriors[destCell.name] = true
                end
            end
        end
    end
    lsString = lsString .. I.CellSave.serializeObjectLs(objectList)
    for index, value in ipairs(destInteriors) do
        interioresStr = interioresStr .. "\"" .. value .. "\","
    end
    interioresStr = interioresStr .. "},"
    retstring = retstring .. ("[\"" .. structureID .. "\"] = {")
    retstring = retstring .. ("ids = " .. lsString .. ",")
    local cellStr = "extCells = { "
    for index, value in ipairs(exteriorCells) do
        cellStr = cellStr .. "{x = " .. tostring(value.gridX) .. ", y = " .. tostring(value.gridY) .. " },"
    end
    cellStr = cellStr .. "},"
    retstring = retstring .. (cellStr)
    retstring = retstring .. (interioresStr .. "}")
    local holdingList = idList
    idList = nil
    local createdCellData = ""
    local structureGenData = retstring
    objectList = nil
    I.ZackUtilsG.printToConsole("Offset: " .. tostring(-zOffset))
    I.ZackUtilsG.printToConsole("CELLS:")
    for index, value in ipairs(destInteriors) do

        local cell = world.getCellByName(value)
        local str = I.CellSave.serializeCell(cell)
        createdCellData = createdCellData .. str
    end
    vfs.writeToFile("/Users/tobias/Games/OpenMW/Projects/ashlander-architect/scripts/MoveObjects/data/cellcache/" .. structureID .. ".lua","return  " ..createdCellData .. "")
    vfs.writeToFile("/Users/tobias/Games/OpenMW/Projects/ashlander-architect/scripts/MoveObjects/data/structuregen/" .. structureID .. ".lua","return  {" ..structureGenData .. "}")
   
end) --world.players[1]:sendEvent("ZHAC_createWindow",{createdCellData = createdCellData, structureGenData = structureGenData, id = structureID, offset =  tostring(zOffset)})
   -- return holdingList
end
return {
    interfaceName = "StructureGen",
    interface = {
        getIDs = getIDs,
        addObject = addObject
    },
    eventHandlers = {
        -- createItemReturn_AA = createItemReturn,
        printToConsoleEvent_AA = printToConsoleEvent,
        addItemEquipReturn_AA = addItemEquipReturn,
    },
}
