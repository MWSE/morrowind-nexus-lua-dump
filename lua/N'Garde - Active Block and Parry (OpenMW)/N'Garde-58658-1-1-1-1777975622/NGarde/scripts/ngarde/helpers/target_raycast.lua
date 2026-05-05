local core = require('openmw.core')
local contextReader = require('scripts.ngarde.helpers.scriptContext')
local nearby = require('openmw.nearby')
local camera
local scriptContext = contextReader.get()
if scriptContext == contextReader.Types.Player then
    camera = require('openmw.camera')
end
local util = require('openmw.util')
local iMaxActivateDist = core.getGMST("iMaxActivateDist") or 192
local logging = require('scripts.ngarde.helpers.logger').new()
logging:setLoglevel(logging.LOG_LEVELS.OFF)


local targetRaycast = {}
targetRaycast.__index = targetRaycast

function targetRaycast.new()
    local self = setmetatable({}, targetRaycast)
    self.raycast = nearby.castRay
    return self
end

-- Modifying this to suit target acquisition, for now just dropping the version to 0, so that no other mod uses it. Renaming the interface too.
-- Don't care about telekinesis, and need a much longer distance
function targetRaycast.getCameraVector()
    local yaw = camera.getYaw()
    local pitch = camera.getPitch()
    local cosPitch = math.cos(pitch)
    return util.vector3(
        math.sin(yaw) * cosPitch,
        math.cos(yaw) * cosPitch,
        -math.sin(pitch)
    )
end

function targetRaycast.castToCursor(self, ignore)
    local cameraPos = camera.getPosition()
    local maxDist = iMaxActivateDist * 50

    local endPos = cameraPos + targetRaycast.getCameraVector() * maxDist
    local ray = self.raycast(cameraPos, endPos, { ignore = ignore })

    local newHitObject = ray.hitObject
    return {
        hit = ray.hit,
        hitPos = ray.hitPos,
        hitNormal = ray.hitNormal,
        hitObject = newHitObject,
        hitTypeName = newHitObject and tostring(newHitObject.type) or nil,
    }
end

function targetRaycast.castToCursorRange(self, ignore, range)
    local cameraPos = camera.getPosition()
    local maxDist = range
    if camera.getMode() == camera.MODE.ThirdPerson then
        local cameraDistance = camera.getThirdPersonDistance()
        maxDist = maxDist + cameraDistance
    end

    local endPos = cameraPos + targetRaycast.getCameraVector() * maxDist
    logging:status(("cameraPos: %s, endPos: %s, maxDist: %s"):format(cameraPos,endPos,maxDist))
    local ray = self.raycast(cameraPos, endPos, { ignore = ignore })

    local newHitObject = ray.hitObject
    return {
        hit = ray.hit,
        hitPos = ray.hitPos,
        hitNormal = ray.hitNormal,
        hitObject = newHitObject,
        hitTypeName = newHitObject and tostring(newHitObject.type) or nil,
    }
end


function targetRaycast.castFromToTarget(self, ignore, from, to)
    local ray = self.raycast(from, to, { ignore = ignore })
    local newHitObject = ray.hitObject
    return {
        hit = ray.hit,
        hitPos = ray.hitPos,
        hitNormal = ray.hitNormal,
        hitObject = newHitObject,
        hitTypeName = newHitObject and tostring(newHitObject.type) or nil,
    }
end

function targetRaycast.castNavigationRay(self, from, to, options)
    local opt = options or nil
    local res = nearby.castNavigationRay(from, to, opt)
    return res
end

function targetRaycast.setRayType(self, func)
    if func == nearby.castRenderingRay or func == "castRenderingRay" then
        logging:debug("Changing raycast to castRenderingRay")
        self.raycast = nearby.castRenderingRay
    elseif func == nearby.castRay or func == "castRay" then
        logging:debug("Changing raycast to castRay")
        self.raycast = nearby.castRay
    elseif func == nearby.castNavigationRay or func == "castNavigationRay" then
        logging:debug("Changing raycast to castNavigationRay")
        self.raycast = nearby.castNavigationRay
    elseif func == nearby.asyncCastRenderingRay or func == "asyncCastRenderingRay" then
        logging:debug("Changing raycast to asyncCastRenderingRay")
        self.raycast = nearby.asyncCastRenderingRay
    else
        logging:error("Unknown raycast type. Defaulting to castRenderingRay")
        self.raycast = nearby.castRenderingRay
    end
end

return targetRaycast
