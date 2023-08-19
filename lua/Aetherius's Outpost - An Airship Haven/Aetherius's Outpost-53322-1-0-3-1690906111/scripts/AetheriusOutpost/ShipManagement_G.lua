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
    ["zhac_dsub_full"] = "zhac_dsub_full",
    ["ex_de_ship"] = "ex_de_ship",
    ["ab_ex_impgalleonfullfurled"] = "ab_ex_impgalleonfullfurled",
    ["zhac_dship_x"] = "zhac_dship_x",
    ["ex_longboat"] = "ex_longboat",
    ["ab_ex_deshipsmall"] = "ab_ex_deshipsmall",
    ["zhac_silvercascade_ship"] = "zhac_silvercascade_ship",
}
if core.API_REVISION < 42 then
    error("You do not have the latest version of the OpenMW Engine")
end
local overWorldCeiling = 200000
local cellname = "skies of nirn"
local shipData = {}
local bobStates = { waitAtTop = 0, descendGradually = 1, waitAtBot = 2, ascendGradually = 3, }
local shipObjects = {}
local playerShip = nil
local dataLoaded = true

local function getPlayer()
    return world.players[1]
end
local function getMainShipOb(objectList)
    for index, value in ipairs(objectList) do
        if shipObjectIds[value.recordId] then
            return value
        end
    end
    for index, value in pairs(objectList) do
        if shipObjectIds[value.recordId] then
            return value
        end
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
    elseif inputNumber >= threshold - fadeRange and inputNumber <= threshold + fadeRange then
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
local function setShipRot(object, num)
    for index, data in pairs(shipData) do
        if index == object.id then
            data.degRot = num
        end
    end
end
local function getShipCollideDisable(objectId)
    if shipData[objectId] then
        return shipData[objectId].disableCollision
    end
    return false
end
local function setShipSpeed(object, num)
    for index, data in pairs(shipData) do
        if index == object.id then
            data.forwMovement = num
        end
    end
end
local lockedShip = false
local function ChangeShipObject(objectId)
    for findex, data in pairs(shipData) do
        if data.lockMovement then
            data.lockMovement = false
        end
    end
    if not objectId and lockedShip then return end
    for findex, data in pairs(shipData) do
        if findex == objectId then
            if lockedShip then
                getPlayer():sendEvent("setAirshipOb", object)
                return
            end
            getPlayer():sendEvent("setAirshipOb", getMainShipOb(shipObjects[findex]))
            playerShip = findex
            return
        elseif shipObjects[findex] then
            for index, object in ipairs(shipObjects[findex]) do
                if object.id == objectId then
                    if lockedShip then
                        getPlayer():sendEvent("setAirshipOb", object)
                        return
                    end
                    playerShip = findex
                    getPlayer():sendEvent("setAirshipOb", object)
                    return
                end
            end
        end
    end

    playerShip = nil
end
local function lockShipObject(state)
    lockedShip = state
end
local function getPlayerShip()
    return playerShip
end
local decreaseBy = 0.99

local function updateShipCell(ob, cell)
    if shipData[ob.id] then
        shipData[ob.id].cell = cell.name
        if cell.isExterior then
            shipData[ob.id].px = cell.gridX
            shipData[ob.id].py = cell.gridY
        else
            shipData[ob.id].px = nil
            shipData[ob.id].py = nil
        end
    else
    end
end
local function airshipKeysOnPressed(data)
    local keyData = data.keyData
    if keyData["lockMovement"].pressed then
        shipData[playerShip].lockMovement = not shipData[playerShip].lockMovement
        local message = "Movement Unlocked"
        if shipData[playerShip].lockMovement then
            message = "Movement Locked"
        end
        world.players[1]:sendEvent("AOSmessage", message)
    elseif keyData["toggleCollision"].pressed then
        shipData[playerShip].disableCollision = not shipData[playerShip].disableCollision
        local message = "Collision Disabled"
        if shipData[playerShip].disableCollision then
            message = "Collision Enabled"
        end
        world.players[1]:sendEvent("AOSmessage", message)

    end
end
local function airshipKeysPressed(data)
    local keyData = data.keyData

    local dt = 1
    --print(dt)
    local increment = 0.03 * dt
    local max = increment * 1000000
    if not playerShip then return end
        if keyData["MoveForward"].pressed and playerShip then
            if shipData[playerShip].forwMovement < max then
                shipData[playerShip].forwMovement = shipData[playerShip].forwMovement + increment
            end
        elseif keyData["MoveBackwards"].pressed and playerShip then
            if shipData[playerShip].forwMovement > -max then
                shipData[playerShip].forwMovement = shipData[playerShip].forwMovement - increment
            end
        elseif playerShip and not shipData[playerShip].lockMovement then
            if shipData[playerShip].forwMovement > increment then
                shipData[playerShip].forwMovement = shipData[playerShip].forwMovement * decreaseBy
            elseif shipData[playerShip].forwMovement < -increment then
                shipData[playerShip].forwMovement = shipData[playerShip].forwMovement * decreaseBy
            else
                shipData[playerShip].forwMovement = 0
            end
        end
        increment = 0.03 * dt
        if keyData["MoveLeft"].pressed and playerShip then
            shipData[playerShip].sideMovement = shipData[playerShip].sideMovement + increment
        elseif keyData["MoveRight"].pressed and playerShip then
            shipData[playerShip].sideMovement = shipData[playerShip].sideMovement - increment
        elseif playerShip and not shipData[playerShip].lockMovement then
            if shipData[playerShip].sideMovement > increment then
                shipData[playerShip].sideMovement = shipData[playerShip].sideMovement * decreaseBy
            elseif shipData[playerShip].sideMovement < -increment then
                shipData[playerShip].sideMovement = shipData[playerShip].sideMovement * decreaseBy
            else
                shipData[playerShip].sideMovement = 0
            end
        end
    increment = 0.03 * dt
    if keyData["MoveUp"].pressed and playerShip then
        shipData[playerShip].vertMovement = shipData[playerShip].vertMovement + increment
    elseif keyData["MoveDown"].pressed and playerShip then
        shipData[playerShip].vertMovement = shipData[playerShip].vertMovement - increment
    elseif playerShip then
        if shipData[playerShip].vertMovement > increment then
            shipData[playerShip].vertMovement = shipData[playerShip].vertMovement * decreaseBy
        elseif shipData[playerShip].vertMovement < -increment then
            shipData[playerShip].vertMovement = shipData[playerShip].vertMovement * decreaseBy
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
            shipData[playerShip].degRot = shipData[playerShip].degRot * decreaseBy
        elseif shipData[playerShip].degRot < -increment then
            shipData[playerShip].degRot = shipData[playerShip].degRot * decreaseBy
        else
            shipData[playerShip].degRot = 0
        end
    end
end
local markerIdList = {
    zhac_sc_exitmarker_cabinm = true,
    zhac_sc_exitmarker_cabinr = true,
    zhac_sc_exitmarker_cabinl = true,
    zhac_sc_exitmarker_main = true,
    zhac_sw_exitmarker = true
}
local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end
local function markerCheck(obj)
    if markerIdList[obj.recordId] == true then
        obj:setScale(0)
        if I.AOutpost_ShipMovement then
            I.AOutpost_ShipMovement.setMarkerPosition(obj)
        end
    end
    if startsWith(obj.recordId, "zhac_collisionchecker_") == true then
        obj:setScale(0)
    end
end
local function addShipData(objectList, mainObject)
    shipData[mainObject.id]              = { mainObjectId = mainObject.id, objectIds = {}, cell = mainObject.cell.name }
    shipObjects[mainObject.id]           = {}
    shipData[mainObject.id].bobState     = bobStates.waitAtTop
    shipData[mainObject.id].bobCount     = 1
    shipData[mainObject.id].bobDist      = 100
    shipData[mainObject.id].vertMovement = 0
    shipData[mainObject.id].forwMovement = 0
    shipData[mainObject.id].sideMovement = 0
    shipData[mainObject.id].degRot       = 0
    shipData[mainObject.id].lockMovement = false
    shipData[mainObject.id].disableCollision = true
    shipData[mainObject.id].cell         = mainObject.cell.name
    if (mainObject.cell.isExterior) then
        shipData[mainObject.id].px, shipData[mainObject.id].py = mainObject.cell.gridX, mainObject.cell.gridY
    end
    for index, obj in ipairs(objectList) do
        markerCheck(obj)
        table.insert(shipData[mainObject.id].objectIds, obj.id)
        table.insert(shipObjects[mainObject.id], obj)
    end
   -- print("Created ship " .. mainObject.recordId .. "," .. mainObject.id)
end
local function arrestMovement(shipId)
    shipData[shipId].vertMovement = 0
    shipData[shipId].forwMovement = 0
    shipData[shipId].sideMovement = 0
    shipData[shipId].degRot       = 0
    shipData[shipId].lockMovement = false
end
local function onSave()
    for index, value in pairs(shipData) do
        shipData[index].vertMovement = 0
        shipData[index].forwMovement = 0
        shipData[index].sideMovement = 0
        shipData[index].degRot       = 0
        shipData[index].lockMovement = false
    end
    return { shipData = shipData }
end
local function getCellsAroundOb(centerX, centerY)
    local ret = {}
    local centerCell = world.getExteriorCell(centerX, centerY)
    table.insert(ret, centerCell)

    -- Iterate over the surrounding cells
    for dx = -1, 1 do
        for dy = -1, 1 do
            local cellX = centerX + dx
            local cellY = centerY + dy
            local cell = world.getExteriorCell(cellX, cellY)
            table.insert(ret, cell)
        end
    end

    return ret
end
local function onLoad(data)
    if not data then return end
    shipData = data.shipData
    if not world.players[1] then dataLoaded = false
        return end

    for findex, data in pairs(shipData) do
        shipObjects[findex] = {}
        if not data.px and not data.py then
            for index, obj in ipairs(world.getCellByName(data.cell):getAll()) do
                for index, id in ipairs(data.objectIds) do
                    if id == obj.id then
                        markerCheck(obj)
                        table.insert(shipObjects[findex], obj)
                    end
                end
            end
        else
            for index, cell in ipairs(getCellsAroundOb(data.px, data.py)) do
                for index, obj in ipairs(cell:getAll()) do
                    for index, id in ipairs(data.objectIds) do
                        if id == obj.id then
                            markerCheck(obj)
                            table.insert(shipObjects[findex], obj)
                        end
                    end
                end
            end
        end
    end
end
local function onPlayerAdded()
if shipData then
    onLoad({shipData = shipData})
end
end


local function onUpdate(dt)
    if not getPlayer() then
        return
    end
    if not dataLoaded then

        onLoad({shipData = shipData})
    end
    for index, data in pairs(shipData) do
        local bobState = 9999 ---data.bobState
        local objectList = shipObjects[index]
        if not objectList then return end
        if bobState == bobStates.waitAtTop then
            data.bobCount = data.bobCount + 1
            if data.bobCount > 500 then
                data.bobCount = 1
                data.bobState = bobStates.descendGradually
            end
        elseif bobState == bobStates.descendGradually then
            data.bobCount = data.bobCount + 1
            if data.bobCount > 500 then
                data.bobCount = 1
                data.bobState = bobStates.waitAtBot
                data.vertMovement = 0
            else
                data.vertMovement = -transformNumber(data.bobCount) / 6
            end
        elseif bobState == bobStates.waitAtBot then
            data.bobCount = data.bobCount + 1
            if data.bobCount > 100 then
                data.bobCount = 1
                data.bobState = bobStates.ascendGradually
            end
        elseif bobState == bobStates.ascendGradually then
            data.bobCount = data.bobCount + 1
            if data.bobCount > 500 then
                data.bobCount = 1
                data.bobState = bobStates.waitAtTop
                data.vertMovement = 0
            else
                data.vertMovement = transformNumber(data.bobCount) / 6
            end
        end
        local doMove = false
        if not getMainShipOb(objectList) then
            return
        end
        local newPosition = getMainShipOb(objectList).position
        if data.vertMovement ~= 0 then
            doMove = true
            newPosition = util.vector3(newPosition.x, newPosition.y, newPosition.z + data.vertMovement)
        end
        if data.forwMovement ~= 0 then
            doMove = true
            newPosition = getPositionBehind(newPosition, getMainShipOb(objectList).rotation:getAnglesZYX(),
                data.forwMovement,
                "north")
        end
        if data.sideMovement ~= 0 then
            doMove = true
            newPosition = getPositionBehind(newPosition, getMainShipOb(objectList).rotation:getAnglesZYX(),
                data.sideMovement,
                "east")
        end
        I.AOutpost_ShipRecorder.recordFrame(data)
        local newCell = nil
        if getMainShipOb(objectList).cell.isExterior and getMainShipOb(objectList).position.z > overWorldCeiling then
            newCell = world.getCellByName(cellname)
        elseif not getMainShipOb(objectList).cell.isExterior and getMainShipOb(objectList).position.z < overWorldCeiling then
            newCell = world.getExteriorCell(0, 0)
        end
        if doMove then
            I.AOutpost_ShipMovement.rotateAndMoveAirship(objectList, getMainShipOb(objectList), data.degRot, newPosition,
                nil, nil, newCell)
        end
    end
    I.AOutpost_ShipRecorder.advanceFrame()
end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function objectWhiteListed(object)
    if object.type == types.Door or object.type == types.Container or object.type == types.Activator or object.type.baseType == types.Item then
        return true
    end
end
local function onObjectActive(object)
        if shipObjectIds[object.recordId] then
        if  not shipData[object.id] then
            local objectList = { object }
            for index, act in ipairs(object.cell:getAll()) do
                if distanceBetweenPos(object.position, act.position) < 2000 and objectWhiteListed(act) then
                    table.insert(objectList, act)
                end
            end

            addShipData(objectList, object)
        elseif shipData[object.id] and not shipObjects[object.id] then
            shipObjects[object.id] = {}
            local objectList = { object }
            for index, act in ipairs(object.cell:getAll()) do
                if distanceBetweenPos(object.position, act.position) < 2000 and objectWhiteListed(act) then
                  --  table.insert(objectList, act)
                    table.insert(shipObjects[object.id], act)
                end
            end
        end
    end
end
local function AO_TeleportToCell(data)
    --Simple function to teleport an object to any cell.

    if (data.cellname.name ~= nil) then
        data.cellname = data.cellname.name
    end
    data.item:teleport(data.cellname, data.position, data.rotation)
end
local function getShipObjects(shipId)
    return shipObjects[shipId]
end
local function onActorActive(actor)
if actor.recordId == "zhac_ao_zack" then
actor.enabled = false
end

end
return {
    interfaceName  = "AOutpost_ShipManage",
    interface      = {
        version = 1,
        getPlayerShip = getPlayerShip,
        setShipSpeed = setShipSpeed,
        setShipRot = setShipRot,
        getShipObjects = getShipObjects,
        updateShipCell = updateShipCell,
        arrestMovement = arrestMovement,
        getShipCollideDisable = getShipCollideDisable,
    },
    engineHandlers = {
        onActorActive = onActorActive,
        onObjectActive = onObjectActive,
        onLoad = onLoad,
        onUpdate = onUpdate,
        onPlayerAdded = onPlayerAdded,
        onSave = onSave,
    },
    eventHandlers  = {
        ChangeShipObject = ChangeShipObject,
        airshipKeysPressed = airshipKeysPressed,
        lockShipObject = lockShipObject,
        airshipKeysOnPressed = airshipKeysOnPressed,
        AO_TeleportToCell = AO_TeleportToCell,
    },
}
