local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local shipObjectIds = {
    ["ab_ex_impgalleonfullunfurled"] = "ab_ex_impgalleonfullunfurled",
    ["ex_de_ship"] = "ex_de_ship",
    ["ab_ex_impgalleonfullfurled"] = "ab_ex_impgalleonfullfurled",
    ["aeth_dship_x"] = "aeth_dship_x",
    ["ex_longboat"] = "ex_longboat",
    ["ab_ex_deshipsmall"] = "ab_ex_deshipsmall",
    ["aeth_silvercascade_ship"] = "aeth_silvercascade_ship",
    ["aeth_airship3"] = "aeth_airship3"
}
if core.API_REVISION < 42 then
    error("You do not have the latest version of the OpenMW Engine")
end
local overWorldCeiling = 200000
local cellname = "Aetherveil Skies"
local shipData = {}
local bobStates = {
    waitAtTop = 0,
    descendGradually = 1,
    waitAtBot = 2,
    ascendGradually = 3
}
local playerShip = nil

local function getPlayer() return world.players[1] end
local function getMainShipOb(objectList)
  return objectList[1]
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ((z))
        return rotate
    end
end
local function transformNumber(inputNumber)
    local min = 0
    local max = 600
    local threshold = 30
    local fadeRange = 20 -- The range over which the value will gradually increase or decrease (10 units on each side of the threshold)

    if inputNumber <= min then
        return 0
    elseif inputNumber >= max then
        return 0
    elseif inputNumber >= threshold - fadeRange and inputNumber <= threshold +
        fadeRange then
        local t = (inputNumber - (threshold - fadeRange)) / (2 * fadeRange)
        return 1 - t
    elseif inputNumber >= max - fadeRange then
        local t = (inputNumber - (max - fadeRange)) / fadeRange
        return t
    elseif inputNumber <= min + fadeRange then
        local t = (inputNumber - min) / fadeRange
        return t
    else
        return 1
    end
end
local function getPositionBehind(pos, rot, distance, direction)
    -- helper func I brought over from other mods
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
        error(
            "Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
    end

    currentRotation = currentRotation - angleOffset
    local obj_x_offset = distance * math.cos(currentRotation)
    local obj_y_offset = distance * math.sin(currentRotation)
    local obj_x_position = pos.x + obj_x_offset
    local obj_y_position = pos.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, pos.z)
end
local function setShipRot(object, num)
    -- not used?
    for index, data in pairs(shipData) do
        if index == object.id then data.degRot = num end
    end
end
local function getShipCollideDisable(objectId)
    if shipData[objectId] then return shipData[objectId].disableCollision end
    return false
end
local function setShipSpeed(object, num)
    -- pretty obvious
    for index, data in pairs(shipData) do
        if index == object.id then data.forwMovement = num end
    end
end
local lockedShip = false

local function lockShipObjectx(state) lockedShip = state end
local function getPlayerShip() return playerShip end
local decreaseBy = 0.99

local function updateShipCell(ob, cell)
    if shipData[ob.recordId] then
        shipData[ob.recordId].cell = cell.name
        if cell.isExterior then
            shipData[ob.recordId].px = cell.gridX
            shipData[ob.recordId].py = cell.gridY
        else
            shipData[ob.recordId].px = nil
            shipData[ob.recordId].py = nil
        end
    else
    end
end
local function airshipKeysOnPressed(data)
    local keyData = data.keyData
    if keyData["lockMovement"].pressed then
        shipData[playerShip].lockMovement =
            not shipData[playerShip].lockMovement
        local message = "Movement Unlocked"
        if shipData[playerShip].lockMovement then
            message = "Movement Locked"
        end
        world.players[1]:sendEvent("AOSmessage", message)
    elseif keyData["toggleCollision"].pressed then
        shipData[playerShip].disableCollision =
            not shipData[playerShip].disableCollision
        local message = "Collision Disabled"
        if shipData[playerShip].disableCollision then
            message = "Collision Enabled"
        end
        world.players[1]:sendEvent("AOSmessage", message)

    end
end
local function airshipKeysPressedx(data)
    local keyData = data.keyData

    local dt = 1
    -- print(dt)
    local increment = 0.03 * dt
    local max = increment * 1000000
    if not playerShip then return end
    if keyData["MoveForward"].pressed and playerShip then
        if shipData[playerShip].forwMovement < max then
            shipData[playerShip].forwMovement =
                shipData[playerShip].forwMovement + increment
        end
    elseif keyData["MoveBackwards"].pressed and playerShip then
        if shipData[playerShip].forwMovement > -max then
            shipData[playerShip].forwMovement =
                shipData[playerShip].forwMovement - increment
        end
    elseif playerShip and not shipData[playerShip].lockMovement then
        if shipData[playerShip].forwMovement > increment then
            shipData[playerShip].forwMovement =
                shipData[playerShip].forwMovement * decreaseBy
        elseif shipData[playerShip].forwMovement < -increment then
            shipData[playerShip].forwMovement =
                shipData[playerShip].forwMovement * decreaseBy
        else
            shipData[playerShip].forwMovement = 0
        end
    end
    increment = 0.03 * dt
    if keyData["MoveLeft"].pressed and playerShip then
        shipData[playerShip].sideMovement =
            shipData[playerShip].sideMovement + increment
    elseif keyData["MoveRight"].pressed and playerShip then
        shipData[playerShip].sideMovement =
            shipData[playerShip].sideMovement - increment
    elseif playerShip and not shipData[playerShip].lockMovement then
        if shipData[playerShip].sideMovement > increment then
            shipData[playerShip].sideMovement =
                shipData[playerShip].sideMovement * decreaseBy
        elseif shipData[playerShip].sideMovement < -increment then
            shipData[playerShip].sideMovement =
                shipData[playerShip].sideMovement * decreaseBy
        else
            shipData[playerShip].sideMovement = 0
        end
    end
    increment = 0.03 * dt
    if keyData["MoveUp"].pressed and playerShip then
        shipData[playerShip].vertMovement =
            shipData[playerShip].vertMovement + increment
    elseif keyData["MoveDown"].pressed and playerShip then
        shipData[playerShip].vertMovement =
            shipData[playerShip].vertMovement - increment
    elseif playerShip then
        if shipData[playerShip].vertMovement > increment then
            shipData[playerShip].vertMovement =
                shipData[playerShip].vertMovement * decreaseBy
        elseif shipData[playerShip].vertMovement < -increment then
            shipData[playerShip].vertMovement =
                shipData[playerShip].vertMovement * decreaseBy
        else
            shipData[playerShip].vertMovement = 0
        end
    end
    increment = 0.003 * dt
    if keyData["RotatePlus"].pressed and playerShip then
        shipData[playerShip].degRot = shipData[playerShip].degRot + increment
    elseif keyData["RotateMinus"].pressed and playerShip then
        shipData[playerShip].degRot = shipData[playerShip].degRot - increment
    elseif playerShip then
        if shipData[playerShip].degRot > increment then
            shipData[playerShip].degRot =
                shipData[playerShip].degRot * decreaseBy
        elseif shipData[playerShip].degRot < -increment then
            shipData[playerShip].degRot =
                shipData[playerShip].degRot * decreaseBy
        else
            shipData[playerShip].degRot = 0
        end
    end
end
local markerIdList = {
    aeth_sc_exitmarker_cabinm = true,
    aeth_sc_exitmarker_cabinr = true,
    aeth_sc_exitmarker_cabinl = true,
    aeth_sc_exitmarker_dockr = true,
    aeth_sc_exitmarker_dockl = true,
    aeth_sc_exitmarker_main = true,
    aeth_sw_exitmarker = true
}
local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end
local function markerCheck(obj)
    if markerIdList[obj.recordId] == true then
        obj:setScale(0)
        if I.Aeth_ShipMovement then
            I.Aeth_ShipMovement.setMarkerPosition(obj)
        end
    end
    if startsWith(obj.recordId, "aeth_collisionchecker_") == true then
        obj:setScale(0)
    end
end
local function addShipData(objectList, mainObject)
    shipData[mainObject.recordId] = {
        mainObjectId = mainObject.recordId,
        cell = mainObject.cell.name
    }
    shipData[mainObject.recordId].bobState = bobStates.waitAtTop
    shipData[mainObject.recordId].bobCount = 1
    shipData[mainObject.recordId].bobDist = 100
    shipData[mainObject.recordId].vertMovement = 0
    shipData[mainObject.recordId].forwMovement = 0
    shipData[mainObject.recordId].sideMovement = 0
    shipData[mainObject.recordId].degRot = 0
    shipData[mainObject.recordId].lockMovement = false
    shipData[mainObject.recordId].disableCollision = true
    shipData[mainObject.recordId].cell = mainObject.cell.name
    if (mainObject.cell.isExterior) then
        shipData[mainObject.recordId].px, shipData[mainObject.recordId].py =
            mainObject.cell.gridX, mainObject.cell.gridY
    end
     print("Created ship " .. mainObject.recordId .. "," .. mainObject.recordId)
    shipData[mainObject.recordId].ladders = {
--        ladderTop = world.createObject("Aeth_LadderExtend_0", 1),
--        ladder1 = world.createObject("Aeth_LadderExtend_1", 1),
--        ladder2 = world.createObject("Aeth_LadderExtend_2", 1),
--        ladder3 = world.createObject("Aeth_LadderExtend_3", 1),
--        ladder4 = world.createObject("Aeth_LadderExtend_4", 1)
    }
    for _, obj in pairs(shipData[mainObject.recordId].ladders) do
        obj:teleport(mainObject.cell.name, mainObject.position, mainObject.rotation)
    end
end
local function arrestMovement(shipId)
    shipData[shipId].vertMovement = 0
    shipData[shipId].forwMovement = 0
    shipData[shipId].sideMovement = 0
    shipData[shipId].degRot = 0
    shipData[shipId].lockMovement = false
end
local function onSave()
    for index, value in pairs(shipData) do
        shipData[index].vertMovement = 0
        shipData[index].forwMovement = 0
        shipData[index].sideMovement = 0
        shipData[index].degRot = 0
        shipData[index].lockMovement = false
    end
    return {shipData = shipData}
end
local function onLoad(data)
    if not data then return end
    shipData = data.shipData
    if not world.players[1] then
        return
    end

end
local function onPlayerAdded() if shipData then onLoad({shipData = shipData}) end end

local function onUpdate(dt)
    if not getPlayer() then return end
    for index, data in pairs(shipData) do
   
        local objectList = I.ObjectGroup_Management.getObjectGroup(index)

        if  objectList[1]:isValid() then

        if not objectList then return end
       
        local doMove = false
        if not getMainShipOb(objectList) then return end
        local newPosition = objectList[1].position
        if data.vertMovement ~= 0 then
            doMove = true

            -- reduce speed closer to water
            if ((newPosition.z + data.vertMovement) < 512) then
                data.vertMovement = data.vertMovement * 0.95
            end
            -- update position and don't go below water
            newPosition = util.vector3(newPosition.x, newPosition.y, (newPosition.z + data.vertMovement) < 32 and 32 or (newPosition.z + data.vertMovement))
        end
        if data.forwMovement ~= 0 then
            doMove = true
            newPosition = getPositionBehind(newPosition, getMainShipOb(
                                                objectList).rotation:getAnglesZYX(),
                                            data.forwMovement, "north")
        end
        if data.sideMovement ~= 0 then
            doMove = true
            newPosition = getPositionBehind(newPosition, getMainShipOb(
                                                objectList).rotation:getAnglesZYX(),
                                            data.sideMovement, "east")
        end
        local newCell = nil
        if getMainShipOb(objectList).cell.isExterior and
            getMainShipOb(objectList).position.z > overWorldCeiling then
         --   newCell = world.getCellByName(cellname)
        elseif not getMainShipOb(objectList).cell.isExterior and
           getMainShipOb(objectList).position.z < overWorldCeiling then
         --   newCell = world.getExteriorCell(0, 0)
        end
        if doMove then
            I.ObjectGroup_Movementx.rotateAndMoveGroup(
                                                         getMainShipOb(
                                                             objectList).recordId,
                                                         data.degRot,
                                                         newPosition, nil, nil,
                                                         newCell)
        end
    end
end
end
local function AO_TeleportToCell(data)
    -- Simple function to teleport an object to any cell.

    if (data.cellname.name ~= nil) then data.cellname = data.cellname.name end
    data.item:teleport(data.cellname, data.position, data.rotation)
end

local function onActorActive(actor)
    if actor.recordId == "aeth_ao_zack" then actor.enabled = false end

end
local function onActivate(object, actor)

    if object.recordId == "aeth_ae_compass_silver" or object.recordId == "aeth_ae_compass_airship" or object.recordId == "aeth_ae_compass_steam" then
        actor:sendEvent("compassActivatex", object.recordId)
    end
end
return {
    interfaceName = "Aeth_ShipManage",
    interface = {
        version = 1,
        getPlayerShip = getPlayerShip,
        setPlayerShip = function (ship)
            playerShip = ship
        end,
        setShipSpeed = setShipSpeed,
        setShipRot = setShipRot,
        addShipData = addShipData,
        getShipData = function ()
            return shipData
        end,
        updateShipCell = updateShipCell,
        arrestMovement = arrestMovement,
        getShipCollideDisable = getShipCollideDisable,

    },
    engineHandlers = {
        onActivate = onActivate,
        onActorActive = onActorActive,
        onLoad = onLoad,
        onUpdate = onUpdate,
        onPlayerAdded = onPlayerAdded,
        onSave = onSave
    },
    eventHandlers = {
        airshipKeysPressedx = airshipKeysPressedx,
        lockShipObjectx = lockShipObjectx,
        airshipKeysOnPressed = airshipKeysOnPressed,
        AO_TeleportToCell = AO_TeleportToCell,
        ActorCheckShip = ActorCheckShip,
        showLadders = function ()
            local objectList = I.ObjectGroup_Management.getObjectGroup(getPlayerShip())
            if not objectList then return end
            if objectList[1]:isValid() then
                if not getMainShipOb(objectList) then return end
                local center = objectList[1].position
                local angle = objectList[1].rotation:getAnglesZYX()
                local rotation = createRotation(center.x, center.y, center.z - angle)
                for _, ladder in pairs(shipData[objectList[1].recordId].ladders) do
                    if (ladder:isValid() and ladder.count > 0) then
                        I.ObjectGroup_Movementx.teleportObject(objectList[1].cell, rotation, util.vector3(center.x, center.y, center.z), ladder)
                        ladder.enabled = true
                    end
                end
            end
        end,
        hideLadders = function ()
            local objectList = I.ObjectGroup_Management.getObjectGroup(getPlayerShip())
            if not objectList then return end
            if objectList[1]:isValid() then
                if not getMainShipOb(objectList) then return end
                for _, ladder in pairs(shipData[objectList[1].recordId].ladders) do
                    if (ladder:isValid() and ladder.count > 0) then
                        ladder.enabled = false
                    end
                end
            end
        end
   }
}
