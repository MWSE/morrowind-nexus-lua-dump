local camera = require("openmw.camera")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local util = require("openmw.util")

local function getCurrentTooltipTarget(player)
    local currentCameraMode = camera.getMode()
    if currentCameraMode ~= camera.MODE.FirstPerson and currentCameraMode ~= camera.MODE.ThirdPerson then
        return nil
    end

    local from = camera.getPosition()
    local to = from + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * core.getGMST("iMaxActivateDist")

    return nearby.castRay(from, to, { ignore = player }).hitObject
end

return {
    getCurrentTarget = getCurrentTooltipTarget
}
