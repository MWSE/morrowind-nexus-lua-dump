-- Modified from the original

local ui     = require("openmw.ui")
local util   = require("openmw.util")
local camera = require("openmw.camera")

---@param worldPos util.vector3
---@return boolean
local function isObjectBehindCamera(worldPos)
    -- This is from h3.
    local cameraPos = camera.getPosition()
    local cameraForward = util.transform.identity
        * util.transform.rotateZ(camera.getYaw())
        * util.vector3(0, 1, 0)

    -- Direction vector from camera to object
    local toObject = worldPos - cameraPos

    -- Normalize both vectors
    cameraForward = cameraForward:normalize()
    toObject = toObject:normalize()

    -- Calculate the dot product
    local dotProduct = cameraForward:dot(toObject)

    -- If the dot product is negative, the object is behind the camera
    return dotProduct < 0
end

---@class ViewportPosResult
---@field pos util.vector2? Normalized.
---@field onScreen boolean

---@param worldPos util.vector3
---@return ViewportPosResult
local function worldPosToNormalizedViewportPos(worldPos)
    -- This is from h3.
    local viewportPos = camera.worldToViewportVector(worldPos)
    local screenSize = ui.screenSize()

    local validX = viewportPos.x > 0 and viewportPos.x < screenSize.x
    local validY = viewportPos.y > 0 and viewportPos.y < screenSize.y
    local withinViewDistance = viewportPos.z <= camera.getViewDistance()

    if isObjectBehindCamera(worldPos) then return { onScreen = false } end

    local pos = util.vector2(viewportPos.x / screenSize.x, viewportPos.y / screenSize.y)

    if not validX or not validY or not withinViewDistance then
        return
        { pos = pos, onScreen = false }
    end

    return { pos = pos, onScreen = true }
end

--- Builds a world-space ray from a viewport pixel.
--- @param viewportPos util.vector2 -- pixel coordinates
--- @return util.vector3? rayDir (normalized)
local function viewportPosToWorldRay(viewportPos)
    assert(viewportPos and viewportPos.x and viewportPos.y,
        "viewportPos must be util.vector2")

    local screen = ui.screenSize()
    if screen.x <= 0 or screen.y <= 0 then
        return nil
    end

    local normalized = util.vector2(
        viewportPos.x / screen.x,
        viewportPos.y / screen.y
    )

    local dir = camera.viewportToWorldVector(normalized)
    if not dir then
        return nil
    end

    return dir:normalize()
end




return {
    isObjectBehindCamera = isObjectBehindCamera,
    worldPosToNormalizedViewportPos = worldPosToNormalizedViewportPos,
    viewportPosToWorldRay = viewportPosToWorldRay,
}
