--[[
    SharedRay v1

    Provides a single rendering raycast per frame for mods that need look-target
    data. This matches the lightweight pattern used by recent OpenMW spell mods.
]]
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local iMaxActivateDist = core.getGMST('iMaxActivateDist') or 192
local raycast = nearby.castRenderingRay

local MY_VERSION = 1
local cachedResult = {}

if I.SharedRay and I.SharedRay.version >= MY_VERSION then
    return
end

local function getCameraVector()
    local yaw = camera.getYaw()
    local pitch = camera.getPitch()
    local cosPitch = math.cos(pitch)
    return util.vector3(
        math.sin(yaw) * cosPitch,
        math.cos(yaw) * cosPitch,
        -math.sin(pitch)
    )
end

local function onFrame()
    if I.SharedRay and I.SharedRay.version > MY_VERSION then
        return
    end

    local cameraPos = camera.getPosition()
    local maxDist = iMaxActivateDist + camera.getThirdPersonDistance()

    local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        maxDist = maxDist + telekinesis.magnitude * 22
    end

    local endPos = cameraPos + getCameraVector() * maxDist
    local ray = raycast(cameraPos, endPos, { ignore = self })
    local hitObject = ray.hitObject

    cachedResult = {
        hit = ray.hit,
        hitPos = ray.hitPos,
        hitNormal = ray.hitNormal,
        hitObject = hitObject,
        hitTypeName = hitObject and tostring(hitObject.type) or nil,
    }
end

local function get()
    return cachedResult
end

local function setRayType(func)
    raycast = func
end

return {
    interfaceName = 'SharedRay',
    interface = {
        version = MY_VERSION,
        get = get,
        setRayType = setRayType,
    },
    engineHandlers = {
        onFrame = onFrame,
    },
}
