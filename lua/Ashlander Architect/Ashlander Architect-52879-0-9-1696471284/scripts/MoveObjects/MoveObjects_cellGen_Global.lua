local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local acti = require("openmw.interfaces").Activation


local myModData = storage.globalSection("MoveObjectsCellGen")
local settlementModData = storage.globalSection("AASettlements")
local playerActor
local generatedStructures = {}
local nowData
local prefabDatas = nil

local currentData = nil
local objectList

local function renameCellLabel(data)
    local text = data.text
    local context = data.context
    local doorID = data.doorID
    for x, structure in ipairs(generatedStructures) do
        if (structure.InsideDoorID == doorID) then
            if (context == "InsideCellLabel") then
                generatedStructures[x].InsideCellLabel = text
            else
                generatedStructures[x].OutsideCellLabel = text
            end
        end
    end
    myModData:set("generatedStructures", generatedStructures)
end
local function trim(s)
    return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)'
end
local function DeletePlacedObject(data)
    local object = data.object
    local settlementId = data.settlementId
    if (settlementId) then
        I.AA_Settlements.removeBedId(settlementId, object.id)
    end

    object:remove()
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

local function buildNewHouse(prefab, ExtdoorRef, player, prefabIndex)
    local xposOffset = prefabDatas[prefabIndex].currentCount
    playerActor = player
    prefabDatas[prefabIndex].currentCount = prefabDatas[prefabIndex].currentCount + 1

    nowData = {
        OutsideCellExt = false,             --wordspace coords if outside is an exterior
        OutsideCellInt = "",                --cell name if outside is an interior
        InsideCellName = "",                --cell that the house is in
        InsideDoorID = "",                  --ID of the door that exits the house
        OutsideDoorID = "",                 --ID of the door that enters the house
        OutsidePos = util.vector3(0, 0, 0), --Where the player is teleported when extiing the house
        InsidePos = util.vector3(0, 0, 0),  --where the player is teleported when entering the house
        OutsideZRot = 0,                    --Where the player is rotated to when exiting the house
        InsideZRot = 0,                     --where the player is rotated to when entering the house
        InsideCellLabel = "",
        OutsideCellLabel = "",
        settlementId = "",
        OutsideWorldSpaceID = "",


    }
    local zpos = 0
    if (player.position.z < 0) then
        zpos = -40000
    end
    nowData.InsideCellLabel = prefab.targetCell
    if (player.cell.isExterior) then
        nowData.OutsideCellExt = true
        if (player.cell.name == "") then
            nowData.OutsideCellLabel = formatRegion(player.cell.region)
            print("Checking settlements")
            for x, structure in ipairs(settlementModData:get("settlementList")) do
                print("Found one")
                local dist = math.sqrt((player.position.x - structure.settlementCenterx) ^ 2 +
                    (player.position.y - structure.settlementCentery) ^ 2 +
                    (player.position.z - structure.settlementCenterz) ^ 2)
                print(dist)
                if (dist < structure.settlementDiameter / 2) then
                    nowData.settlementId = structure.markerId
                    nowData.OutsideCellLabel = structure.settlementName
                    nowData.InsideCellLabel = structure.settlementName .. ", " .. prefab.targetCell
                end
            end
        else
            nowData.InsideCellLabel = player.cell.name .. ", " .. prefab.targetCell
            nowData.OutsideCellLabel = player.cell.name
        end
        nowData.OutsideWorldSpaceID = player.cell.worldSpaceId
    else
        nowData.OutsideCellInt = player.cell.name
        nowData.OutsideCellLabel = player.cell.name
    end
    currentData = prefab
    nowData.InsideCellName = prefab.targetCell
    nowData.OutsideDoorID = ExtdoorRef.id
    print(prefab.baseCell, prefab.targetCell)
    objectList = I.ZackUtilsAA.cellCopy(prefab.baseCell, prefab.targetCell, util.vector3(0, 100000 * xposOffset, zpos),
        player)
    myModData:set("generatedStructures")
end

local function getPositionBehind(pos, rot, distance, direction)
    local currentRotation = -rot.z
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
local function onUpdate()
    if (generatedStructures == nil) then
        generatedStructures = {}
    end

    if (myModData:get("generatedStructures") == nil) then
        myModData:set("generatedStructures", generatedStructures)
    end
    if (prefabDatas == nil) then
        prefabDatas = {
            {
                name = "Longhouse",
                baseCell = "AAIntLongH",
                targetCell = "Longhouse",
                currentCount = 0,
                fullObjectId = "a_zh_b_longhouse_pre",
                ExtAct = "a_zh_b_longhouse_done",
                ExtDoor = "a_zh_b_longhouse_door",
                IntDoor = "ZHAC_In_S_doorAct",
                doorSound = "door heavy open"
            },
            {
                name = "Breezehome",
                baseCell = "WhiterunBreezehome",
                targetCell = "Infinite Abyss",
                currentCount = 0,
                fullObjectId = "FormId:0x402ac8b",
                ExtAct = "FormId:0x402ac8b",
                ExtDoor = "FormId:0x4024e26",
                IntDoor = "FormId:0x4024e26",
                DoorEast = 180,
                DoorNorth = 25,
                doorSound = "door heavy open"
            },
            {
                name = "Velothi Manor",
                baseCell = "AAIntVeloManor",
                targetCell = "Velothi Manor",
                currentCount = 0,
                fullObjectId = "a_zh_b_velothimanorpre",
                ExtAct = "a_zh_b_velothimanor",
                ExtDoor = "a_zh_b_velothimanorextdoor",
                IntDoor = "a_zh_b_velothimanor_intdooract",
                doorSound = "door heavy open"
            },
            {
                name = "Velothi House",
                baseCell = "AAInt VeloShack",
                targetCell = "Velothi Small House",
                currentCount = 0,
                fullObjectId = "a_zh_b_velothihouse_01Pre",
                ExtAct = "a_zh_b_velothihouse_01",
                ExtDoor = "a_zh_b_velothihouse_01doorext",
                IntDoor = "a_zh_b_velothihouse_intdooract",
                doorSound = "door heavy open"
            },
            {
                name = "Redoran Manor",
                baseCell = "AAIntREdoranManor",
                targetCell = "Redoran Manor",
                currentCount = 0,
                fullObjectId = "a_zh_b_RedoranManor_01",
                ExtAct = "a_zh_b_RedoranManor_01_nodoor",
                ExtDoor = "a_zh_b_RedoranManor_01_door",
                IntDoor = "a_zh_b_redoranmanor_doorIntAct",
                doorSound = "door heavy open"
            },
            {
                name = "Redoran Hut",
                baseCell = "AAIntREdoranHut",
                targetCell = "Redoran Hut",
                currentCount = 0,
                fullObjectId = "a_zh_b_RedoranHutPre",
                ExtAct = "a_zh_b_RedoranHut",
                ExtDoor = "a_zh_b_RedoranHutDoor",
                IntDoor = "zhac_redoranHut_intDoor",
                doorSound = "door heavy open"
            },
            {
                name = "Redoran Grand Hall",
                baseCell = "AAInt_RedoranHall",
                targetCell = "Redoran Grand Hall",
                currentCount = 0,
                fullObjectId = "a_zh_b_RedoranHall_Full",
                ExtAct = "a_zh_b_RedoranHall_Act",
                ExtDoor = "a_zh_b_RedoranHall_Door",
                IntDoor = "zhac_redoranHall_intDoor",
                doorSound = "door heavy open"
            },
            {
                name = "Ashlander Tent",
                baseCell = "AAIntTent",
                targetCell = "Ashlander Tent",
                currentCount = 0,
                fullObjectId = "a_zh_b_ashltent_01_pre",
                ExtAct = "a_zh_b_ashltent_01",
                ExtDoor = "a_zh_b_ashltent_01_door",
                IntDoor = "zhac_ashlanderdoorInt",
                doorSound = "door heavy open"
            },
            {
                name = "Hlaalu House",
                baseCell = "AAIntBalmoraShack",
                targetCell = "Hlaalu House",
                currentCount = 0,
                fullObjectId = "a_zh_b_HlaaluHouse_01",
                ExtAct = "a_zh_b_HlaaluHouse_01Done",
                ExtDoor = "a_zh_b_HlaaluHouse_01ExtDoor",
                IntDoor = "ZHAC_HlaaluIntDoor",
                doorSound = "door heavy open"
            },
            {
                name = "Hlaalu Manor",
                baseCell = "AAIntHlaaluManor",
                targetCell = "Hlaalu Manor",
                currentCount = 0,
                fullObjectId = "a_zh_b_HlaaluManor_01",
                ExtAct = "a_zh_b_HlaaluManor_01Done",
                ExtDoor = "a_zh_b_HlaaluManor_01ExtDoor",
                IntDoor = "ZHAC_HlaaluIntDoor"
            },
            {
                name = "Imperial House",
                baseCell = "AAIntImpHouse",
                targetCell = "Imperial House",
                currentCount = 0,
                fullObjectId = "a_zh_b_imphouse",
                ExtAct = "a_zh_b_imphouseDone",
                ExtDoor = "a_zh_b_imphouse_doorext",
                IntDoor = "zhac_imphouse_intDoor"
            },
            {
                name = "Telvanni Pod House",
                baseCell = "AAIntTelPod",
                targetCell = "Mushroom House",
                currentCount = 0,
                fullObjectId = "zhac_mushroomhouse_full",
                ExtAct = "zhac_mushroomhouse_NoDoor",
                ExtDoor = "zhac_mushroomhouse_Door",
                IntDoor = "zhac_mushroomhouse_intdoor"
            },
        }
    end

    if (objectList == nil) then
        return
    end
    for i, object in ipairs(objectList) do
        if (object.position.z == 0) then
            return
        end
       -- print(object.recordId, object.cell.name, object.position, object.rotation)
        if (object.recordId:lower() == currentData.IntDoor:lower()) then
            print(object.id .. " door")
            nowData.InsideDoorID = object.id
            object.enabled = true
          --  local insidePos = getPositionBehind(object.position,object.rotation,50,"west")
          if not  nowData.InsidePos then
            nowData.InsidePos = util.vector3(object.position.x, object.position.y, object.position.z)
          end
        elseif (object.recordId == "a_zh_b_entermarker") then
            nowData.InsidePos = util.vector3(object.position.x, object.position.y, object.position.z)
            nowData.InsideZRot = I.ZackUtilsAA.getObjectAngle(object).z
            object:remove() --don't need this anymore, it's ugly
           -- print(nowData.InsideCellName, nowData.InsidePos)
            -- playerActor:teleport(world.getCellByName(nowData.InsideCellName), nowData.InsidePos)
        end
    end
    table.insert(generatedStructures, nowData)
    myModData:set("generatedStructures", generatedStructures)
    objectList = nil
end
local function ZackUtilsCreateInterface(itemid, cellname, position, rotation)
    local item = world.createObject(itemid)
    item:teleport(world.getCellByName(cellname), position, rotation)
    return item
end
local function activateActivator(object, actor)
    if (object == nil) then
        return
    end
    for i, prefab in ipairs(prefabDatas) do
        if (prefab.fullObjectId:lower() == object.recordId:lower()) then --this is the placed object, need to convert it to the door and building
            ZackUtilsCreateInterface(prefab.ExtAct, object.cell.name, object.position, object.rotation)
            print("Door creating")
            local doorPos = object.position
            if (prefab.DoorEast ~= nil) then
                doorPos = getPositionBehind(
                    getPositionBehind(doorPos, util.vector3(0, 0, I.ZackUtilsAA.getObjectAngle(object).z), prefab.DoorNorth, "north"),
                    util.vector3(0, 0,I.ZackUtilsAA.getObjectAngle(object).z), prefab.DoorEast, "east")

                doorPos = util.vector3(doorPos.x, doorPos.y, doorPos.z + 220)
            end
            local doorRot =  object.rotation-- util.vector3(0, 0, object.rotation.z - math.rad(-180))
            local newDoor = ZackUtilsCreateInterface(prefab.ExtDoor, object.cell.name, doorPos,
              doorRot)
            print(newDoor.id)
            buildNewHouse(prefab, newDoor, actor, i)
            if (object) then
                object:remove()
            end
            return false
        end
        if (prefab.ExtDoor:lower() == object.recordId:lower()) then --this is the exterior door, that should move us into the house
            for x, structure in ipairs(generatedStructures) do
                if (structure.OutsideDoorID == object.id) then
                    if (generatedStructures[x].OutsideZRot == 0) then
                        generatedStructures[x].OutsidePos = actor.position
                        generatedStructures[x].OutsideZRot = I.ZackUtilsAA.getObjectAngle(actor).z - math.rad(180)
                    end

                    actor:teleport(structure.InsideCellName, structure.InsidePos,
                        {
                            rotation = util.transform.rotateZ(structure
                                .InsideZRot),
                            onGround = true
                        })
                end
            end

            return false
        end
    end
    print("Found Nothing")
end
local function exitBuildMode(data)
    activateActivator(data.placedItem, data.player)
end
local function activateDoor(object, actor)
    print(object.recordId)
    for i, prefab in ipairs(prefabDatas) do
        if (prefab.IntDoor:lower() == object.recordId:lower()) then --this is the exterior door, that should move us into the house
            
            for x, structure in ipairs(generatedStructures) do
                if (structure.InsideDoorID == object.id and structure.OutsideCellExt) then
                    local extCellName = ""
                   
                    if(structure.OutsideWorldSpaceID ~= nil and structure.OutsideWorldSpaceID ~= "sys::default") then
                        extCellName = structure.OutsideWorldSpaceID
                    end
                    actor:teleport(extCellName, structure.OutsidePos, util.transform.rotateZ( structure
                        .OutsideZRot))
                elseif (structure.InsideDoorID == object.id and structure.OutsideCellExt == false) then
                    actor:teleport(structure.OutsideCellInt, structure.OutsidePos, util.transform.rotateZ( structure
                        .OutsideZRot))
                end
            end

            return false
        end
    end
end
local function InsideDoorActivate(data)
    local player = data.player
    local door = data.door
    activateDoor(door, player)
end
local function OutsideDoorActivate(data)
    local player = data.player
    local door = data.door
    activateActivator(door, player)
end
local function doorCheck(object,actor)
--return false
end
acti.addHandlerForType(types.ESM4Door, doorCheck)
acti.addHandlerForType(types.Activator, activateActivator)
--acti.addHandlerForType(types.Door, activateDoor)

local function onInit()

end
local myPlayer = nil
local function onPlayerAdded(player)
    if (myPlayer == nil) then
        myPlayer = player
    end
end
local tempActor = nil
local function onActorActive(actor)
    if (actor.recordId == ("AA_TravelCreature"):lower()) then
        for i, act in ipairs(world.activeActors) do
            if (act.recordId == "player") then
                act:sendEvent("startTravel")
                tempActor = actor
            end
        end
    end
end
local function clearTempActor()
    if (tempActor ~= nil) then
        tempActor:remove()
    end
end

local function onLoad(data)
    if (data) then
        generatedStructures = data.generatedStructures
        myModData:set("generatedStructures", generatedStructures)

        prefabDatas = data.prefabDatas
    end
end
local function onSave()
    return { generatedStructures = generatedStructures, prefabDatas = prefabDatas }
end
return {
    interfaceName = "CellGen",
    interface = {
        version = 1,
        formatRegion = formatRegion,
    },
    eventHandlers = {
        InsideDoorActivate = InsideDoorActivate,
        OutsideDoorActivate = OutsideDoorActivate,
        renameCellLabel = renameCellLabel,
        exitBuildMode = exitBuildMode,
        clearTempActor = clearTempActor,
        DeletePlacedObject = DeletePlacedObject,
    },
    engineHandlers = {
        onInit = onInit,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onActorActive = onActorActive,
        onPlayerAdded = onPlayerAdded,
    }
}
