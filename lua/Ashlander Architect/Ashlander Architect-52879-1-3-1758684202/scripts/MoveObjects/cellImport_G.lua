local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local acti = require("openmw.interfaces").Activation
local base_64 = require("scripts.MoveObjects.utility.base_64")
local settlementList = {}
local time = require('openmw_aux.time')
local myModData = storage.globalSection("AASettlements")
local treeData = {}
local config = require("scripts.MoveObjects.config")
if not config.isUpdated then
    error("Your OpenMW version is too old!")
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
local function remove_non_printable_chars(input)
    -- Match and retain only printable characters (ASCII 32 to 126)
    local clean = string.gsub(input, "[^%c%s%g]", "") -- Keep printable, spaces, and graphic characters
    return clean
end
local function split_table(serialized_str, chunk_size)
    local chunks = {}
    local current_chunk = {}
    local count = 0

    -- Iterate over each line in the serialized string
    for line in serialized_str:gmatch("[^\n]*") do
        current_chunk[#current_chunk + 1] = line
        if line:find("^%[%d+%]") then
            count = count + 1
        end

        if count >= chunk_size then
            chunks[#chunks + 1] = table.concat(current_chunk, "\n")
            current_chunk = {}
            count = 0
        end
    end

    -- Add any remaining lines as the last chunk
    if #current_chunk > 0 then
        chunks[#chunks + 1] = table.concat(current_chunk, "\n")
    end

    return chunks
end
function split(str, sep)
    local t = {}
    local pattern = "(.-)" .. sep
    local last_end = 1
    local s, e, cap = str:find(pattern, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end
        last_end = e + 1
        s, e, cap = str:find(pattern, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 76) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        local rotatex = util.transform.rotateX(x)
        local rotatey = util.transform.rotateY(y)
        rotate = rotate:__mul(rotatex)
        rotate = rotate:__mul(rotatey)
        return rotate
    end
end
local function importCell(jsonBase64, targetCell)
    if not targetCell then
        targetCell = world.players[1].cell
    end
    local decoded = base_64.decode_base64(jsonBase64)
    local decoded_tables = split(decoded, "|SPL|")
    local combined_table = {}
    for i, decoded in ipairs(decoded_tables) do--loop through each item on hte list
        -- Remove non-printable characters from the table string
        local clean_str = remove_non_printable_chars(decoded)
        
        -- Convert the string to a Lua table
        --print(clean_str)
        
        local success, t = pcall(function()
            return util.loadCode("return " .. clean_str, {})()
        end)
        
        if success and t then
            -- Combine the tables
            -- If your tables are arrays and you want to concatenate them:
            for _, v in ipairs(t) do
             --   table.insert(combined_table, v)
            end
            
            table.insert(combined_table, t)
            -- If you simply want a table of tables:
            --[[
            ]]
        else
            -- Skip this set and optionally print a message
            print("Failed to load table at index " .. i .. ", skipping.")
        end
     
    --    table.insert(combined_table, t)
    end
    if not combined_table or #combined_table == 0 then
        error("No decoded table")
    end
    local foundObjects = {}
    for index, obj in ipairs(targetCell:getAll()) do--check each existing item in cell
        local found = false
        local refNum = getRefNum(obj.id)
        for index, subtable in pairs(combined_table) do
            --each item
            --First, we check to make sure all of these things are still here. If they're not, we remove them.
            local objRefNum = subtable.refNum
         --   print(refNum,objRefNum)
            if refNum == objRefNum then
                found = true
                foundObjects[objRefNum] = obj
            end
        end
        if not found then
            obj:remove()
        end
    end

    for index, savedObj in pairs(combined_table) do
        local newObj = foundObjects[savedObj.refNum]
        if not savedObj.contentFile then
            local newObj = world.createObject(savedObj.recordId,savedObj.count)
            if savedObj.soul then
                types.Miscellaneous.setSoul(newObj,savedObj.soul)
            end
            newObj:teleport(targetCell,util.vector3(savedObj.position.x,savedObj.position.y,savedObj.position.z),createRotation(savedObj.rotation.x,savedObj.rotation.y,savedObj.rotation.z))
        else
            newObj:teleport(targetCell,util.vector3(savedObj.position.x,savedObj.position.y,savedObj.position.z),createRotation(savedObj.rotation.x,savedObj.rotation.y,savedObj.rotation.z))
     
        end
        
        if savedObj.inventory and (newObj.type == types.NPC or newObj.type == types.Creature or newObj.type == types.Container) then
           
            if not types.Container.content(newObj):isResolved() then
                types.Container.content(newObj):resolve()
            end
            for index, item in ipairs(types.Actor.inventory(newObj):getAll()) do
                item:remove()
            end
            local itemsToEquip = {}
            for index, value in ipairs(savedObj.inventory ) do
                local newItem = world.createObject(value.recordId,value.count or 1)
                if value.soul then
                    types.Miscellaneous.setSoul(newItem,savedObj.soul)
                end
                newItem:moveInto(newObj)
                if value.equipped then
                    table.insert(itemsToEquip,value.recordId)
                end
            end
            if #itemsToEquip > 0 then
                
                newObj:sendEvent("equipItems_Default",itemsToEquip)
            end
        end
    end
end

return {
    interfaceName = "CellImport",
    interface = {
        importCell = importCell,
        serializeCell = serializeCell,
        codeTest = codeTest,
        serializeObjectLs = serializeObjectLs,
    },
    eventHandlers = {
        importCell = importCell,
    }
}
