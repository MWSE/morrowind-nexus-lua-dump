local camera = require 'openmw.camera'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

CamHelper = {}

function CamHelper.isObjectBehindCamera(object)
    local cameraPos = camera.getPosition()
    local cameraForward = util.transform.identity
        * util.transform.rotateZ(camera.getYaw())
        * util.vector3(0, 1, 0)

    -- Direction vector from camera to object
    local toObject = object.position - cameraPos

    -- Normalize both vectors
    cameraForward = cameraForward:normalize()
    toObject = toObject:normalize()

    -- Calculate the dot product
    local dotProduct = cameraForward:dot(toObject)

    -- If the dot product is negative, the object is behind the camera
    return dotProduct < 0
end

---@param object GameObject object whose position will be checked
---@param useCenter boolean? whether to use the object's origin or the center of its bbox for targeting. Defaults to true if not provided.
---@return util.vector3? viewportPos If the object is onscreen, the identified screenSize position is returned. If not, then nil. Viewpos is NOT normalized.
function CamHelper.objectIsOnscreen(object, useCenter)
    if useCenter == nil then useCenter = true end
    local box = object:getBoundingBox()

    local checkPos = useCenter and box.center or (object.position + util.vector3(0, 0, box.halfSize.z * 1.25))
    local viewportPos = camera.worldToViewportVector(checkPos)
    local screenSize = ui.screenSize()

    local validX = viewportPos.x > 0 and viewportPos.x < screenSize.x
    local validY = viewportPos.y > 0 and viewportPos.y < screenSize.y
    local withinViewDistance = viewportPos.z <= camera.getViewDistance()

    if not validX or not validY or not withinViewDistance then return end

    if CamHelper.isObjectBehindCamera(object) then return end

    local normalizedX = util.remap(viewportPos.x, 0, screenSize.x, 0.0, 1.0)
    local normalizedY = util.remap(viewportPos.y, 0, screenSize.y, 0.0, 1.0)

    return util.vector3(normalizedX, normalizedY, viewportPos.z)
end

function CamHelper.trackTargetUsingViewport(targetObject, normalizedPos)
    if not targetObject then return end

    -- Desired screen position (center of the screen)
    local desiredScreenPos = util.vector2(0.5, 0.5)

    -- Convert the current and desired screen positions to world-space directions
    local currentWorldDir = camera.viewportToWorldVector(normalizedPos.xy)
    local desiredWorldDir = camera.viewportToWorldVector(desiredScreenPos)

    -- Normalize the directions
    currentWorldDir = currentWorldDir:normalize()
    desiredWorldDir = desiredWorldDir:normalize()

    -- Calculate the yaw and pitch differences
    local yawDifference = math.atan2(currentWorldDir.x, currentWorldDir.y) -
        math.atan2(desiredWorldDir.x, desiredWorldDir.y)

    local pitchDifference = math.asin(currentWorldDir.z) - math.asin(desiredWorldDir.z)

    camera.setYaw(util.normalizeAngle(camera.getYaw() + yawDifference))
    camera.setPitch(util.normalizeAngle(camera.getPitch() - pitchDifference))

    I.s3lf.controls.yawChange = yawDifference
    I.s3lf.controls.pitchChange = -pitchDifference

    return yawDifference, pitchDifference
end

return CamHelper
