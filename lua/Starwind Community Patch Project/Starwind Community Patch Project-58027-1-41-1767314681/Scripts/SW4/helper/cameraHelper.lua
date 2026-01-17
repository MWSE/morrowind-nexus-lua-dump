local camera = require 'openmw.camera'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

CamHelper = {}

function CamHelper.isObjectBehindCamera(object)
    local cameraPos = camera.getPosition()
    local cameraForward = util.transform.identity * util.transform.rotateZ(camera.getYaw()) *
        util.vector3(0, 1, 0)

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

---@param object userdata object whose position will be checked
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

function CamHelper.getCameraTransform()
    return {
        position = camera.getPosition(),
        rotation = util.transform.identity * util.transform.rotateZ(camera.getYaw()) *
            util.transform.rotateY(camera.getRoll()) * util.transform.rotateX(camera.getPitch()),
    }
end

return CamHelper
