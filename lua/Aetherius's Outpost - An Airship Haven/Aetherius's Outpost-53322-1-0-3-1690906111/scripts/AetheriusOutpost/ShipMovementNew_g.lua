local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local shipData = {}
local shipObjects = {}
local shipObjectIds = {
    ["ab_ex_impgalleonfullunfurled"] = "ab_ex_impgalleonfullunfurled",
    ["zhac_dsub_full"] = "zhac_dsub_full",
    ["ex_de_ship"] = "ex_de_ship",
    ["ab_ex_impgalleonfullfurled"] = "ab_ex_impgalleonfullfurled",
    ["zhac_dship_x"] = "zhac_dship_x",
    ["ex_longboat"] = "ex_longboat",
    ["ab_ex_deshipsmall"] = "ab_ex_deshipsmall",
    ["zhac_silvercascade_ship"] = "zhac_silvercascade_ship",
}
local function getPlayer()
    return world.players[1]
end
local function getMainShipOb(objectList)
    for index, value in ipairs(objectList) do
        if shipObjectIds[value.recordId] then
            return value
        end
    end
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ((z))
        return rotate
    end
end
local shipCheck = nil
local countDown = 0
local function ShipHit()
    if shipCheck and I.AOutpost_ShipManage.getShipCollideDisable(shipCheck) then
        I.AOutpost_ShipManage.arrestMovement(shipCheck)
        countDown = 5
    end
    shipCheck = nil
end
local function onUpdate(dt)
    if countDown > 0 then
        countDown = countDown - dt
    end
end
local markerData = {}
local function onSave()
    return { markerData = markerData }
end
local function onLoad(data)
    if not data then return end
    if not data.markerData then return end
    markerData = data.markerData
end
local function setPlayerPosition(pos, rotZ)
    local scr = world.mwscript.getGlobalScript("zhac_airship_setppos", getPlayer())
    scr.variables.px = pos.x
    scr.variables.py = pos.y
    scr.variables.pz = pos.z
    scr.variables.pr = math.deg(rotZ)
    scr.variables.domove = 1
end
local markerIdList = { zhac_sc_exitmarker_cabinm = true, zhac_sc_exitmarker_cabinr = true,
    zhac_sc_exitmarker_cabinl = true, zhac_sc_exitmarker_main = true, zhac_sw_exitmarker = true }
local function setMarkerPosition(object)
    markerData[object.recordId] = { cellName = object.cell.name, position = object.position, rotation = object.rotation }
end
local function getMarkerPosition(recordId)
    return markerData[recordId]
end
local TPedObjects = {}
local function teleportObject(cell, rot, pos, ob)
    if markerIdList[ob.recordId] then
        setMarkerPosition(ob)
    end
    if TPedObjects[ob.id] then return end
    if ob == getPlayer() and cell.worldSpaceId == ob.cell.worldSpaceId then
        -- if setPlayerPosition ~= nil then
        local rz = 0
        if rot then
            rz = rot:getAnglesZYX()
        else
            rz = getPlayer().rotation:getAnglesZYX()
        end
        setPlayerPosition(pos, rz)
        return

        -- end
    end
    if shipObjectIds[ob.recordId] then
        I.AOutpost_ShipManage.updateShipCell(ob, cell)
    end
    TPedObjects[ob.id] = true
    if not rot then
        ob:teleport(cell, pos)
        return
    end
    ob:teleport(cell, pos, rot)
    --shipObjects[i]:setRotation(rotation)
    --shipObjects[i]:setPosition(position)
end
local locData = {}
local function stageData(objectList)
    locData = {}
    for index, value in ipairs(objectList) do
        locData[value.id] = { object = value, rotation = object.rotation, position = object.position }
    end
    if I.AOutpost_ShipManage.getPlayerShip() == getMainShipOb(objectList).id then
        locData[getPlayer().id] = {
            object = getPlayer(),
            rotation = getPlayer().rotation,
            position = getPlayer().position
        }
    end
end

local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end
local function moveAirship(objectList, mainObject, position, rotationZ, newCell)
    if not rotationZ then
        rotationZ = 0
    end
    stageData(objectList)

    local rot = createRotation(0, 0, rotationZ)
    --airshipOb = ob
    if I.AOutpost_ShipManage.getPlayerShip() == mainObject.id then
        local value = getPlayer()
        teleportObject(newCell, value.rotation, value.position - mainObject.position + position, value)
    end
end
local function rotateAndMoveAirship(objectList, mainObject, degrees, newPosition, rotationZ, doEvent, newCell)
    if countDown ~= 0 and countDown > 4 then
        return
    end
    --local rot = createRotation(0, 0, rotationZ)
    -- airshipOb = ob
    local newPos = {}
    local obList = {}
    TPedObjects = {}
    for index, value in ipairs(objectList) do
        table.insert(obList, value)
    end
    if I.AOutpost_ShipManage.getPlayerShip() == mainObject.id then
        table.insert(obList, getPlayer())
    end
    -- airshipOb:teleport("", position, rot)
    --player:teleport("", util.vector3(position.x, position.y, position.z - 340), rot)
    --player:teleport(player.cell.name, (player.position - airshipOb.position) + position)
    if newCell then
        if newCell.name == nil then
            newCell = world.getCellByName(newCell)
        end
        for index, value in ipairs(obList) do
            --  value:setPosition(value.position - airshipOb.position + position)

            teleportObject(newCell, nil, (value.position - mainObject.position) + newPosition, value)
            -- value:teleport(newCell, (value.position - mainObject.position) + newPosition)
        end
        return
    end
    if not newCell then
        newCell = mainObject.cell
    end
    for index, value in ipairs(obList) do
        newPos[value.id] = (value.position - mainObject.position + newPosition)
        --   value:teleport("", (value.position - airshipOb.position) + position)
    end
    local collisionCheck = {}
    if degrees == 0 then
        for index, value in ipairs(obList) do
            teleportObject(newCell, nil, newPos[value.id], value)
            collisionCheck[value.recordId] = value.position
        end
        shipCheck = mainObject.id
        world.players[1]:sendEvent("collisionCheck", collisionCheck)
    else
        local angle = math.rad((degrees))
        local recordId = mainObject.recordId
        -- Find the object with the specified recordId and calculate its position
        local center = newPos[mainObject.id]


        -- Calculate the total offset of all objects from the center
        local totalOffset = util.vector3(0, 0, 0)
        for i = 1, #obList do
            totalOffset = totalOffset + (newPos[obList[i].id] - center)
        end

        -- Calculate the average position of all objects
        local averagePosition = center -- + (totalOffset / #shipObjects)

        -- Rotate each object around the average position
        for i = 1, #obList do
            -- Calculate the relative position of the object to the average position
            local relativePosition = newPos[obList[i].id] - averagePosition
            local x = relativePosition.x * math.cos(angle) - relativePosition.y * math.sin(angle)
            local y = relativePosition.x * math.sin(angle) + relativePosition.y * math.cos(angle)
            local position = util.vector3(x + averagePosition.x, y + averagePosition.y, newPos[obList[i].id].z)

            -- Calculate the new rotation
            local rz, ry, rx = obList[i].rotation:getAnglesZYX()
            local rotation = createRotation(rx, ry, rz - angle)


            if obList[i]:isValid() then
                -- Move the object
                teleportObject(newCell, rotation, position, obList[i])
                if startsWith(obList[i].recordId, "zhac_collisionchecker_") then
                    obList[i]:setScale(0)
                    collisionCheck[obList[i].recordId] = position
                end
            end
        end
        world.players[1]:sendEvent("collisionCheck", collisionCheck)
    end
    --doRot = true
    -- if doEvent then
    -- getPlayer():sendEvent("POVAirship")
    -- end
end
local function rotateObjects(objectList, mainObject, degrees)
    local shipObjects = {}
    for index, value in ipairs(objectList) do
        table.insert(shipObjects, value)
    end
    if I.AOutpost_ShipManage.getPlayerShip() == mainObject.id then
        table.insert(shipObjects, getPlayer())
    end
    local angle = math.rad((degrees))
    local recordId = mainObject.recordId
    -- Find the object with the specified recordId and calculate its position
    local center = mainObject.position


    -- Calculate the total offset of all objects from the center
    local totalOffset = util.vector3(0, 0, 0)
    for i = 1, #objectList do
        totalOffset = totalOffset + (shipObjects[i].position - center)
    end

    -- Calculate the average position of all objects
    local averagePosition = center -- + (totalOffset / #shipObjects)

    -- Rotate each object around the average position
    for i = 1, #objectList do
        -- Calculate the relative position of the object to the average position
        local relativePosition = shipObjects[i].position - averagePosition
        local x = relativePosition.x * math.cos(angle) - relativePosition.y * math.sin(angle)
        local y = relativePosition.x * math.sin(angle) + relativePosition.y * math.cos(angle)
        local position = util.vector3(x + averagePosition.x, y + averagePosition.y, shipObjects[i].position.z)

        -- Calculate the new rotation
        local rz, ry, rx = objectList[i].rotation:getAnglesZYX()
        local rotation = createRotation(rx, ry, rz - angle)


        if objectList[i]:isValid() then
            -- Move the object
            teleportObject(rotation, position, shipObjects[i])
        end
    end
end
local function moveAirshipVert(objectList, mainObject, dist)
    local newLocation = util.vector3(mainObject.position.x, mainObject.position.y, mainObject.position.z + dist)
    moveAirship(objectList, mainObject, newLocation)
end
local function moveAirshipVertDown(objectList, mainObject, dist)
    local newLocation = util.vector3(mainObject.position.x, mainObject.position.y, mainObject.position.z - dist)
    moveAirship(objectList, mainObject, newLocation)
end
local markerIdList = { zhac_sc_exitmarker_cabinm = true, zhac_sc_exitmarker_cabinr = true,
    zhac_sc_exitmarker_cabinl = true, zhac_sc_exitmarker_main = true, zhac_sw_exitmarker = true }

local doorActivateMap = { zhac_door_impgalleon01_r = "zhac_sc_exitmarker_cabinl",
    zhac_door_impgalleon01_l = "zhac_sc_exitmarker_cabinr", zhac_door_impgalleon01_m = "zhac_sc_exitmarker_cabinm",
    zhac_door_impgalleon02_in = "zhac_sc_exitmarker_main", zhac_sw_exitdoor = "zhac_sw_exitmarker" }
local function onActivate(object, actor)
    if doorActivateMap[object.recordId] then
        local tpData = getMarkerPosition(doorActivateMap[object.recordId])
        actor:teleport(tpData.cellName, tpData.position, { rotation = tpData.rotation, onGround = true })
        for index, value in ipairs(world.activeActors) do
            
            if value ~= world.players[1] then
                value:sendEvent("AO_teleportFollower",
                    { destPos = tpData.position, destCell = tpData.cellName, destRot = tpData.rotation })
            end
        end
    end
    if object.recordId == "zhac_ae_compass_silver" or object.recordId == "zhac_ae_compass_steam" then
        actor:sendEvent("compassActivate",object.recordId)
    end
end
return {
    interfaceName  = "AOutpost_ShipMovement",
    interface      = {
        version = 1,
        moveAirship = moveAirship,
        moveAirshipVert = moveAirshipVert,
        moveAirshipVertDown = moveAirshipVertDown,
        rotateObjects = rotateObjects,
        rotateAndMoveAirship = rotateAndMoveAirship,
        getMarkerPosition = getMarkerPosition,
        setMarkerPosition = setMarkerPosition
    },
    engineHandlers = {
        onActorActive = onActorActive,
        onObjectActive = onObjectActive,
        onLoad = onLoad,
        onUpdate = onUpdate,
        onSave = onSave,
        onActivate = onActivate,
    },
    eventHandlers  = {
        ShipHit = ShipHit,
    },
}
