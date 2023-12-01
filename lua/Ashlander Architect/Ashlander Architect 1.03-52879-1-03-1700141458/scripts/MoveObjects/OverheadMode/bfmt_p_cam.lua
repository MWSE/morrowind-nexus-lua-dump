local core = require "openmw.core"
local input = require("openmw.input")
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local startTime = core.getRealTime() -- Start time since the game started
local storage = require('openmw.storage')


local currentCamObjPos

local migrateToPos = false

local desiredPitch = 0
local desiredYaw
local currentCamRot
local camMode = false
local function isInOverheadMode()
    return camMode
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

local function enterCamMode(position)
    I.UI.setPauseOnMode("Interface", false)
    camMode = true
    currentCamRot = 0
    currentCamObjPos = position
    camera.setMode(camera.MODE.ThirdPerson)
    camera.setMode(camera.MODE.Static)
    desiredPitch = 0.7
    desiredYaw = currentCamRot - math.rad(90)
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
    I.UI.setMode("Interface", { windows = {} })
    migrateToPos = true
end

local function exitCamMode(position)
    camMode = false
    currentCamObjPos = nil
    currentCamRot = nil
    camera.setMode(camera.MODE.FirstPerson)
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
    I.UI.setMode(nil)
    I.UI.setPauseOnMode("Interface", true)
end
local verticalMove, horizontalMove
local function adjustTowardsNumber(currentNumber, desiredNumber, incrementAmount)
    local reachedDesiredState = false
    local adjustedNumber

    if desiredNumber > currentNumber and desiredNumber > (currentNumber + incrementAmount) then
        adjustedNumber = currentNumber + incrementAmount
    elseif desiredNumber < currentNumber and desiredNumber < (currentNumber - incrementAmount) then
        adjustedNumber = currentNumber - incrementAmount
    else
        adjustedNumber = desiredNumber
        reachedDesiredState = true
    end
    return adjustedNumber, reachedDesiredState
end
local zHeight = 1000
local function edgeScroll(fverticalMove, fhorizontalMove)
    verticalMove, horizontalMove = fverticalMove, fhorizontalMove
end
local function onFrame()
    if not currentCamObjPos then return end
    local realCamPos = getPositionBehind(currentCamObjPos, currentCamRot, zHeight, "east")
    realCamPos = util.vector3(realCamPos.x, realCamPos.y, realCamPos.z + zHeight)
    if migrateToPos then
        local currentCamPos = camera.getPosition()
        local posAdjust = 30
        local xPos, xposCorrect = adjustTowardsNumber(currentCamPos.x, realCamPos.x, posAdjust)
        local yPos, yposCorrect = adjustTowardsNumber(currentCamPos.y, realCamPos.y, posAdjust)
        local zPos, zposCorrect = adjustTowardsNumber(currentCamPos.z, realCamPos.z, posAdjust)
        local curPitch, pitchCorrect = adjustTowardsNumber(camera.getPitch(), desiredPitch, 0.05)
        local curYaw, yawCorrect = adjustTowardsNumber(camera.getYaw(), desiredYaw, 0.05)

        camera.setPitch(curPitch)
        camera.setYaw(curYaw)

        camera.setStaticPosition(util.vector3(xPos, yPos, zPos))
        if xposCorrect and yposCorrect and zposCorrect and pitchCorrect and yawCorrect then
            migrateToPos = false
        end
        return
    end
    camera.setStaticPosition(realCamPos)
    camera.setYaw(currentCamRot - math.rad(90))
    local midButtonPressed = input.isMouseButtonPressed(2)

    if midButtonPressed then
        local movement = input.getMouseMoveX() + input.getMouseMoveY()
        currentCamRot = currentCamRot + (movement * 0.03)
    end
    if input.isKeyPressed(input.KEY.B) then
        -- currentCamRot = currentCamRot + math.rad(0.3)
    end

    if input.isKeyPressed(input.KEY.V) then
        --currentCamRot = currentCamRot - math.rad(0.3)
    end
    local moveAmount = 15
    local zoomAmount = 4
    if input.isKeyPressed(input.KEY.W) or horizontalMove == "up" then
        if input.isShiftPressed()  then
            zHeight = zHeight - zoomAmount
        else
        currentCamObjPos = getPositionBehind(currentCamObjPos, currentCamRot, moveAmount, "west")
        end
    end
    if input.isKeyPressed(input.KEY.S) or horizontalMove == "down" then
        if input.isShiftPressed()  then
            zHeight = zHeight + zoomAmount
        else

            currentCamObjPos = getPositionBehind(currentCamObjPos, currentCamRot, moveAmount, "east")
        end
    end

    if input.isKeyPressed(input.KEY.A) or verticalMove == "left" then
        if input.isShiftPressed()  then
             currentCamRot = currentCamRot - math.rad(0.3)
        else

            currentCamObjPos = getPositionBehind(currentCamObjPos, currentCamRot, moveAmount, "north")
        end
    end
    if input.isKeyPressed(input.KEY.D) or verticalMove == "right" then
        if input.isShiftPressed()  then
            currentCamRot = currentCamRot + math.rad(0.3)
        else

            currentCamObjPos = getPositionBehind(currentCamObjPos, currentCamRot, moveAmount, "south")
        end
    end
end
local function camMovement(offset)
    local mult = 0.1
    currentCamObjPos = getPositionBehind(currentCamObjPos, currentCamRot, offset.x * mult, "north")
    currentCamObjPos = getPositionBehind(currentCamObjPos, currentCamRot, offset.y * mult, "west")
    -- currentCamObjPos = util.vector3(currentCamObjPos.x - (offset.x * mult),currentCamObjPos.y - (offset.y * mult),currentCamObjPos.z)
end
local function onInputAction(action)
    local zoomAmount = 30
    if input.isCtrlPressed() or input.isShiftPressed() or input.isAltPressed() then
    else
        if action == input.ACTION.ZoomIn then
            zHeight = zHeight - zoomAmount
        elseif action == input.ACTION.ZoomOut then
            zHeight = zHeight + zoomAmount
        end
    end
    --zoon in, out
end
local function getcurrentCamRot()
    return currentCamRot
end
--Need to track the camera position.
--Camera object is the point on the ground that the camera is looking atl.
return {
    interfaceName = "BFMT_Cam",
    interface = {
        enterCamMode = enterCamMode,
        camMovement = camMovement,
        isInOverheadMode = isInOverheadMode,
        exitCamMode = exitCamMode,
        edgeScroll = edgeScroll,
        getcurrentCamRot = getcurrentCamRot,
    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
    }
}
