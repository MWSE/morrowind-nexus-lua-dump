local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local startingWallHub

local endWallHub
local slopeCount = 0

local buildData = require("scripts.MoveObjects.Movement.TileData")

local walls = {}
local wallsSloped = {}
local wallcount = 1
local wallRotate = 0
local zOffset = 0
local possibleDestHubs = {}
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
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

local function getPointedAngle(start, endx)
    -- Your vector2 points

    -- Calculate the difference in x and y coordinates
    local deltaX = endx.x - start.x
    local deltaY = endx.y - start.y

    -- Calculate the angle in radians using atan2
    local angleRadians = math.atan2(deltaY, deltaX)

    -- Ensure the angle is between 0 and 2*pi (0 and 360 degrees)
    angleRadians = angleRadians >= 0 and angleRadians or (2 * math.pi + angleRadians)

    -- Now, angleRadians contains the angle in radians between the two points
    --print("Angle in radians: " .. angleRadians)
    return angleRadians
end
local function getPointedAngleIncrement(start, endx, increment)
    increment = increment or math.pi / 2 -- Default to 90 degrees if not provided

    -- Your vector2 points

    -- Calculate the difference in x and y coordinates
    local deltaX = endx.x - start.x
    local deltaY = endx.y - start.y

    -- Calculate the angle in radians using atan2
    local angleRadians = math.atan2(deltaY, deltaX)

    -- Round the angle to the nearest increment
    angleRadians = math.floor((angleRadians + increment / 2) / increment) * increment

    -- Ensure the angle is between 0 and 2*pi (0 and 360 degrees)
    angleRadians = angleRadians >= 0 and angleRadians or (2 * math.pi + angleRadians)

    -- Now, angleRadians contains the angle in radians between the two points rounded to the nearest increment
    return angleRadians
end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    if (vector1 == nil or vector2 == nil) then
        error("Invalid position data provided")
    end
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
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
local function stopBuilding()
    for index, value in ipairs(walls) do
        value:remove()
    end

    for index, value in ipairs(wallsSloped) do
        value:remove()
    end
    if endWallHub then
        endWallHub:remove()
        world.players[1]:sendEvent("setSelectedObj", nil)
        endWallHub = nil
        startingWallHub = nil
    end
end
local function startBuildingFromHub(hub, cancel)
    for index, value in ipairs(walls) do
        if value.enabled == false and value.count > 0 then
            value:remove()
        end
    end
    possibleDestHubs = {}
    if not buildData[hub.recordId] then
        world.players[1]:sendEvent("setSelectedObj", nil)
        endWallHub = nil
        startingWallHub = nil
    end
    walls = {}
    wallsSloped = {}
    if cancel then
        stopBuilding()
        return
    end
    startingWallHub = hub
    zOffset = 0
    endWallHub = world.createObject(buildData[hub.recordId].endPiece)
    endWallHub:teleport(startingWallHub.cell, startingWallHub.position)
    table.insert(walls, world.createObject(buildData[hub.recordId].wallPiece))
    for i = 1, 10, 1 do
        table.insert(walls, world.createObject(buildData[hub.recordId].wallPiece))
        if buildData[hub.recordId].slopePieceMain then
            table.insert(wallsSloped, world.createObject(buildData[hub.recordId].slopePieceMain))
        end
    end
    for index, value in ipairs(walls) do
        value:teleport(startingWallHub.cell, startingWallHub.position)
    end
    for index, value in ipairs(wallsSloped) do
        value:teleport(startingWallHub.cell, startingWallHub.position)
    end
    for index, value in ipairs(world.players[1].cell:getAll()) do
        if value.recordId == buildData[hub.recordId].endPiece and value.id ~= endWallHub.id and value.id ~= hub.id then
            table.insert(possibleDestHubs,value)
        end
    end
    world.players[1]:sendEvent("setSelectedObj", endWallHub)
end
local function getStartingPosition()
    if not startingWallHub then return end
    local data  = buildData[startingWallHub.recordId]
    local angle = startingWallHub.rotation:getAnglesZYX()

    if data.startPosOffset then
        return getPositionBehind(startingWallHub.position, angle, data.startPosOffset, data.startPosOffsetDir)
    end
    return startingWallHub.position
end
local function updateEndPosition(pos)
    if not pos then
        return
    end
    local fixedPos = false
    for index, value in ipairs(possibleDestHubs) do
        local distCheck = distanceBetweenPos(pos, value.position) 
        if distCheck < 1300 then
            pos = value.position
            fixedPos = true
        end
    end
    if not startingWallHub then return end
    local startingPos  = getStartingPosition()
    local checkPos     = util.vector3(pos.x, pos.y, startingPos.z)
    local data         = buildData[startingWallHub.recordId]
    local dist         = distanceBetweenPos(startingPos, checkPos)
    local angle        = startingWallHub.rotation:getAnglesZYX()

    local zSlopeHeight = 0
    local distOffset   = 5000
    if data.distOffset and not fixedPos then
        dist = dist + data.distOffset
    end
    if data.freeRotate then
        angle = -getPointedAngle(startingPos, checkPos)
    elseif data.doRotate then
        angle = -getPointedAngleIncrement(startingPos, checkPos)
    end
    local wrotate = 0
    if data.wallRotate then
        wrotate = data.wallRotate
    end
    local newPos = getPositionBehind(startingPos, angle, dist, "east")
    local countDown = dist + data.separatingDistance
if fixedPos then
    countDown = dist - (data.separatingDistance / 2)
end
    local reverseSlope = false
    local slopeZAdjust = data.slopeDist
    if slopeCount < 0 then
        reverseSlope = true
        slopeZAdjust = -slopeZAdjust
        if data.doSlopeRotate then
            wallRotate = math.rad(180)
        end
    elseif data.doSlopeRotate then
        wallRotate = math.rad(0)
    end
    local slopeCountAbs = math.abs(slopeCount)
    local wallNum = 1
    while countDown > 0 do
        if walls[wallNum] then
            local id = data.wallPiece
            local slope = false
            if wallNum < slopeCountAbs and data.slopePieceMain then
                slope = true
            else

            end
            if reverseSlope and slope then
                zSlopeHeight = zSlopeHeight + slopeZAdjust
            end
            local wallPos = getPositionBehind(startingPos, angle, data.separatingDistance * wallNum - data.startOffset,
                "east")
            wallPos = util.vector3(wallPos.x, wallPos.y, wallPos.z + data.wallHeightOffset + zOffset + zSlopeHeight)
            if slope then
                wallsSloped[wallNum]:teleport(startingWallHub.cell, wallPos,
                    createRotation(0, 0, angle + wallRotate + math.rad(wrotate)))
                if not reverseSlope then
                    zSlopeHeight = zSlopeHeight + slopeZAdjust
                end
            else
                walls[wallNum]:teleport(startingWallHub.cell, wallPos,
                    createRotation(0, 0, angle + wallRotate + math.rad(wrotate)))
            end
            wallNum = wallNum + 1
        end
        countDown = countDown - data.separatingDistance
    end
    if wallNum < #walls then
        for index, value in ipairs(walls) do
            if index >= wallNum or index < slopeCountAbs then
                value.enabled = false
            end
        end
    end
    for index, value in ipairs(wallsSloped) do
        if index >= slopeCountAbs then
            value.enabled = false
        end
    end
    local endRot = startingWallHub.rotation
    if data.rotateEnd then
        endRot = createRotation(0, 0, angle + wallRotate + math.rad(wrotate))
    end
    local endPos = getPositionBehind(startingPos, angle, data.separatingDistance * wallNum - data.endOffset, "east")
    if fixedPos then
        endPos = pos
    end
    endWallHub:teleport("", util.vector3(endPos.x, endPos.y, endPos.z + zOffset + zSlopeHeight), endRot)
end
local function keyPress(key)
    if key == "leftclick" then
        startBuildingFromHub(endWallHub, not buildData[startingWallHub.recordId].repeats)
    elseif key == "esc" then
        stopBuilding()
    elseif key == "zoomin" then
        zOffset = zOffset + buildData[startingWallHub.recordId].scrollHeight
    elseif key == "zoomout" then
        zOffset = zOffset - buildData[startingWallHub.recordId].scrollHeight
    elseif key == "x" then
        slopeCount = slopeCount + 1
    elseif key == "z" then
        slopeCount = slopeCount - 1
    elseif key == "j" then
        if wallRotate == 0 then
            wallRotate = math.rad(180)
        else
            wallRotate = 0
        end
    end
end
local function onSave()
    if endWallHub then
        endWallHub:remove()
    end
    for index, value in ipairs(walls) do
        value:remove()
    end
    for index, value in ipairs(wallsSloped) do
        value:remove()
    end
end
return {
    interfaceName = "AA_TileWall",
    interface = {
        version = 1,
    },
    eventHandlers = {
        startBuildingFromHub = startBuildingFromHub,
        updateEndPosition = updateEndPosition,
        keyPress = keyPress,
    },
    engineHandlers = { onSave = onSave }
}
