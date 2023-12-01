local util           = require("openmw.util")
local world          = require("openmw.world")
local core           = require("openmw.core")
local types          = require("openmw.types")
local storage        = require("openmw.storage")
local interfaces     = require("openmw.interfaces")

local tempObjects    = {}
local grabbedObject  = nil
local grabbedGroup   = nil
local buildMode      = false
local placePosition  = nil
local placeRotation

local placedObjectGroupID
local swapObjectData = require("scripts.MoveObjects.Movement.objectSwap")

local structureData  = require("scripts.MoveObjects.StructureData")

local socketedPosts  = {}
local socketedSigns  = {}

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

local snapData = {
    ["furn_com_lantern_hook_02"] = {
        ids = { "light_com_lantern_02_128", "light_de_lantern_08" },
        zOffset = 2.4395751953125,
        dist = 7.7797303458507,
        direction = "north",
        minDist = 50,
        secondDest = "east",
        secondDist = 2.5

    },
    ["furn_com_rm_bar_04"] = {
        ids = { "active_com_bar_door" },
        zOffset = 30,
        dist = 28,
        direction = "north",
        minDist = 50,
        secondDest = "east",
        secondDist = 0

    },
    ["furn_de_bar_02"] = {
        ids = { "active_de_bar_door" },
        zOffset = 30,
        dist = 28,
        direction = "north",
        minDist = 50,
        secondDest = "east",
        secondDist = 0

    },
    ["furn_de_signpost_02"] = {
        ids = { "furn_banner_tavern_aldruhnskar", "furn_banner_dagoth_01", "furn_banner_dagoth_01",
            "furn_banner_hlaalu_01",
            "furn_banner_tavern_01",
            "furn_banner_temple_01",
            "furn_banner_temple_02",
            "furn_banner_temple_03",
            "furn_bannerd_alchemy_01",
            "furn_bannerd_clothing_01",
            "furn_bannerd_danger_01",
            "furn_bannerd_goods_01",
            "furn_bannerd_wa_shop_01",
            "furn_bannerd_welcome_01",
            "furn_de_banner_book_01",
            "furn_de_banner_pawn_01",
            "furn_de_banner_telvani_01" },
        zOffset = 62,
        dist = 15,
        direction = "east",
        minDist = 50

    },
    ["furn_de_signpost_04"] = {
        ids = { "furn_banner_tavern_aldruhnskar", "furn_banner_dagoth_01", "furn_banner_dagoth_01",
            "furn_banner_hlaalu_01",
            "furn_banner_tavern_01",
            "furn_banner_temple_01",
            "furn_banner_temple_02",
            "furn_banner_temple_03",
            "furn_bannerd_alchemy_01",
            "furn_bannerd_clothing_01",
            "furn_bannerd_danger_01",
            "furn_bannerd_goods_01",
            "furn_bannerd_wa_shop_01",
            "furn_bannerd_welcome_01",
            "furn_de_banner_book_01",
            "furn_de_banner_pawn_01",
            "furn_de_banner_telvani_01" },
        zOffset = -60,
        dist = 65,
        direction = "east",
        minDist = 150

    }

}
local function getSnapPostForSign(obj, destPos)
    if not obj.cell then return end
    for pindex, snaps in pairs(snapData) do
        for index, id in pairs(snaps.ids) do
            if id == obj.recordId then
                for index, post in ipairs(obj.cell:getAll()) do
                    if post.recordId == pindex then
                        local dist = math.sqrt((destPos.x - post.position.x) ^ 2 +
                            (destPos.y - post.position.y) ^ 2)
                        if dist < snaps.minDist then
                            if socketedPosts[post.id] and socketedPosts[post.id] ~= obj.id then
                            else
                                return post, snaps, dist
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function snapObjects(sign, destPos)
    local post, data, postDist = getSnapPostForSign(sign, destPos)
    if not data then return false end
    if not post then return false end
    local toPos = getPositionBehind(post.position, post.rotation:getAnglesZYX(), data.dist, data.direction)
    local zOffset = data.zOffset
    toPos = util.vector3(toPos.x, toPos.y, toPos.z + zOffset)
    if data.secondDest then
        toPos = getPositionBehind(toPos, post.rotation:getAnglesZYX(), data.secondDist, data.secondDest)
    end
    sign:teleport(post.cell, toPos, post.rotation)
    socketedPosts[post.id] = sign.id
    socketedSigns[sign.id] = post.id
    return true
end
local function clearTempObjects()
    tempObjects = {}

    grabbedObject = nil
    grabbedGroup = nil
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        return rotate
    end
end
local function updatePlayerData()
    world.players[1]:sendEvent("createItemReturn_AA", { objectList = tempObjects, mainRef = grabbedObject })
end
local function swapObjectToID(obj, newID)
    local newObj = world.createObject(newID)
    newObj:teleport(obj.cell, obj.position, obj.rotation)
    obj:remove()
end

local function swapObject(obj)
    for index, swapTable in ipairs(swapObjectData) do
        local useNext = false
        for index, id in ipairs(swapTable) do
            if useNext then
                swapObjectToID(obj, id)
                return
            end
            if id == obj.recordId then
                useNext = true
            end
        end
        if useNext then
            swapObjectToID(obj, swapTable[1])
            return
        end
    end
end

local function moveTempObjects()
    if grabbedObject and grabbedObject:isValid() then
        local cell = grabbedObject.cell
        if not cell then
            cell = world.players[1].cell
        end

        if grabbedGroup then
            local rotDiff = grabbedObject.rotation:getAnglesZYX() - placeRotation:getAnglesZYX()
            -- local rotDiff = (placeRotation:getAnglesZYX())
            if rotDiff ~= 0 then
                -- print(rotDiff)
            end
            local check = interfaces.AA_Build_Group.rotateAndMoveObjects(grabbedObject, rotDiff, placePosition)
            if check == false then
                grabbedGroup = nil
            end
            return
            -- for index, value in ipairs(grabbedGroup) do

            --value:teleport(cell, placePosition, placeRotation)
            -- end
        elseif grabbedObject and grabbedObject.count > 0 then
            local check = snapObjects(grabbedObject, placePosition)
            if not check then
                if socketedSigns[grabbedObject.id] then
                    for index, value in pairs(socketedPosts) do
                        if value == grabbedObject.id then
                            socketedPosts[index] = nil
                        end
                    end
                    socketedSigns[grabbedObject.id] = nil
                end
                -- local halfSize = grabbedObject:getBoundingBox().halfSize.x
                --placePosition = getPositionBehind(placePosition, grabbedObject.rotation:getAnglesZYX(), halfSize, "east")
                grabbedObject:teleport(cell, placePosition, placeRotation)
            end
        end
        return
    elseif grabbedObject and not grabbedObject:isValid() then
        print("Can't move this")
    end
    local player = world.players[1]
    for index, ob in ipairs(tempObjects) do
        ob:teleport(player.cell, placePosition, placeRotation)
    end
end
local waitTime = 0
local function onUpdate(dt)
    waitTime = waitTime + dt
    if buildMode and dt > 0 and #tempObjects > 0 then
        if (waitTime > 0.01) then
            waitTime = 0
            moveTempObjects()
        end
    else
        return
    end
end
local function updateTargetPos(data)
    placePosition = data.placePosition
    placeRotation = data.placeRotation

    moveTempObjects()
end
local function deleteTempObjects()
    for index, value in ipairs(tempObjects) do
        if value.count > 00 then
            value:remove()
        end
    end
    tempObjects = {}
end
local function setGrabbedObject(object, group)
    grabbedObject = object
    if group then
        grabbedGroup = group
        return
    end
    if object then
        local parentCheck = interfaces.AA_Build_Group.getParentObject(object)
        if parentCheck then
            -- grabbedObject = parentCheck
            --object = parentCheck
            --  world.players[1]:sendEvent("setSelectedObj",parentCheck)
        end
    end
    local groupcheck = interfaces.AA_Build_Group.getObjectGroupforObject(object)
    if groupcheck then
        grabbedGroup = groupcheck
    end
end
local function updateSelectedObject(data)
    local player = world.players[1]
    local recordId = data.recordId
    local pos = data.position
    local rotation = data.rotation
    if pos then
        placePosition = pos
    end
    if rotation then
        placeRotation = createRotation(0, 0, rotation)
    end
    if not placePosition then
        placePosition = player.position
    end
    if not placeRotation or placeRotation == 0 then
        placeRotation = createRotation(0, 0, 0)
    end
    deleteTempObjects()
    if not recordId then
        tempObjects = {}
        -- print("no recordID")
        updatePlayerData()
        return
    end
    if structureData[recordId] then
        tempObjects = {}
        if not structureData[recordId].ids then
            error("Missing ID list for " .. recordId)
        end
        local mainObjectId = structureData[recordId].ids[1]
        local ret, tbl, markers = interfaces.AA_Build_Group.placeObjectsForGroup(structureData[recordId], placePosition, "")
        placedObjectGroupID = recordId
        for index, value in ipairs(tbl) do
            table.insert(tempObjects, value)
        end
        setGrabbedObject(ret, tbl)
        updatePlayerData()

        return
    end
    if grabbedGroup and #grabbedGroup > 0 then
        clearTempObjects()
    end
    local newObject = world.createObject(recordId)
    setGrabbedObject(newObject)
    -- newObject:teleport(player.cell, placePosition, placeRotation)
    waitTime = 0
    table.insert(tempObjects, newObject)
    updatePlayerData()
end
local function createPermObject()
    local createdObjects = {}
    local currentSettlement
    for index, value in ipairs(tempObjects) do
        local idCheck = value.recordId
        if not idCheck then
            error("Missing ID: " .. value.recordId)
        end
        local newOb = world.createObject(idCheck)
        if not newOb then
            error("Was unable to create " .. idCheck)
        end
        print(idCheck)
        --newOb:setScale(value.scale)
        local idCheck = interfaces.AA_Build_Group.getOriginalObjectID(value)
        if idCheck then
            interfaces.AA_Build_Group.saveOriginalObjectID(newOb, idCheck)
        else
            print(value.recordId)
        end
        newOb:setScale(value.scale)
        newOb:teleport(value.cell, value.position, value.rotation)
        world.players[1]:sendEvent("permaObjectStore", newOb)
        -- core.sendGlobalEvent("exitBuildMode", { placedItem = newOb, player = world.players[1] })
        table.insert(createdObjects, newOb)
    end
    if #createdObjects > 1 and placedObjectGroupID then
         interfaces.AA_Build_Group.saveObjectGroup(createdObjects)
        interfaces.AA_CellGen_2.processNewStructure(createdObjects, placedObjectGroupID, currentSettlement)
    elseif not placedObjectGroupID then
        error("Missing placedObjectGroupID")
    end
end
local function getBuildModeState()
    return buildMode
end
local function setBuildModeState(state)
    buildMode = state
    if not state then
        deleteTempObjects()
        grabbedObject = nil
    end
    local markerScale = 0
    if state then
        markerScale = 1
    end
    for index, cellObj in ipairs(world.players[1].cell:getAll(types.Activator)) do
        for index, tableItem in ipairs(interfaces.AA_Settlements.TypeTable) do
            if cellObj.recordId == tableItem.MarkerID then
                cellObj:setScale(markerScale)
            end
        end
    end
    updatePlayerData()
end
local function onSave()
    deleteTempObjects()
    updatePlayerData()
end
return {
    interfaceName = "AA_BuildMode",
    interface = {
        version = 1,
        snapObjects = snapObjects,
        getBuildModeState = getBuildModeState,
    },
    eventHandlers = {
        deleteTempObjects = deleteTempObjects,
        setBuildModeState = setBuildModeState,
        updateSelectedObject = updateSelectedObject,
        updateTargetPos = updateTargetPos,
        createPermObject = createPermObject,
        setGrabbedObject = setGrabbedObject,
        clearTempObjects = clearTempObjects,
        swapObject = swapObject,
    },
    engineHandlers = { onSave = onSave }
}
