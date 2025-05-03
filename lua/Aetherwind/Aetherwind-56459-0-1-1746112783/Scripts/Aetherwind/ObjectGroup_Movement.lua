local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ((z))
        return rotate
    end
end
local function setPlayerPosition(pos, rotZ)
    local scr = world.mwscript.getGlobalScript("aeth_airship_setppos", world.players[1])
    scr.variables.px = pos.x
    scr.variables.py = pos.y
    scr.variables.pz = pos.z
    scr.variables.pr = math.deg(rotZ)
    scr.variables.domove = 1
end
local function distanceBetweenPos(vector1, vector2)
    -- Quick way to find out the distance between two vectors.
    -- Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local lastPlayerPosition
local function teleportObject(cell, rot, pos, ob)
    if ob == world.players[1] and cell.worldSpaceId == ob.cell.worldSpaceId then
        -- if setPlayerPosition ~= nil then
        local rz = 0
        if rot then
            rz = rot:getAnglesZYX()
        else
            rz = world.players[1] .rotation:getAnglesZYX()
        end
        if lastPlayerPosition then
            if distanceBetweenPos(lastPlayerPosition,pos) > 1000 then
            -- pos = lastPlayerPosition
            end
        end
        setPlayerPosition(pos, rz)
        lastPlayerPosition = pos
        return
        -- end
    end
    ob:teleport(cell, pos, rot)
    --shipObjects[i]:setRotation(rotation)
    --shipObjects[i]:setPosition(position)
end
local function rotateAndMoveGroup(key, degrees, newPosition, rotationZ, doEvent, newCell)
    --This function does the heavy lifting for moving and rotating the airship/object group.
    local objectList = I.ObjectGroup_Management.getObjectGroup(key)
    local mainObject = objectList[1]
    --local rot = createRotation(0, 0, rotationZ)
    -- airshipOb = ob
    local newPos = {}
    local obList = {}
    TPedObjects = {}
    for _, value in ipairs(objectList) do
        table.insert(obList, value)
    end
    -- airshipOb:teleport("", position, rot)
    --player:teleport("", util.vector3(position.x, position.y, position.z - 340), rot)
    --player:teleport(player.cell.name, (player.position - airshipOb.position) + position)
    if newCell then
        if newCell.name == nil then
            newCell = world.getCellByName(newCell)
        end
        for _, value in ipairs(obList) do
            --  value:setPosition(value.position - airshipOb.position + position)
            teleportObject(newCell, nil, (value.position - mainObject.position) + newPosition, value)
            -- value:teleport(newCell, (value.position - mainObject.position) + newPosition)
        end
        return
    end
    if not newCell then
        newCell = mainObject.cell
    end
    for _, value in ipairs(obList) do
        if value:isValid() and value.count > 0 then
            newPos[value.id] = (value.position - mainObject.position + newPosition)
        end
        --   value:teleport("", (value.position - airshipOb.position) + position)
    end
    local collisionCheck = {}
    if degrees == 0 then
        for _, value in ipairs(obList) do
            if value:isValid() and value.count > 0 then
                teleportObject(newCell, nil, newPos[value.id], value)
                collisionCheck[value.recordId] = value.position
            end
        end
        world.players[1]:sendEvent("collisionCheck", collisionCheck)
    else
        local angle = math.rad((degrees))
        local recordId = mainObject.recordId
        -- Find the object with the specified recordId and calculate its position
        local center = newPos[mainObject.id]

        -- Calculate the total offset of all objects from the center
        local totalOffset = util.vector3(0, 0, 0)
        for i = 1, #obList do
            if obList[i]:isValid() and obList[i].count > 0 then
                totalOffset = totalOffset + (newPos[obList[i].id] - center)
            end
        end

        -- Calculate the average position of all objects
        local averagePosition = center -- + (totalOffset / #shipObjects)

        -- Rotate each object around the average position
        for i = 1, #obList do
            if obList[i]:isValid() and obList[i].count > 0 then
                -- Calculate the relative position of the object to the average position
                local relativePosition = newPos[obList[i].id] - averagePosition
                local x = relativePosition.x * math.cos(angle) - relativePosition.y * math.sin(angle)
                local y = relativePosition.x * math.sin(angle) + relativePosition.y * math.cos(angle)
                local position = util.vector3(x + averagePosition.x, y + averagePosition.y, newPos[obList[i].id].z)

                -- Calculate the new rotation
                local rz, ry, rx = obList[i].rotation:getAnglesZYX()
                local rotation = createRotation(rx, ry, rz - angle)

                if obList[i]:isValid() and obList[i].count > 0 then
                    -- Move the object
                    teleportObject(newCell, rotation, position, obList[i])
                    if startsWith(obList[i].recordId, "aeth_collisionchecker_") then
                        obList[i]:setScale(0)
                        collisionCheck[obList[i].recordId] = position
                    end
                end
                world.players[1]:sendEvent("collisionCheck", collisionCheck)
            end
        end
    end
    --doRot = true
    -- if doEvent then
    -- getPlayer():sendEvent("POVAirship")
    -- end
end
local function moveGroupVert(objectList, mainObject, dist)
    local newLocation = util.vector3(mainObject.position.x, mainObject.position.y, mainObject.position.z + dist)
    rotateAndMoveGroup(mainObject.recordId,0, newLocation)
end
local function moveGroupVertDown(objectList, mainObject, dist)
    local newLocation = util.vector3(mainObject.position.x, mainObject.position.y, mainObject.position.z - dist)
    rotateAndMoveGroup(mainObject.recordId,0, newLocation)
end
local function moveAirshipEvent(data)
    rotateAndMoveGroup(data.ob.recordId, data.rot,data.position)
end
return {
    interfaceName = "ObjectGroup_Movementx",
    interface = {
        rotateAndMoveGroup = rotateAndMoveGroup,
        moveGroupVert = moveGroupVert,
        moveGroupVertDown = moveGroupVertDown,
        teleportObject = teleportObject
    },
    engineHandlers = {
    },
    eventHandlers = {
        moveAirshipEvent = moveAirshipEvent,
    }
}


