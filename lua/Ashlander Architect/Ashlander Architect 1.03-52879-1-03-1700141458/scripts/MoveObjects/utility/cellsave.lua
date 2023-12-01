local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local interfaces = require("openmw.interfaces")
local objectList = {}
local idList = {}


local function tableToString(tbl, lineLength, currentLength)
    lineLength = lineLength or 260
    currentLength = currentLength or 0
    local str = ""

    if type(tbl) == "table" then
        str = str .. "{"
        for k, v in pairs(tbl) do
            local keyStr = tableToString(k, lineLength, currentLength + 2)
            local valueStr = tableToString(v, lineLength, currentLength + #keyStr + 6)
            local entryStr = "[" .. keyStr .. "]=" .. valueStr .. ","
            if currentLength + #entryStr > lineLength then
                str = str .. "\n  " .. entryStr
                currentLength = #entryStr + 2
            else
                str = str .. " " .. entryStr
                currentLength = currentLength + #entryStr
            end
        end
        str = str .. "}"
    elseif type(tbl) == "number" then
        str = str .. tostring(tbl)
    elseif type(tbl) == "string" then
        str = str .. string.format("%q", tbl)
    else
        str = str .. "\"" .. tostring(tbl) .. "\""
    end

    return str
end
local function serializeObject(obj)
    local tbl = {}
    tbl.position = { x = obj.position.x, y = obj.position.y, z = obj.position.z }
    tbl.scale = obj.scale
    tbl.recordId = obj.recordId
    tbl.id = obj.id
    local z, y, x = obj.rotation:getAnglesZYX()
    if obj.startingRotation and obj.contentFile then
        z, y, x = obj.startingRotation:getAnglesZYX() --make sure doors stay closed
    end
    tbl.rotation = { x = x, y = y, z = z }

    if obj.type == types.Door and types.Door.isTeleport(obj) then
        tbl.teleport                   = {}
        local tpos                     = types.Door.destPosition(obj)
        tbl.teleport.position          = { x = tpos.x, y = tpos.y, z = tpos.z }
        local z, y, x                  = types.Door.destRotation(obj):getAnglesZYX()
        tbl.teleport.rotation          = { x = x, y = y, z = z }
        tbl.teleport.cell              = { name = types.Door.destCell(obj).name }
        local destdoor                 = I.AA_CellGen_2.findDoorPair(obj)[1]
        tbl.teleport.destDoor          = {

        }
        tbl.teleport.destDoor.id       = destdoor.id
        local tpos                     = types.Door.destPosition(destdoor)
        tbl.teleport.destDoor.position = { x = tpos.x, y = tpos.y, z = tpos.z }
        local z, y, x                  = types.Door.destRotation(destdoor):getAnglesZYX()
        tbl.teleport.destDoor.rotation = { x = x, y = y, z = z }
    end
    return tbl
end
local function serializeObjectLs(objLs)
    local tbl = {}

    for index, value in ipairs(objLs) do
        table.insert(tbl, serializeObject(value))
    end

    local tableToSave = (tableToString(tbl))
    --print(tableToSave)
    --I.ZackUtilsG.printToConsole(tableToSave)
    return tableToSave
end
local function serializeCell(cell)
    local cellTable = { [cell.name] = {} }
    for index, value in ipairs(cell:getAll()) do
        if I.AA_CellGen_2_CellCopy.canCopyObject(value) then
            table.insert(cellTable[cell.name], serializeObject(value))
        end
    end

    local tableToSave = (tableToString(cellTable))
    -- print(tableToSave)
    -- I.ZackUtilsG.printToConsole(tableToSave)
    return tableToSave
end


return {
    interfaceName = "CellSave",
    interface = {
        serializeObject = serializeObject,
        serializeCell = serializeCell,
        serializeObjectLs = serializeObjectLs,
    },
    eventHandlers = {
        -- createItemReturn_AA = createItemReturn,
        printToConsoleEvent_AA = printToConsoleEvent,
        addItemEquipReturn_AA = addItemEquipReturn,
    },
}
