local core = require("openmw.core")
local util = require("openmw.util")
local world = require("openmw.world")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")
local myModData = storage.globalSection('MundisData')

local MUNDISStartData = require("scripts.mundis.mundis_startData")
local MUNDISLocData = nil
local buttonData = {}
-- Global variable to store the current ID counter
local idCounter = 0
local startCell = "Odrosal, Tower"
-- Function to generate a unique ID
local function generateUniqueID()
    idCounter = idCounter + 1
    return idCounter
end
local wasImported = false

local function getCellFromId(id)
    for index, dataItem in ipairs(MUNDISLocData) do
        if dataItem.id == id then
            return dataItem.cellData.cellName
        end
    end
end
local function getIDFromCell(cell)
    for index, dataItem in ipairs(MUNDISLocData) do
        if dataItem.cellData.cellName:lower() == cell:lower() then
            return dataItem.ID
        end
    end
end
local function trim(s)
    return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)'
end
local function formatRegion(regionString)
    -- remove the word "region"
    -- capitalize the first letter of each word
    regionString = string.gsub(regionString, "(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    -- trim any leading/trailing whitespace
    regionString = trim(regionString)
    return regionString
end

local function getCellData(cell)
    local cellX = cell.gridX
    local cellY = cell.gridY
    if not cell.isExterior then
        cellX = -999
        cellY = -999
    end
    local cellLabel = cell.name
    if cell.name == "" or cell.name == nil then
        cellLabel = formatRegion(cell.region)
    end
    local cellName = cell.name
    if not cellName then
        cellName = ""
    end
    return { cellX = cellX, cellY = cellY, cellName = cellName, cellLabel = cellLabel, }
end
local function getImportedData()
    local ret = {}
    for index, value in ipairs(MUNDISLocData) do
        if not value.wasImported then
            table.insert(ret, value)
        end
    end
    return ret
end
local function addMundisLocation(extPos, extRot, cellData)
    local ID = generateUniqueID()
    local newData = { ID = ID, position = extPos, rotation = extRot, cellData = cellData, wasImported = wasImported }
    table.insert(MUNDISLocData, newData)

    myModData:set("MUNDISLocData", MUNDISLocData)
    return newData
end
local function initData()
    if not MUNDISLocData then
        MUNDISLocData = {}
    end
    wasImported = true
    for index, data in ipairs(MUNDISStartData) do
        local ppos = util.vector3(data.px, data.py, data.pz)
        local boxRot = data.rz
        local cellName = data.cell
        local cellData = {
            cellName = cellName,
            cellX = data.cellX,
            cellY = data.cellY,
            cellLabel = cellName,
            contentFile = data.contentFile
        }
        addMundisLocation(ppos, boxRot, cellData)
    end
    wasImported = false
end
local function getData()
    return MUNDISLocData
end
local bcomExists = false
if core.API_REVISION == 29 then
    for index, value in ipairs(world.getCellByName("Vivec, Puzzle Canal, Center"):getAll()) do
        if value.recordId:lower() == "ql_ladderdoor01" then
            bcomExists = true
            break
        end
    end
end
local function contentFileChecker(contentFile)
    contentFile = contentFile:lower()
    if core.API_REVISION > 29 then
        return core.contentFiles.has(contentFile)
    else
        if contentFile == "beautiful cities of morrowind.esp" then
            return bcomExists
        elseif contentFile == "solstheim tomb of the snow prince.esm" then
            return world.getExteriorCell(-15, 22).name == "Fort Frostmoth"
        elseif contentFile == "tr_mainland.esm" then
            return world.getExteriorCell(5, -28).name == "Almas Thirr"
        end
        return false
    end
end
local function setCellButton(cell, buttonId, setUnSet)
    if buttonData["mundis_switch_" .. buttonId] then return false end

    for index, dataItem in ipairs(MUNDISLocData) do
        if (string.lower(cell) == string.lower(dataItem.cellData.cellName)) then
            if dataItem.cellData.contentFile and contentFileChecker(dataItem.cellData.contentFile) then
                buttonData["mundis_switch_" .. buttonId] = dataItem.ID
                return true
            end
        end
    end

    for index, dataItem in ipairs(MUNDISLocData) do
        if (string.lower(cell) == string.lower(dataItem.cellData.cellName)) and not dataItem.cellData.contentFile then
            buttonData["mundis_switch_" .. buttonId] = dataItem.ID
            return true
        end
    end
    if setUnSet then
        buttonData["mundis_switch_" .. buttonId] = -1
    end
    return false
end
local function setButtonDest(data)
    local buttonId = data.buttonId
    local newId = data.newId
    for index, dataItem in ipairs(MUNDISLocData) do
        if (dataItem.ID == newId) then
            buttonData[buttonId] = newId
            myModData:set("buttonData", buttonData)
            return
        end
    end
end
local function initButtons()
    initData()
    setCellButton("Balmora", "front_01")
    setCellButton("Vivec, Arena", "front_02")
    setCellButton("Ald-ruhn", "front_03")
    setCellButton("Sadrith Mora", "front_04")
    setCellButton("Caldera", "front_05")
    setCellButton("Gnisis", "front_06")
    setCellButton("Vos", "front_07")
    setCellButton("Seyda Neen", "front_08")

    setCellButton("Tel Aruhn", "side01")
    setCellButton("Khuul", "side02")
    setCellButton("Molag Mar", "side03")
    setCellButton("Pelagiad", "side04")
    setCellButton("Suran", "side05")
    setCellButton("Ebonheart", "side06")
    setCellButton("Fort Frostmoth", "side07")
    setCellButton("Mournhold, Temple Courtyard", "side08")

    setCellButton("Odai Plateau", "side09")
    setCellButton("Uvirith's Grave", "side10")
    setCellButton("Bal Isra", "side11")
    setCellButton("Dagon Fel", "side12")
    setCellButton("Moonmoth Legion Fort", "side13")
    setCellButton("Hla Oad", "side14")
    setCellButton("Tel Mora", "side15")
    setCellButton("Ald Velothi", "side16")


    setCellButton("Windmoth Legion Fort", "side29", true)
    setCellButton("Vhul", "side30", true)
    setCellButton("Gorne", "side31", true)
    setCellButton("Ranyon-ruhn", "side32", true)
    setCellButton("Nivalis", "side17", true)
    setCellButton("Bodrum", "side18", true)
    setCellButton("Port Telvannis", "side19", true)
    setCellButton("Firewatch", "side20", true)

    setCellButton("Akamora", "side21", true)
    setCellButton("Old Ebonheart", "side22", true)
    setCellButton("Andothren", "side23", true)
    setCellButton("Almas Thirr", "side24", true)
    setCellButton("Helnim", "side25", true)
    setCellButton("Necrom", "side26", true)
    setCellButton("Bahrammu", "side27", true)
    setCellButton("Roa Dyr", "side28", true)

    myModData:set("buttonData", buttonData)
    myModData:set("MUNDISLocData", MUNDISLocData)
end
local function onLoad(data)
    if MUNDISLocData == nil then
        initButtons()
    end
    if (data) then
        MUNDISLocData = data.MUNDISLocData
        idCounter = data.idCounter
        buttonData = data.buttonData
        myModData:set("MUNDISLocData", MUNDISLocData)
        myModData:set("buttonData", buttonData)
    end
    for index, value in ipairs(MUNDISLocData) do
        if not value.cellData.cellLabel then
            value.cellData.cellLabel = value.cellData.cellName
        end
    end
end
local function onSave()
    return { MUNDISLocData = MUNDISLocData, idCounter = idCounter, buttonData = buttonData, }
end
local function setData(data)
    MUNDISLocData = data
end

local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ((z))
        return rotate
    end
end
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
local function getBoxExitPos(pos, rot, direction)
    local offset = 0
    if not direction then
        direction = "north"
        offset = 180
    else

    end
    local targetPos = getPositionBehind(pos, rot, 150, direction)
    return targetPos, createRotation(0, 0, math.rad(offset) + rot)
end
local function onInit()
    --local MUNDISData = storage.globalSection('MundisData')
    --if(MUNDISData:get("LocationData" ) == nil ) then
    --MUNDISData:set("LocIndex",0)
    --MUNDISData:set("LocationData",MUNDISStartData )
end
local function onPlayerAdded(plr)
    if MUNDISLocData == nil then
        initButtons()
        myModData:set("MUNDISLocData", MUNDISLocData)
        myModData:set("buttonData", buttonData)
        interfaces.MundisGlobalData.onLoad({ LocIndex = 0, NextIndex = getIDFromCell(startCell) })
        return
    end
    myModData:set("MUNDISLocData", MUNDISLocData)
    myModData:set("buttonData", buttonData)
    core.sendGlobalEvent("MUNDISInit", nil)
end

return {
    interfaceName = "MundisDataHandler",
    interface = {
        version = 1,
        getData = getData,
        setData = setData,
        setCellButton = setCellButton,
        getBoxExitPos = getBoxExitPos,
        addMundisLocation = addMundisLocation,
        getCellData = getCellData,
        getIDFromCell = getIDFromCell,
        getImportedData = getImportedData,
        contentFileChecker = contentFileChecker,
    },
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
        onPlayerAdded = onPlayerAdded,
    },
    eventHandlers = { setButtonDest = setButtonDest }
}
