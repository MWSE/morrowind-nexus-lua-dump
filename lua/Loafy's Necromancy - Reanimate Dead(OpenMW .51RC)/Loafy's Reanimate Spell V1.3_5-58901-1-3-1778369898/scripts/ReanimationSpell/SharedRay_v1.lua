--[[
    LookTarget - Shared Raycast Service v1
    
    Provides a single rendering raycast per frame for all mods to consume.
    Ship this file with any mod that needs look-target data.
    
    Version priority:
        - Multiple mods can ship this at the same path
        - VFS dedupes identical files
        - If different versions exist, highest version wins the interface
        - Lower versions skip their raycast via version check
    
    Usage:
        local result = I.LookTarget.get()
        if result.hitType then
            -- player is looking at something
        end
    
    Result fields:
        hit         - boolean
        hitPos      - Vector3 or nil
        hitNormal   - Vector3 or nil  
        hitObject   - GameObject or nil
        hitType     - string (e.g. "Container", "NPC") or nil
]]
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local iMaxActivateDist = core.getGMST("iMaxActivateDist") or 192
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
    -- Defer to higher version if one exists
    if I.SharedRay.version > MY_VERSION then
        return
    end
    
    local cameraPos = camera.getPosition()
    local maxDist = (iMaxActivateDist) + camera.getThirdPersonDistance()
    
    local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        maxDist = maxDist + telekinesis.magnitude * 22
    end
    
    local endPos = cameraPos + getCameraVector() * maxDist
    local ray = raycast(cameraPos, endPos, { ignore = self })
    
    local newHitObject = ray.hitObject
    cachedResult = {
        hit = ray.hit,
        hitPos = ray.hitPos,
        hitNormal = ray.hitNormal,
        hitObject = newHitObject,
        hitTypeName = newHitObject and tostring(newHitObject.type) or nil,
    }
end

local function get()
    return cachedResult
end

local function setRayType(func)
	raycast = func
	if func == nearby.castRenderingRay then
		print("[SharedRay] changing raycast to castRenderingRay")
	elseif func == nearby.castRay then
		print("[SharedRay] changing raycast to castRay")
	else
		print("[SharedRay] changing raycast to unknown")
	end
end

return {
    interfaceName = "SharedRay",
    interface = {
        version = MY_VERSION,
        get = get,
		setRayType = setRayType,
    },
    engineHandlers = {
        onFrame = onFrame,
    },
}