local camera = require('openmw.camera')
local input = require('openmw.input')
local util = require('openmw.util')
local storage = require('openmw.storage')

local controlsSettings = storage.playerSection('SettingsCinematicCameraControls')
local smoothingSettings = storage.playerSection('SettingsCinematicCameraSmoothing')
local smoothRotation = require('scripts.CinematicCamera.smooth').rotation

local v2 = util.vector2
local v3 = util.vector3

local function getCameraRotation()
    return v2(camera.getYaw(), camera.getPitch())
end

local function setCameraRotation(v)
    camera.setYaw(v.x)
    camera.setPitch(v.y)
end

local actionMap = {
    [input.ACTION.MoveForward] = v3(0, 1, 0),
    [input.ACTION.MoveBackward] = v3(0, -1, 0),
    [input.ACTION.MoveLeft] = v3(-1, 0, 0),
    [input.ACTION.MoveRight] = v3(1, 0, 0),
    [input.ACTION.Jump] = v3(0, 0, 1),
    [input.ACTION.Sneak] = v3(0, 0, -1),
}
local function getMovementDirection(rotation)
    local transform = util.transform.rotateZ(rotation.x)
    local direction = v3(0, 0, 0)
    for action, v in pairs(actionMap) do
        if input.isActionPressed(action) then
            direction = direction + v
        end
    end
    direction = transform * direction
    return direction:normalize()
end

local rotation = v2(0, 0)
local rotationChange = v2(0, 0)
local position = v3(0, 0, 0)
local velocity = v3(0, 0, 0)
local lastCameraMode = nil
local lastControlSwitches = {}

local function on()
    lastCameraMode = camera.getMode()
    rotation = getCameraRotation()
    rotationChange = v2(0, 0)
    position = camera.getPosition()
    velocity = v3(0, 0, 0)

    for _, v in pairs(input.CONTROL_SWITCH) do
        lastControlSwitches[v] = input.getControlSwitch(v)
        input.setControlSwitch(v, false)
    end

    camera.setMode(camera.MODE.Static)
end

local function update(dt)
    local mouseMove = v2(input.getMouseMoveX(), input.getMouseMoveY())
    local sensitivity = v2(
        controlsSettings:get('cameraSensitivityX'),
        controlsSettings:get('cameraSensitivityY')
    ) / 256
    local newRotationChange = mouseMove:emul(sensitivity)
    rotationChange = smoothRotation(newRotationChange, rotationChange, dt)
    if rotationChange:length() > smoothingSettings:get('maxRotation') * dt then
        rotationChange = rotationChange:normalize() * smoothingSettings:get('maxRotation') * dt
    end
    -- prevent locking into vertical rotations
    if math.abs(rotation.y) > math.pi * 0.5 and rotationChange.y * rotation.y > 0 then
        rotationChange = v2(rotationChange.x, 0)
    end 
    rotation = rotation + rotationChange
    setCameraRotation(rotation)

    local direction = getMovementDirection(rotation)
    local acceleration = util.clamp(
        velocity:length() * smoothingSettings:get('relativeAcceleration') * dt,
        smoothingSettings:get('minAcceleration') * dt,
        smoothingSettings:get('maxAcceleration') * dt
    )
    velocity = velocity + direction * acceleration
    position = position + velocity * dt
    camera.setStaticPosition(position)
end

local function off()
    camera.setMode(lastCameraMode)
    for _, v in pairs(input.CONTROL_SWITCH) do
        input.setControlSwitch(v, lastControlSwitches[v])
    end
end

return {
    on = on,
    update = update,
    off = off,
}