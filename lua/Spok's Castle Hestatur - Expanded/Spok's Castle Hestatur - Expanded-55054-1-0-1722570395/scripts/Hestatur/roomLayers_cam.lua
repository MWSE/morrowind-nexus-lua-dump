local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local layers = require("scripts.Hestatur.roomLayers_data")

local state = false
local currentCam = 1
local oldFov
local function isInCamMode()
    return state
end
local function enterCameraMode(pos, yaw, pitch, fov)
    if state == true then
        return
    end
    oldFov = camera.getFieldOfView()
    camera.setMode(camera.MODE.Static, true)
    camera.setStaticPosition(pos)
    camera.setPitch(pitch)
    camera.setYaw(yaw)
    camera.setFieldOfView(fov)
    state = true
end
local function exitCameraMode()
    if not state then
        return
    end
    camera.setMode(camera.MODE.FirstPerson)
    camera.setFieldOfView(oldFov)
    state = false
end
local function nextCamera()
    local layerdata = layers[self.cell.id]
    if layerdata.camPos then
        layerdata = layerdata.camPos
        local nextData = layerdata[currentCam + 1]
        if not nextData then
            currentCam = 1
            nextData = layerdata[currentCam ]
        else
            currentCam = currentCam + 1
        end
        local data = layerdata[currentCam]
        --print(currentCam)
        camera.setStaticPosition(util.vector3(data.position[1], data.position[2], data.position[3]))
        camera.setPitch(data.pitch)
        camera.setYaw(data.yaw)
        camera.setFieldOfView(data.fov)
    end
end

return {
    interfaceName = "RoomLayers_Cam",
    interface = {
        isInCamMode = isInCamMode,
        enterCameraMode = enterCameraMode,
        exitCameraMode = exitCameraMode,
        nextCamera = nextCamera,
    },
    eventHandlers = {
    },
    engineHandlers = {
        onSave = function()
            if state then
                exitCameraMode()
            end
        end
    }
}
