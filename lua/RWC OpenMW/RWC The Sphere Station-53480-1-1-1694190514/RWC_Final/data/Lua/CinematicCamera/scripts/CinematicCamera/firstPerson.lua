local self = require('openmw.self')
local camera = require('openmw.camera')
local util = require('openmw.util')

local smoothRotation = require('scripts.CinematicCamera.smooth').rotation

local v2 = util.vector2
local controls = self.controls

local lastCameraMode = nil
local rotationChange = v2(0, 0)

local function getRotationControls()
    return v2(controls.yawChange, controls.pitchChange)
end

local function setRotationControls(v)
    controls.yawChange = v.x
    controls.pitchChange = v.y
end

local function on()
    lastCameraMode = camera.getMode()
    rotationChange = v2(0, 0)
end

local function update(dt)
    camera.setMode(camera.MODE.FirstPerson)

    rotationChange = smoothRotation(getRotationControls(), rotationChange, dt)
    setRotationControls(rotationChange)
end

local function off()
    camera.setMode(lastCameraMode)
end

return {
    on = on,
    update = update,
    off = off,
}