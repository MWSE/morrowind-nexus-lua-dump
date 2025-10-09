local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local interfaces = require("openmw.interfaces")
local objectList = {}
local idList = {}


local function tableToString(tbl, lineLength, currentLength,top)
    lineLength = lineLength or 260
    currentLength = currentLength or 0
    local str = ""

    if type(tbl) == "table" then
        if not top then
            
        str = str .. "{"
        end
        for k, v in pairs(tbl) do
            local keyStr = tableToString(k, lineLength, currentLength + 2)
            local valueStr = tableToString(v, lineLength, currentLength + #keyStr + 6)
            local entryStr = "[" .. keyStr .. "]=" .. valueStr .. ","
            if top then
                entryStr =valueStr .. "|SPL|"
            else
                entryStr = "[" .. keyStr .. "]=" .. valueStr .. ","
            end
            if currentLength + #entryStr > lineLength then
                str = str .. "\n  " .. entryStr
                currentLength = #entryStr + 2
            else
                str = str .. " " .. entryStr
                currentLength = currentLength + #entryStr
            end
        end
        if not top then
        str = str .. "}" 
        end
    elseif type(tbl) == "number" then
        str = str .. tostring(tbl)
    elseif type(tbl) == "string" then
        str = str .. string.format("%q", tbl)
    else
        str = str .. "\"" .. tostring(tbl) .. "\""
    end

    return str
end
local function getEquipped(recordId, actor)
    for i, x in pairs(types.Actor.getEquipment(actor)) do
        if x.recordId == recordId then return true end
    end
    return false
end
local function seralizeInventory(obj)
    local items = {}
    local isActor = false
    if obj.type == types.NPC or obj.type == types.Creature then
        isActor = true
    end
    for index, item in ipairs(types.Container.content(obj):getAll()) do
        local data = {
            recordId = item.recordId,
            count = item.count
        }
        if item.type == types.Miscellaneous and types.Miscellaneous.getSoul(item) then
            data.soulId =  types.Miscellaneous.getSoul(item) 
        end
        if isActor then
            if getEquipped(item.recordId,obj) then
                data.equipped = true
            end
        end
        table.insert(items,data)
    end
    return items
end
local function getRefNum(objId)
    local idNumber = objId--tonumber(string.match(selectedObject.id, "^(.-)_"))
    if idNumber:sub(1, 1) == "@" then
        -- Remove the '@' and convert the rest to a number
        local hex_part = idNumber:sub(2)
        idNumber = tonumber(hex_part, 16) -- Convert from hex to decimal
    end
    return  idNumber % 0x10000
end
local function serializeObject(obj)
    local tbl = {}
    tbl.position = { x = obj.position.x, y = obj.position.y, z = obj.position.z }
    tbl.scale = obj.scale
    tbl.recordId = obj.recordId
    tbl.id = obj.id

    tbl.refNum = getRefNum(obj.id)
    if obj.count ~= 1 then
        tbl.count = obj.count
    end
    --TODO: Handle inventories
    if obj.type == types.NPC or obj.type == types.Creature or obj.type == types.Container then
      
        if not types.Container.content(obj):isResolved() then
            types.Container.content(obj):resolve()
        end
       tbl.inventory = seralizeInventory(obj)
       --print("Saving inventory")
    end
    local z, y, x = obj.rotation:getAnglesZYX()
    if obj.startingRotation and obj.contentFile then
        z, y, x = obj.startingRotation:getAnglesZYX() --make sure doors stay closed
    end
    if obj.contentFile then
        tbl.contentFile = obj.contentFile
    end
    tbl.rotation = { x = x, y = y, z = z }
    if obj.type == types.Miscellaneous and types.Miscellaneous.getSoul(obj) then
        tbl.soulId =  types.Miscellaneous.getSoul(obj) 
    end

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
    elseif obj.type == types.Activator and I.AA_Records.getDoorOrigID(obj.recordId) then
        local pos, rot, cellName = I.AA_CellGen_2_CellCopy_DoorTP.getMarkerDataForDoor(obj)
         tbl.teleport                   = {}
        local tpos                     = pos
        tbl.teleport.position          = { x = tpos.x, y = tpos.y, z = tpos.z }

        tbl.teleport.rotation          = { x = 0, y = 0, z = rot }
        local cellCheck 
        if cellName then
            
        for i,x in ipairs(world.cells) do
            if x.name:lower() == cellName:lower() then
                cellCheck = true
            end
        end
        end
        if cellCheck and cellName then
              tbl.teleport.cell              = { name = cellName , isExterior = world.getCellByName(cellName).isExterior}
       
        else
  tbl.teleport.cell              = { name = nil , isExterior = true}
       
        end
       --tbl.recordId = I.AA_Records.getDoorOrigID(obj.recordId)
   
    end
    return tbl
end

--[[
================================================================================
serializeObject(obj) — Return Table Schema & All Possible Subvalues
================================================================================

Return type: ObjectSnapshot (table)

Always present:
- position               table
  - x                    number
  - y                    number
  - z                    number
- rotation               table               -- angles in radians (XYZ order as stored)
  - x                    number
  - y                    number
  - z                    number
- scale                  number
- recordId               string              -- base record editor ID
- id                     string|integer      -- engine instance/unique id
- refNum                 integer             -- reference number for the placed object

Conditionally present:
- count                  integer             -- only if obj.count ~= 1
- contentFile            string              -- only if obj.contentFile is set on the instance
- inventory              table[]             -- only for NPC / Creature / Container
  -- The exact element shape depends on seralizeInventory(obj). Typical subvalues include:
  --   - itemId           string
  --   - count            integer
  --   - condition        number|nil
  --   - soulId           string|nil
  --   - owner            string|nil
  --   - charge           number|nil
  -- (If seralizeInventory adds more fields, they will appear here as given.)
- soulId                 string              -- only for Miscellaneous items that contain a soul (soul gems)

Teleport data (only for Doors that are teleporters: obj.type == types.Door and types.Door.isTeleport(obj)):
- teleport               table
  - position             table               -- destination position of THIS door's teleport
    - x                  number
    - y                  number
    - z                  number
  - rotation             table               -- destination rotation of THIS door's teleport (radians)
    - x                  number
    - y                  number
    - z                  number
  - cell                 table
    - name               string              -- destination cell name
  - destDoor             table               -- paired destination door metadata
    - id                 string|integer
    - position           table
      - x                number
      - y                number
      - z                number
    - rotation           table               -- radians
      - x                number
      - y                number
      - z                number

Notes:
- If obj.startingRotation and obj.contentFile are present, rotation is derived from startingRotation
  to preserve initial/closed states (e.g., doors).
- Angles are extracted via getAnglesZYX() but stored as {x, y, z} in the output.
- Inventory resolution is forced for Containers (and for NPC/Creature via the same pathway) prior
  to serialization to ensure contents are available.

================================================================================
]]--
local function serializeObjectLs(objLs)
    local tbl = {}

    for index, value in ipairs(objLs) do

        if value.enabled and value.count > 0 then
            
            table.insert(tbl, serializeObject(value))
        end
    end

    local tableToSave = (tableToString(tbl,nil,nil,true)) 
    --print(tableToSave)
    --I.DaisyUtilsG.printToConsole(tableToSave)
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
    -- I.DaisyUtilsG.printToConsole(tableToSave)
    return tableToSave, cellTable
end
local function getCellNewObjs(cell)
    local ret = {}
    for i, x in ipairs(cell:getAll()) do
        if not x.contentFile and x.type ~= types.Creature then
            table.insert(ret,x)
        end
    end
    --TODO: filter out levelled list creatures
    return ret
end

return {
    interfaceName = "CellSave",
    interface = {
        serializeObject = serializeObject,
        serializeCell = serializeCell,
        serializeObjectLs = serializeObjectLs,
        getCellNewObjs = getCellNewObjs,
    },
    eventHandlers = {
        -- createItemReturn_AA = createItemReturn,
        printToConsoleEvent_AA = printToConsoleEvent,
        addItemEquipReturn_AA = addItemEquipReturn,
    },
}
