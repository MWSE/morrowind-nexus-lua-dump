local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local function getInventory(object)
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        print("actor")
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
    print("no?")
end
local function indexCells(cellname)
    for x = -100, 100 do
        for y = -100, 100 do
            local cell = world.getExteriorCell(x, y)
            local doors = cell:getAll(types.Door)
            for i, record in ipairs(doors) do
                if (types.Door.isTeleport(record) and types.Door.destCell(record).name == cellname) then
                    print(types.Door.destCell(record).name)
                end
            end
        end
    end
end
local function PlaceInFrontTest(obj)
    -- Define the position and rotation vectors
    local position = util.vector3(obj.position.x, obj.position.y, obj.position.z)
    local rotation = util.vector3(obj.rotation.x, obj.rotation.y, obj.rotation.z)

    -- Calculate the direction vector based on the rotation
    local direction = util.vector3(
        math.sin(rotation.z),
        math.cos(rotation.z),
        0
    )

    -- Calculate the new position based on the direction and distance
    local distance = 1000
    local newPosition = position + (direction * distance)

    -- Place the object at the new position
    obj:teleport(obj.cell, newPosition)
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
local function createObjectAtPosition(refId, cell, position, rotation)

end
local function activateThing(source, target)
    target:activateBy(source)
end
local function activateThingEvent(data)
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
local function findNPCInterior(targetName)
    for i, cellName in ipairs(interfaces.CellList.cellList) do --find the doors inside so we can get back to the outside
        local scell = world.getCellByName(cellName)
        local sactors = scell:getAll(types.NPC)
        for i, record in ipairs(sactors) do --find the doors inside so we can get back to the outside
            if (record.recordId == targetName:lower()) then
                return record
            end
        end
    end
end
local function findNPCInWorld(targetName) --need to do a ray cast if no int cell is found
    for x = -100, 100 do
        for y = -100, 100 do
            local cell = world.getExteriorCell(x, y) --get all ext cells
            local npcs = cell:getAll(types.NPC)
            for i, record in ipairs(npcs) do         --find the doors inside so we can get back to the outside
                if (record.recordId == targetName:lower()) then
                    return record
                end
            end
        end
    end
    return nil
end
local function moveToActor(objectToTeleport, targetName) --need to do a ray cast if no int cell is found
   local target = findNPCInWorld(targetName)

   if(target == nil) then
    

    target = findNPCInterior(targetName)
   end

    if(target ~= nil) then
    
        local destPos = target.position
        local destRot = target.rotation
        local destCell = target.cell
        objectToTeleport:teleport(destCell, destPos, destCell)
   end
end
local function cellScan(cellName, type)
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
    local cellSize = 8192
    local cellX = math.floor(position.x / cellSize)
    local cellY = math.floor(position.y / cellSize)

    return world.getExteriorCell(cellX, cellY).name
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
    moveToActor(data.objectToTeleport, data.targetName)
end
local function teleportToExtEvent(data)
    teleportToExt(data.objectToTeleport, data.cellname)
end
local function ZackUtilsTeleport(data)
    if (data.item == nil) then
        return
    end

    data.item:teleport(data.item.cell, data.position, data.rotation)
end


local function ZackUtilsTeleportToCell(data)
    if (data.item == nil) then
        return
    end

    data.item:teleport(world.getCellByName(data.cellname), data.position, data.rotation)
end

local function matchNPCCells()
    local table = interfaces.TravelWindow_Data.travelData


    for i, item in ipairs(interfaces.TravelWindow_Data.travelData) do
        local npcId = item.ID
        if (item.class == "guild guide") then
            local npcRecord = interfaces.ZackUtilsG.findNPCInterior(npcId)

            if (npcRecord == nil) then
                print("Not found: " .. npcId)
            end
        else
            local npcRecord = interfaces.ZackUtilsG.findNPCInWorld(npcId)

            if (npcRecord == nil) then
                print("Not found: " .. npcId)
            end
        end
    end
end


local function genTravelData()
    for i, record in ipairs(types.NPC.records) do
        local myCell = ""
        local myRef = nil
        local myPos = {x = 0,y = 0,z = 0}

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


local function ZackUtilsCreate(data)
    local item = world.createObject(data.itemid)
    item:teleport(world.getCellByName(data.cell), data.position, data.rotation)
    data.player:sendEvent("createItemReturn", item)
end
local function printToConsole(message)
    for i, ref in ipairs(world.activeActors) do
        if (ref.type == types.Player) then
            ref:sendEvent("printToConsoleEvent", message)
        end
    end
end
local function ZackUtilsCreateInterface(itemid, cellname, position, rotation)
    if (itemid == nil) then
        printToConsole("Usage for this function: (itemid(string),cellname(string),position(vec3),rotation(vec3))")
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
        data:remove()
    end
end
local function removeItemCount(data)
    if (data.itemId ~= nil and data.count > 0) then
        local inv = types.Actor.inventory(data.actor)
        local item = inv:find(data.itemId)

        item:remove(data.count)
    end
end
local function ZackUtilsAddItem(data)
    local item = world.createObject(data.itemId, data.count)
    print(data.actor.recordId)
    local inv = getInventory(data.actor)
    item:moveInto(types.Actor.inventory(data.actor))
    if (data.equip == true) then
        data.actor:sendEvent("addItemEquipReturn", item)
    end
end
local function ZackUtilsPauseWorld(doPause)
    if (doPause) then
        world.setSimulationTimeScale(0)
    else
        world.setSimulationTimeScale(1)
    end
end
local function createContainerFilledWithType(type, actor)
    local container = world.createObject("de_r_chest_01_empty")
    local records = type.records
    for i, record in ipairs(records) do
        local object = world.createObject(record.id, 1)
        object:moveInto(types.Container.content(container))
    end
    container:teleport(actor.cell, actor.position, util.vector3(0, 0, 0))
end


return {
    interfaceName = "ZackUtilsG",
    interface     = {
        version = 1,
        createContainerFilledWithType = createContainerFilledWithType,
        indexCells = indexCells,
        teleportOutsideCell = teleportOutsideCell,
        teleportToExt = teleportToExt,
        ZackUtilsCreateInterface = ZackUtilsCreateInterface,
        cellCopy = cellCopy,
        ZackUtilsDelete = ZackUtilsDelete,
        printToConsole = printToConsole,
        PlaceInFrontTest = PlaceInFrontTest,
        genTravelData = genTravelData,
        getCellNameByPos = getCellNameByPos,
        findNPCInWorld = findNPCInWorld,
        matchNPCCells = matchNPCCells,
        cellScan = cellScan,
        findNPCInterior = findNPCInterior,
    },
    eventHandlers = {
        ZackUtilsAddItem = ZackUtilsAddItem,
        ZackUtilsPauseWorld = ZackUtilsPauseWorld,
        ZackUtilsTeleport = ZackUtilsTeleport,
        teleportToExtEvent = teleportToExtEvent,
        moveToActorEvent = moveToActorEvent,
        ZackUtilsDelete = ZackUtilsDelete,
        ZackUtilsCreate = ZackUtilsCreate,
        cellScan = cellScan,
        ZackUtilsTeleportToCell = ZackUtilsTeleportToCell,
        activateThingEvent = activateThingEvent,
        removeItemCount = removeItemCount,
    },
}
