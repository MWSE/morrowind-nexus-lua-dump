local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local interfaces = require("openmw.interfaces")


local config = require("scripts.MoveObjects.config")

local helpVal = "help"

local interfaceModifier = "AA"
local zu
local itemTypes = {
    { name = "Apparatus",  type = types.Apparatus },
    { name = "Armor",      type = types.Armor },
    { name = "Book",       type = types.Book },
    { name = "Clothing",   type = types.Clothing },
    { name = "Ingredient", type = types.Ingredient },
    { name = "Light",      type = types.Light },
    { name = "Lockpick",   type = types.Lockpick },
    { name = "misc",       type = types.Miscellaneous },
    { name = "Potion",     type = types.Potion },
    { name = "Probe",      type = types.Probe },
    { name = "Repair",     type = types.Repair },
    { name = "Weapon",     type = types.Weapon },
    { name = "item",       type = types.Item },
}

local allTypes = {
    { name = "Activator",  type = types.Activator },
    { name = "Apparatus",  type = types.Apparatus },
    { name = "Armor",      type = types.Armor },
    { name = "Book",       type = types.Book },
    { name = "Clothing",   type = types.Clothing },
    { name = "Ingredient", type = types.Ingredient },
    { name = "Light",      type = types.Light },
    { name = "Lockpick",   type = types.Lockpick },
    { name = "misc",       type = types.Miscellaneous },
    { name = "Potion",     type = types.Potion },
    { name = "Probe",      type = types.Probe },
    { name = "Repair",     type = types.Repair },
    { name = "Weapon",     type = types.Weapon },
    { name = "Creature",   type = types.Creature },
    { name = "Door",       type = types.Door },
    { name = "NPC",        type = types.NPC },
    { name = "Player",     type = types.Player },
    { name = "Static",     type = types.Static },
    { name = "Container",  type = types.Container }
}
--Easy way to get CONSOLE_COLOR outside of player scripts
local CONSOLE_COLOR = {
    Default = "Default",
    Error = "Error",
    Info = "Info",
    Success = "Success",
}
local function printHelpText(table)
    for i, line in ipairs(table) do
        zu.getPlayer():sendEvent("printToConsoleEvent", { message = line, color = CONSOLE_COLOR.Info })
    end
end
local function getInventory(object)
    --Quick way to get the inventory of an object, regardless of type
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
    return nil --Not any of the above types, so no inv
end



local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function teleportOutsideCell(objectToTeleport, cellname)
    for x = -100, 100 do
        for y = -100, 100 do
            local cell = world.getExteriorCell(x, y)
            local doors = cell:getAll(types.Door)
            if (cellname:lower() == cell.name:lower()) then

            end
            for i, record in ipairs(doors) do --find the door with the cell we want
                if (types.Door.isTeleport(record) and types.Door.destCell(record).name == cellname) then
                    local scell = types.Door.destCell(record)
                    local sdoors = scell:getAll(types.Door)
                    print(types.Door.destCell(record).name)
                    for i, record in ipairs(sdoors) do --find the doors inside so we can get back to the outside
                        if (types.Door.isTeleport(record) and types.Door.destCell(record).isExterior) then
                            local destPos = types.Door.destPosition(record)
                            local destRot = types.Door.destRotation(record)
                            local destCell = types.Door.destCell(record)
                            objectToTeleport:teleport(destCell, destPos, destCell)
                            return
                        end
                    end
                end
            end
        end
    end
end
local function activateThing(source, target)
    target:activateBy(source)
end
local function activateThingEvent(data)
    --Activates an object.
    data.target:activateBy(data.source)
end
local function teleportToExt(objectToTeleport, cellname) --need to do a ray cast if no int cell is found
    for x = -100, 100 do
        for y = -100, 100 do
            local cell = world.getExteriorCell(x, y)
            local doors = cell:getAll(types.Door)
            local found = false
            print(":" .. cellname .. ":")
            if (cellname:lower() == cell.name:lower()) then
                for i, record in ipairs(doors) do --find the door with the cell we want
                    --  if (types.Door.isTeleport(record) and types.Door.destCell(record).name == cellname) then
                    local scell = types.Door.destCell(record)
                    local sdoors = scell:getAll(types.Door)
                    for i, rsecord in ipairs(sdoors) do --find the doors inside so we can get back to the outside
                        if (types.Door.isTeleport(rsecord) and types.Door.destCell(rsecord).isExterior) then
                            local xdestPos = types.Door.destPosition(rsecord)
                            local xdestRot = types.Door.destRotation(rsecord)
                            print(objectToTeleport.recordId)
                            print(types.Door.destCell(rsecord).name)
                            local destCell = types.Door.destCell(rsecord)
                            objectToTeleport:teleport("", xdestPos, xdestRot)
                            return
                        end
                    end
                    -- end
                end
            end
        end
    end
end


local function findObjectRecordByName(name)
    local ret = {}

    --returns a table containing all records with the specified name.
    for index, typ in ipairs(allTypes) do
        for x, record in ipairs(typ.type.records) do
            if (record.name ~= nil and record.name:lower() == name:lower()) then
                table.insert(ret, record)
            end
        end
    end
    return ret
end
local function findObjectType(recordId)
    --returns the type of the record ID specified.
    for index, typ in ipairs(allTypes) do
        print(typ.name, #typ.type.records)

        for x, record in ipairs(typ.type.records) do
            if (record.id == recordId) then
                return typ.type
            end
        end
    end
    return nil
end

local function findObjectRecord(rec)
    rec = rec:lower()
    for index, typ in ipairs(allTypes) do
        for x, record in ipairs(typ.type.records) do
            if (record.id == rec) then
                return record, typ.type
            end
        end
    end

    for index, typ in ipairs(itemTypes) do
        print(typ.name)
        if (typ.type.records == nil) then
            break
        end
        for x, record in ipairs(typ.type.records) do
            if (record.name:lower() == rec) then
                return record, typ.type
            end
        end
    end
end
local function moveToActor(objectToTeleport, targetName, justReturn)
    --Finds an object in the world with the given ID. Returns the first result.
    local targetType = findObjectType(targetName)
    if targetType == nil then
        print("no target type")
        return
    end

    for index, cell in ipairs(world.cells) do
        for index, record in ipairs(cell:getAll(targetType)) do
            if (record.recordId == targetName) then
                local destPos = record.position
                local destRot = record.rotation
                local destCell = record.cell
                if (justReturn == true) then
                    objectToTeleport:sendEvent("selectReturn", record)
                    return
                end
                objectToTeleport:teleport(destCell, destPos, destCell)
                return
            end
        end
    end
end
local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')
local function setGameTime(desiredGameTime)

end
local function cellScan(cellName, type)
    --Prints the contents of a cell, to use in external use cases.
    local cell = world.getCellByName(cellName)
    local obs = cell:getAll()
    if (type ~= nil) then
        obs = cell:getAll(type)
    end
    for i, ref in ipairs(obs) do
        local field = string.format(
            "{recordId = \"%s\", Position = util.vector3(%f, %f, %f), Rotation = util.vector3(%f, %f, %f)},",
            ref.recordId,
            ref.position.x, ref.position.y, ref.position.z, ref.rotation.x, ref.rotation.y, ref.rotation.z)
        print(field)
    end
end
local function getCellNameByPos(position)
    --Provides the cell name based on a world position
    local cellSize = 8192
    local cellX = math.floor(position.x / cellSize)
    local cellY = math.floor(position.y / cellSize)

    return world.getExteriorCell(cellX, cellY).name
end
local function getCellByPos(position)
    --Provides the cell name based on a world position
    local cellSize = 8192
    local cellX = math.floor(position.x / cellSize)
    local cellY = math.floor(position.y / cellSize)

    return world.getExteriorCell(cellX, cellY)
end
local function getCellNamesByPositions(data)
    local positions = data.positions
    local player = data.player

    local cellNames = {}
    for _, position in ipairs(positions) do
        local cellName = getCellNameByPos(position)
        table.insert(cellNames, cellName)
    end
    player.sendEvent("ReturnCellNames", cellNames)
end
local function moveToActorEvent(data)
    moveToActor(data.objectToTeleport, data.targetName, data.justReturn)
end
local function teleportToExtEvent(data)
    teleportToExt(data.objectToTeleport, data.cellname)
end
local function ZackUtilsTeleport(data)
    --Simple event for teleporting something to the same cell.
    if (data.item == nil) then
        return
    end
    data.item:teleport(data.item.cell, data.position, data.rotation)
end


local function ZackUtilsTeleportToCell(data)
    --Simple function to teleport an object to any cell.
    if (data.item == nil) then
        print("No item")
        return
    end
    if (data.item.recordId == "player") then
    end
    if (data.cellname.name ~= nil) then
        data.cellname = data.cellname.name
    end
    data.item:teleport(world.getCellByName(data.cellname), data.position, { onGround = true, rotation = data.rotation })
end

local function matchNPCCells()
    local table = interfaces.TravelWindow_Data.travelData
    --Used to generate travel data

    for i, item in ipairs(interfaces.TravelWindow_Data.travelData) do
        local npcId = item.ID
        if (item.class == "guild guide") then
            local npcRecord = zu.findNPCInterior(npcId)

            if (npcRecord == nil) then
                print("Not found: " .. npcId)
            end
        else
            local npcRecord = zu.findNPCInWorld(npcId)

            if (npcRecord == nil) then
                print("Not found: " .. npcId)
            end
        end
    end
end


local function genTravelData()
    --Used to generate travel data. Not usable without modifications to the engine.
    for i, record in ipairs(types.NPC.records) do
        local myCell = ""
        local myRef = nil
        local myPos = { x = 0, y = 0, z = 0 }

        if (record.travelCount > 0) then
            --  for i, item in ipairs(interfaces.TravelWindow_Data.travelData) do
            local npcId = record.id
            if (record.class == "guild guide") then
                myRef = interfaces.ZackUtilsG.findNPCInterior(npcId)
            else
                myRef = interfaces.ZackUtilsG.findNPCInWorld(npcId)
            end
            --   end
            if (myRef ~= nil) then
                myPos = myRef.position
                myCell = myRef.cell.name
            end
        end
        if (record.travelCount == 0) then
        elseif (record.travelCount == 1) then
            local t1cellname = record.travel1destcellname
            if (t1cellname == "") then
                t1cellname = getCellNameByPos(record.travel1dest)
            end
            local outputTable = {
                ["ID"] = '"' .. record.id .. '"',
                ["class"] = '"' .. record.class .. '"',
                ["myCell"] = '"' .. myCell .. '"',
                ["travel1destcellname"] = '"' .. t1cellname .. '"',
                ["myPos"] = {
                    ["x"] = myPos.x,
                    ["y"] = myPos.y,
                    ["z"] = myPos.z
                },
                ["travel1dest"] = {
                    ["x"] = record.travel1dest.x,
                    ["y"] = record.travel1dest.y,
                    ["z"] = record.travel1dest.z
                },
                ["travel1destrot"] = {
                    ["z"] = record.travel1destrot.z
                }
            }

            local outputText = "{\n"
            for key, value in pairs(outputTable) do
                outputText = outputText .. '    ' .. tostring(key) .. ' = '
                if type(value) == "table" then
                    outputText = outputText .. "{\n"
                    for subKey, subValue in pairs(value) do
                        outputText = outputText .. '        ' .. tostring(subKey) .. ' = ' .. tostring(subValue) .. ',\n'
                    end
                    outputText = outputText .. "    },\n"
                else
                    outputText = outputText .. tostring(value) .. ',\n'
                end
            end
            outputText = outputText .. "}"

            print(outputText)
        elseif (record.travelCount == 2) then
            local t1cellname = record.travel1destcellname
            if (t1cellname == "") then
                t1cellname = getCellNameByPos(record.travel1dest)
            end
            local t2cellname = record.travel1destcellname
            if (t2cellname == "") then
                t2cellname = getCellNameByPos(record.travel2dest)
            end
            --   print(record.id .. "," .. record.class .. "," .. record.travel1dest.x .. "," .. record.travel1dest.y .. "," .. record.travel1dest.z .. "," .. record.travel1destrot.z .. "," .. record.travel2dest.x .. "," .. record.travel2dest.y .. "," .. record.travel2dest.z .. "," .. record.travel2destrot.z)
            local outputTable = {
                ["ID"] = '"' .. record.id .. '"',
                ["myCell"] = '"' .. myCell .. '"',
                ["class"] = '"' .. record.class .. '"',
                ["myPos"] = {
                    ["x"] = myPos.x,
                    ["y"] = myPos.y,
                    ["z"] = myPos.z
                },
                ["travel1dest"] = {
                    ["x"] = record.travel1dest.x,
                    ["y"] = record.travel1dest.y,
                    ["z"] = record.travel1dest.z
                },
                ["travel1destcellname"] = '"' .. t1cellname .. '"',
                ["travel1destrot"] = {
                    ["z"] = record.travel1destrot.z
                },
                ["travel2dest"] = {
                    ["x"] = record.travel2dest.x,
                    ["y"] = record.travel2dest.y,
                    ["z"] = record.travel2dest.z
                },
                ["travel2destcellname"] = '"' .. t2cellname .. '"',
                ["travel2destrot"] = {
                    ["z"] = record.travel2destrot.z
                }
            }

            local outputText = "{\n"
            for key, value in pairs(outputTable) do
                outputText = outputText .. '    ' .. tostring(key) .. ' = '
                if type(value) == "table" then
                    outputText = outputText .. "{\n"
                    for subKey, subValue in pairs(value) do
                        outputText = outputText .. '        ' .. tostring(subKey) .. ' = ' .. tostring(subValue) .. ',\n'
                    end
                    outputText = outputText .. "    },\n"
                else
                    outputText = outputText .. tostring(value) .. ',\n'
                end
            end
            outputText = outputText .. "}"

            print(outputText)
        elseif (record.travelCount == 3) then
            local t1cellname = record.travel1destcellname
            if (t1cellname == "") then
                t1cellname = getCellNameByPos(record.travel1dest)
            end
            local t2cellname = record.travel1destcellname
            if (t2cellname == "") then
                t2cellname = getCellNameByPos(record.travel2dest)
            end
            local t3cellname = record.travel3destcellname
            if (t3cellname == "") then
                t3cellname = getCellNameByPos(record.travel3dest)
            end


            -- print(record.id .. "," .. record.class .. "," .. record.travel1dest.x .. "," .. record.travel1dest.y .. "," .. record.travel1dest.z .. "," .. record.travel1destrot.z .. "," .. record.travel2dest.x .. "," .. record.travel2dest.y .. "," .. record.travel2dest.z .. "," .. record.travel2destrot.z .. "," .. record.travel3dest.x .. "," .. record.travel3dest.y .. "," .. record.travel3dest.z .. "," .. record.travel3destrot.z)
            local outputTable = {
                ["ID"] = '"' .. record.id .. '"',
                ["class"] = '"' .. record.class .. '"',
                ["myCell"] = '"' .. myCell .. '"',
                ["myPos"] = {
                    ["x"] = myPos.x,
                    ["y"] = myPos.y,
                    ["z"] = myPos.z
                },
                ["travel1dest"] = {
                    ["x"] = record.travel1dest.x,
                    ["y"] = record.travel1dest.y,
                    ["z"] = record.travel1dest.z
                },
                ["travel1destrot"] = {
                    ["z"] = record.travel1destrot.z
                },
                ["travel1destcellname"] = '"' .. t1cellname .. '"',
                ["travel2dest"] = {
                    ["x"] = record.travel2dest.x,
                    ["y"] = record.travel2dest.y,
                    ["z"] = record.travel2dest.z
                },
                ["travel2destrot"] = {
                    ["z"] = record.travel2destrot.z
                },
                ["travel2destcellname"] = '"' .. t2cellname .. '"',
                ["travel3dest"] = {
                    ["x"] = record.travel3dest.x,
                    ["y"] = record.travel3dest.y,
                    ["z"] = record.travel3dest.z
                },
                ["travel3destrot"] = {
                    ["z"] = record.travel3destrot.z
                },

                ["travel3destcellname"] = '"' .. t3cellname .. '"',
            }

            local outputText = "{\n"
            for key, value in pairs(outputTable) do
                outputText = outputText .. '    ' .. tostring(key) .. ' = '
                if type(value) == "table" then
                    outputText = outputText .. "{\n"
                    for subKey, subValue in pairs(value) do
                        outputText = outputText .. '        ' .. tostring(subKey) .. ' = ' .. tostring(subValue) .. ',\n'
                    end
                    outputText = outputText .. "    },\n"
                else
                    outputText = outputText .. tostring(value) .. ',\n'
                end
            end
            outputText = outputText .. "}"

            print(outputText)
        elseif (record.travelCount == 4) then
            local t1cellname = record.travel1destcellname
            if (t1cellname == "") then
                t1cellname = getCellNameByPos(record.travel1dest)
            end
            local t2cellname = record.travel2destcellname
            if (t2cellname == "") then
                t2cellname = getCellNameByPos(record.travel2dest)
            end
            local t3cellname = record.travel3destcellname
            if (t3cellname == "") then
                t3cellname = getCellNameByPos(record.travel3dest)
            end
            local t4cellname = record.travel4destcellname
            if (t4cellname == "") then
                t4cellname = getCellNameByPos(record.travel4dest)
            end

            local outputTable = {
                ["ID"] = '"' .. record.id .. '"',
                ["class"] = '"' .. record.class .. '"',
                ["myCell"] = '"' .. myCell .. '"',
                ["myPos"] = {
                    ["x"] = myPos.x,
                    ["y"] = myPos.y,
                    ["z"] = myPos.z
                },
                ["travel1dest"] = {
                    ["x"] = record.travel1dest.x,
                    ["y"] = record.travel1dest.y,
                    ["z"] = record.travel1dest.z
                },
                ["travel1destrot"] = {
                    ["z"] = record.travel1destrot.z
                },
                ["travel1destcellname"] = '"' .. t1cellname .. '"',
                ["travel2dest"] = {
                    ["x"] = record.travel2dest.x,
                    ["y"] = record.travel2dest.y,
                    ["z"] = record.travel2dest.z
                },
                ["travel2destrot"] = {
                    ["z"] = record.travel2destrot.z
                },
                ["travel2destcellname"] = '"' .. t2cellname .. '"',
                ["travel3dest"] = {
                    ["x"] = record.travel3dest.x,
                    ["y"] = record.travel3dest.y,
                    ["z"] = record.travel3dest.z
                },
                ["travel3destrot"] = {
                    ["z"] = record.travel3destrot.z
                },
                ["travel3destcellname"] = '"' .. t3cellname .. '"',
                ["travel4dest"] = {
                    ["x"] = record.travel4dest.x,
                    ["y"] = record.travel4dest.y,
                    ["z"] = record.travel4dest.z
                },
                ["travel4destrot"] = {
                    ["z"] = record.travel4destrot.z
                },
                ["travel4destcellname"] = '"' .. t4cellname .. '"',
            }

            local outputText = "{\n"
            for key, value in pairs(outputTable) do
                outputText = outputText .. '    ' .. tostring(key) .. ' = '
                if type(value) == "table" then
                    outputText = outputText .. "{\n"
                    for subKey, subValue in pairs(value) do
                        outputText = outputText .. '        ' .. tostring(subKey) .. ' = ' .. tostring(subValue) .. ',\n'
                    end
                    outputText = outputText .. "    },\n"
                else
                    outputText = outputText .. tostring(value) .. ',\n'
                end
            end
            outputText = outputText .. "}"

            print(outputText)
        end
    end
end
local function deleteById(cell, id)
    --Deletes the object with the specified ID in the specified cell.
    if (cell.name == nil) then
        cell = world.getCellByName(cell)
    end
    local searchList = cell:getAll()
    for index, value in ipairs(searchList) do
        if (value.id == id) then
            value:remove()
        end
    end
end
local function findByRecordId(cell, id, create)
    if (cell.name == nil) then
        cell = world.getCellByName(cell)
    end
    local searchList = cell:getAll()
    for index, value in ipairs(searchList) do
        if (value.recordId == id) then
            return value
        end
    end
    if (create) then
        local item = world.createObject(cell)
        item:teleport(cell, util.vector3(0, 0, 0))
        return item
    end
    return nil
end


local function ZackUtilsCreate(data)

end
local function getPlayer()
    return world.players[1]
end
local function getPlayerInventory()
    return types.Actor.inventory(getPlayer())
end
local function calculateBoxCenter(corner1, corner2, corner3, corner4)
    -- Calculate the minimum and maximum x, y, and z values
    local minX = math.min(corner1.x, corner2.x, corner3.x, corner4.x)
    local minY = math.min(corner1.y, corner2.y, corner3.y, corner4.y)
    local minZ = math.min(corner1.z, corner2.z, corner3.z, corner4.z)

    local maxX = math.max(corner1.x, corner2.x, corner3.x, corner4.x)
    local maxY = math.max(corner1.y, corner2.y, corner3.y, corner4.y)
    local maxZ = math.max(corner1.z, corner2.z, corner3.z, corner4.z)

    -- Calculate the center point
    local centerX = (minX + maxX) / 2
    local centerY = (minY + maxY) / 2
    local centerZ = (minZ + maxZ) / 2

    -- Create and return the center vector3
    return util.vector3(centerX, centerY, centerZ)
end

local function ZackUtilsCreateInterface(itemid, cellname, position, rotation)
    if (itemid == nil) then
        interfaces.ZackUtilsG.printToConsole(
            "Usage for this function: (itemid(string),cellname(string),position(vec3),rotation(vec3))")
        return
    end
    local item = world.createObject(itemid)
    item:teleport(world.getCellByName(cellname), position, rotation)
    return item
end
local function cellCopy(sourcecellName, targetcellName, basePosition, player)
    local cell = world.getCellByName(sourcecellName)
    local obs = cell:getAll()
    local createdObs = {}
    local oldPos = player.position
    local oldCell = player.cell
    player:teleport(world.getCellByName(sourcecellName), util.vector3(0, 0, 0))
    player:teleport(world.getCellByName(targetcellName), util.vector3(0, 0, 0))
    for i, ref in ipairs(obs) do
        local newref = ZackUtilsCreateInterface(ref.recordId, targetcellName, ref.position + basePosition, ref.rotation)
        table.insert(createdObs, newref)
    end
    player:teleport(oldCell, oldPos)
    return createdObs
end
local function ZackUtilsDelete(data)
    if (data ~= nil and data.count > 0) then
        data.enabled = false
        data:remove()
    end
end
local function removeItemCount(data)
    if (data.itemId ~= nil and data.count > 0) then
        local inv = types.Actor.inventory(data.actor)
        local item = inv:find(data.itemId)
        if (item ~= nil) then
            if (data.count > item.count) then
                item:remove()
            else
                item:remove(data.count)
            end
        end
    end
    if (data.item ~= nil and data.count > 0) then
        local inv = types.Actor.inventory(data.actor)
        local item = inv:find(data.item)
        if (item ~= nil) then
            if (data.count > item.count) then
                item:remove()
            else
                item:remove(data.count)
            end
        end
    end
end
local function ZackUtilsEmptyInto(data)
    local sourceInv = getInventory(data.source)
    if (sourceInv == nil) then

    end
    local targetInv = getInventory(data.target)
    for index, item in ipairs(sourceInv:getAll()) do
        item:moveInto(targetInv)
    end
end
local function ZackUtilsAddItem(data)
    local record = I.AA_Records.getRecord(data.itemId)
    if not record then
        error("Unable to find record " .. data.itemId)
    end
    local item = world.createObject(record, data.count)

    local inv = getInventory(data.actor)
    item:moveInto(types.Actor.inventory(data.actor))
    if (data.equip == true) then
        data.actor:sendEvent("addItemEquipReturn_AA", item)
    end
end
local function split(str, delimiter)
    local result = {}
    local pattern = "(.-)" .. delimiter .. "()"
    local start = 1
    local splitstart, splitend, captures = string.find(str, pattern, start)
    while splitstart do
        table.insert(result, captures[1])
        start = splitend
        splitstart, splitend, captures = string.find(str, pattern, start)
    end
    table.insert(result, string.sub(str, start))
    return result
end


local function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end


local function ZackUtilsAddItems(data)
    local itemIds = data.itemIds
    print(#itemIds)
    local actor = data.actor
    local goodItemIds = {}
    local inv = getInventory(actor)
    for _, itemId in ipairs(itemIds) do
        local count = 1
        local itemData = mysplit(itemId, ",")
        if #itemData > 0 then
            itemId = itemData[1]
            print(itemId)
            if #itemData > 1 then
                local countStr = itemData[2]:match("%d+")
                count = tonumber(countStr) or count
            end
            table.insert(goodItemIds, itemId)
            local item = world.createObject(itemId, count)
            item:moveInto(inv)
        end
    end
    print("Doing equip")
    if (data.equip == true) then
        data.actor:sendEvent("equipItems", goodItemIds)
    end
end
local function ZackUtilsPauseWorld(doPause)
    if (doPause) then
        world.setSimulationTimeScale(0)
    else
        world.setSimulationTimeScale(1)
    end
end


local function findInWorld(recordId, type)
    for index, cell in ipairs(world.cells) do
        if (cell.isExterior) then
            for index, value in ipairs(cell:getAll(type)) do
                if (value.recordId:lower() == recordId:lower()) then
                    return value
                end
            end
        end
    end
    return nil
end
local function createContainerFilledWithType(type, actor)
    if (type == helpVal) then
        print("Trying this")
        if (actor == nil) then
            print("Actor is nil!")
            return
        end
        zu.printToConsole(actor .. ": " .. "Creates container filled with the specified type")
        return
    end
    if (actor == nil) then
        actor = getPlayer()
    end

    if (type == "item") then
        local container = world.createObject("Fryfnhild")
        for i, record in ipairs(getInventory(container):getAll()) do
            record:remove()
        end
        container:teleport(actor.cell, actor.position, util.vector3(0, 0, 0))
        for index, typeTb in ipairs(itemTypes) do
            if (typeTb.type ~= types.Item) then
                local records = typeTb.type.records
                for i, record in ipairs(records) do
                    if (type == types.Light and record.isCarriable == false) then

                    elseif (record.mwscript == nil or record.mwscript == "") then
                        local object = world.createObject(record.id, 10)
                        object:moveInto(getInventory(container))
                    end
                end
            end
        end
        container:activateBy(actor)
        return
    end
    for index, typeTb in ipairs(itemTypes) do
        if (type:lower() == typeTb.name:lower()) then
            type = typeTb.type
            break
        end
    end

    local container = world.createObject("Fryfnhild")
    container:teleport(actor.cell, actor.position, util.vector3(0, 0, 0))
    for i, record in ipairs(getInventory(container):getAll()) do
        record:remove()
    end
    local records = type.records
    for i, record in ipairs(records) do
        if (type == types.Light and record.isCarriable == false) then

        elseif (record.mwscript == nil or record.mwscript == "") then
            local object = world.createObject(record.id, 10)
            object:moveInto(getInventory(container))
        end
    end
    container:activateBy(actor)
end

local function printToConsole(msg, color)
    if (msg == nil) then
        print("Global message is nil!")
    end
    getPlayer():sendEvent("printToConsoleEvent", { message = msg, color = color })
end

local function setDisabled(data)
    local object = data.object
    local state = data.state

    object.enabled = state
end
local function printToTerminal(text)
    print(text)
end
local function setPos(data, val2)
    if (data == helpVal) then
        printToConsole(val2 .. ": " .. "This is an event")
        return
    end
    local actor = data.actor
    local axis = data.axis
    local pos = data.pos
    local x = actor.position.x
    local y = actor.position.y
    local z = actor.position.z
    if (axis == "x") then
        x = pos
    elseif axis == "y" then
        y = pos
    elseif axis == "z" then
        z = pos
    end
    actor:teleport(actor.cell, util.vector3(x, y, z))
end
local function help(command)
    local functionTable = {
        ["createContainerFilledWithType"] = createContainerFilledWithType,
        ["setPos"] = setPos,

    }
    if (command == nil) then
        for index, value in pairs(functionTable) do
            value(helpVal, index)
        end
    end
    --return functionTable["createContainerFilledWithType" ]
end
local function onInit()
    zu = interfaces.ZackUtilsG
end
local function showMessage(message)
    getPlayer():sendEvent("showMessageEvent", message)
end
local function renameActivator(object, newName)
    function removeFirstInstance(str, pattern)
        local startPos, endPos = str:find(pattern)
        if startPos and endPos then
            local prefix = str:sub(1, startPos - 1)
            local suffix = str:sub(endPos + 1)
            return prefix .. suffix
        else
            return str
        end
    end

    local newActData = {
        name = newName,
        model = removeFirstInstance(object.type.record(object).model, "meshes\\"),
        mwscript = object.type.record(object).mwscript,
    }
    for i, record in ipairs(object.type.records) do
        if record.name == newActData.name and removeFirstInstance(record.model, "meshes\\") == newActData.model and record.mwscript == newActData.mwscript then
            --already have this, don't need to do anything else.
            local newRecord = world.createObject(record.id)
            newRecord:teleport(object.cell.name, object.position, object.rotation)
            object:remove()
            print("Found existing record")
            return newRecord
        end
    end
    local ret = types.Activator.createRecordDraft(newActData)
    local newrecord = world.createRecord(ret)
    local newobject = world.createObject(newrecord.id, 1)
    newobject:teleport(object.cell.name, object.position, object.rotation)
    object:remove()
    return newobject
end
local function addNumbers(num1, num2)
    local function normalizeNumber(num)
        local normalizedNum = string.match(num, "^0*(.-)$") -- Remove leading zeros
        if normalizedNum == "" then
            return "0"
        end
        return normalizedNum
    end

    local function padWithZeros(num, maxLength)
        local paddedNum = num
        while #paddedNum < maxLength do
            paddedNum = "0" .. paddedNum
        end
        return paddedNum
    end

    local maxLength = math.max(#num1, #num2)
    num1 = padWithZeros(num1, maxLength)
    num2 = padWithZeros(num2, maxLength)

    local result = ""
    local carry = 0

    for i = maxLength, 1, -1 do
        local digit1 = tonumber(string.sub(num1, i, i)) or 0
        local digit2 = tonumber(string.sub(num2, i, i)) or 0

        local sum = digit1 + digit2 + carry
        local digitResult = sum % 10
        carry = math.floor(sum / 10)

        result = tostring(digitResult) .. result
    end

    if carry > 0 then
        result = tostring(carry) .. result
    end

    return normalizeNumber(result)
end
local function getObjectAngle(obj)
    local z, y, x = obj.rotation:getAnglesZYX()
    return { z = z, x = x, y = y }
end
local function replaceOb(data)
    local newObId = data.newObId
    local oldObject = data.oldObject

    local newOb = world.createObject(newObId)
    newOb:teleport(oldObject.cell, oldObject.position, oldObject.rotation)
    oldObject:remove()
end

local function getFatigueTerm(actor)
    local max = types.Actor.stats.dynamic.fatigue(actor).base + types.Actor.stats.dynamic.fatigue(actor).modifier
    local current = types.Actor.stats.dynamic.fatigue(actor).current

    local normalised = math.floor(max) == 0 and 1 or math.max(0, current / max)

    local fFatigueBase = core.getGMST("fFatigueBase")
    local fFatigueMult = core.getGMST("fFatigueMult")

    return fFatigueBase - fFatigueMult * (1 - normalised)
end

local function getBarterOffer(npc, basePrice, disposition, buying)
    local disposition = 50

    local player = world.players[1]
    local playerMerc = types.NPC.stats.skills.mercantile(player).modified

    local playerLuck = types.Actor.stats.attributes.luck(player).modified
    local playerPers = types.Actor.stats.attributes.personality(player).modified

    local playerFatigueTerm = getFatigueTerm(player)
    local npcFatigueTerm = getFatigueTerm(npc)

    -- Calculate the remaining parts of the function using the provided variables/methods
    local clampedDisposition = disposition
    local a = math.min(playerMerc, 100)
    local b = math.min(0.1 * playerLuck, 10)
    local c = math.min(0.2 * playerPers, 10)
    local d = math.min(types.NPC.stats.skills.mercantile(npc).modified, 100)
    local e = math.min(0.1 * types.Actor.stats.attributes.luck(npc).modified, 10)
    local f = math.min(0.2 * types.Actor.stats.attributes.personality(npc).modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * playerFatigueTerm
    local npcTerm = (d + e + f) * npcFatigueTerm
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.floor(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end
local function advanceDays(days)
    world.mwscript.getGlobalVariables().dayspassed = world.mwscript.getGlobalVariables().dayspassed + days
    world.mwscript.getGlobalVariables().day = world.mwscript.getGlobalVariables().day + days
end

local function AdvanceTime(hours)
    local currentHour = world.mwscript.getGlobalVariables().gamehour

    if currentHour + hours > 24 then
        local remainder = currentHour + hours - 24
        local daysToAdd = math.floor((currentHour + hours) / 24)
        world.mwscript.getGlobalVariables().dayspassed = world.mwscript.getGlobalVariables().dayspassed + daysToAdd
        world.mwscript.getGlobalVariables().day = world.mwscript.getGlobalVariables().day + daysToAdd

        while remainder >= 24 do
            remainder = remainder - 24
        end

        world.mwscript.getGlobalVariables().gamehour = remainder
    else
        world.mwscript.getGlobalVariables().gamehour = currentHour + hours
    end
end

return {
    interfaceName  = "ZackUtils" .. interfaceModifier,
    interface      = {
        version = 1,
        getBarterOffer = getBarterOffer,
        CONSOLE_COLOR = CONSOLE_COLOR,
        createContainerFilledWithType = createContainerFilledWithType,
        indexCells = indexCells,
        getInventory = getInventory,
        getObjectAngle = getObjectAngle,
        teleportOutsideCell = teleportOutsideCell,
        teleportToExt = teleportToExt,
        ZackUtilsCreateInterface = ZackUtilsCreateInterface,
        cellCopy = cellCopy,
        ZackUtilsDelete = ZackUtilsDelete,
        printToConsole = printToConsole,
        genTravelData = genTravelData,
        getCellNameByPos = getCellNameByPos,
        findNPCInWorld = findNPCInWorld,
        matchNPCCells = matchNPCCells,
        cellScan = cellScan,
        findNPCInterior = findNPCInterior,
        getCellByPos = getCellByPos,
        getPlayer = getPlayer,
        findInWorld = findInWorld,
        printToTerminal = printToTerminal,
        help = help,
        calculateBoxCenter = calculateBoxCenter,
        addNumbers = addNumbers,
        findObjectType = findObjectType,
        findObjectRecord = findObjectRecord,
        renameActivator = renameActivator,
        distanceBetweenPos = distanceBetweenPos,
        showMessage = showMessage,
        playSound = playSound,
        deleteById = deleteById,
        findByRecordId = findByRecordId,
        findObjectRecordByName = findObjectRecordByName,
        getPlayerInventory = getPlayerInventory,
    },
    eventHandlers  = {
        AdvanceTime = AdvanceTime,
        ZackUtilsAddItem_AA = ZackUtilsAddItem,
        ZackUtilsPauseWorld_AA = ZackUtilsPauseWorld,
        ZackUtilsTeleport_AA = ZackUtilsTeleport,
        teleportToExtEvent_AA = teleportToExtEvent,
        moveToActorEvent_AA = moveToActorEvent,
        ZackUtilsDelete_AA = ZackUtilsDelete,
        ZackUtilsCreate_AA = ZackUtilsCreate,
        cellScan_AA = cellScan,
        replaceOb_AA = replaceOb,
        ZackUtilsTeleportToCell_AA = ZackUtilsTeleportToCell,
        activateThingEvent_AA = activateThingEvent,
        removeItemCount_AA = removeItemCount,
        ZackUtilsAddItems_AA = ZackUtilsAddItems,
        setDisabled_AA = setDisabled,
        ZackUtilsEmptyInto_AA = ZackUtilsEmptyInto,
        createContainerFilledWithType_AA = createContainerFilledWithType,
        setPos_AA = setPos,
        setGameTime_AA = setGameTime,
        playSound_AA = playSound,
    },
    engineHandlers = { onInit = onInit, onLoad = onInit }
}
