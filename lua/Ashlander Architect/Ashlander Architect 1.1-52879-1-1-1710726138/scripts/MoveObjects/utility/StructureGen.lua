local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local interfaces = require("openmw.interfaces")
local vfs = require("openmw.vfs")
local celldata = storage.globalSection("cellData")

local config = require("scripts.MoveObjects.config")
local objectList = {}
local idList = {}
local lastAddedObj
local savedcreatedCellData
local savedstructureGenData
local savedstructureID

local savedCellTable = {}
local function addObject(obj)
    if not objectList then
        objectList = {}
    end
    if not idList then
        idList = {}
    end
    lastAddedObj = obj
    table.insert(objectList, obj)
    table.insert(idList, obj.id)
    obj.enabled = false
end
local function getIDs(data)
    local structureID = data.id
    local name = data.name
    local lsString = ""
    local retstring = ""
    savedCellTable = {}
    local interioresStr = "interiors ={ "
    local addedInteriors = {}
    local destInteriors = {}
    local gridX, gridY
    local exteriorCells = {}
    local startingCell = objectList[1].cell
    local zOffset = world.players[1].position.z - objectList[1].position.z
    zOffset = -zOffset
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
        for index, value in ipairs(destInteriors) do
            local cell            = world.getCellByName(value)
            local str, xtable     = I.CellSave.serializeCell(cell)
            savedCellTable[value] = xtable
            createdCellData       = createdCellData .. str
        end
        createdCellData = "return  " .. createdCellData .. ""
        structureGenData = "return  {" .. structureGenData .. "}"
        savedcreatedCellData = createdCellData
        savedstructureGenData = structureGenData
        savedstructureID = structureID
        world.players[1]:sendEvent("ZHAC_createWindow_Info",
            {
                createdCellData = createdCellData,
                structureGenData = structureGenData,
                id = structureID,
                name = name,
                offset = tostring(
                    zOffset)
            })
    end)
    -- return holdingList
end
local function saveObjectGen(data)
    local csvline = data.csvline
    print("Creating " .. data.id)
    if csvline then
        local csvdata = celldata:getCopy("csvTable") or {}
        csvdata[data.id] = csvline
       print(csvline)
        celldata:set("csvTable", csvdata)
    end
end
local function saveDataGen(data)
    if vfs.writeToFile then
        vfs.writeToFile(
            "/Users/tobias/Games/OpenMW/Projects/ashlander-architect/scripts/MoveObjects/data/cellcache/" ..
            savedstructureID .. ".lua", savedcreatedCellData)
        vfs.writeToFile(
            "/Users/tobias/Games/OpenMW/Projects/ashlander-architect/scripts/MoveObjects/data/structuregen/" ..
            savedstructureID .. ".lua", savedstructureGenData)
    end
    local cdata = celldata:getCopy("cellTable") or {}
    for index, value in pairs(savedCellTable) do
        for xindex, xvalue in pairs(value) do
        cdata[xindex] = xvalue
        print(xindex)
        end
    end
    celldata:set("cellTable", cdata)

    local csvline = data.csvline
    if csvline then
        local csvdata = celldata:getCopy("csvTable") or {}
       csvdata[savedstructureID] = csvline
       print(csvline)
        celldata:set("csvTable", csvdata)
    end
    local sdata = celldata:getCopy("structureTable") or {}
    local structureTable = util.loadCode(savedstructureGenData, {})()
    print(structureTable)
    for index, value in pairs(structureTable) do

        sdata[index] = value
    end
    celldata:set("structureTable", sdata)
end
local function resetState()
    for index, value in ipairs(objectList) do
        value.enabled = true
    end
end
local function removeLastAddedObject()
    local prevObject
    for index, value in ipairs(objectList) do
        if value == lastAddedObj then
            value.enabled = true
            table.remove(objectList, index)
            lastAddedObj = prevObject
            return
        end
        prevObject = value
    end
end
local function TPPlayerToPos(position)
    local player = world.players[1]
    player:teleport(player.cell, position)
end
local function onSave()
    if not objectList then return end
    for index, value in ipairs(objectList) do
        value.enabled = true
    end
end
return {
    interfaceName = "StructureGen",
    interface = {
        getIDs = getIDs,
        addObject = addObject
    },
    eventHandlers = {
        -- createItemReturn_AA = createItemReturn,
        removeLastAddedObject = removeLastAddedObject,
        getIDs = getIDs,
        addObject_AA = addObject,
        resetState_AA = resetState,
        TPPlayerToPos = TPPlayerToPos,
        saveDataGen = saveDataGen,
        saveObjectGen = saveObjectGen,
    },
    engineHandlers = {
        onSave = onSave
    }
}
