
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("DepthFinder")

local ShaderService = require("mer.joyOfPainting.services.ShaderService")

---@class JOP.PhotoMenu.DepthFinder
---@field private currentDepth number
local DepthFinder = {
}

---@param photoMenu JOP.PhotoMenu
---@return JOP.PhotoMenu.DepthFinder
function DepthFinder:new(photoMenu)
    local o = {}
    setmetatable(o, self)
    self.photoMenu = photoMenu
    self.shader = ShaderService
    self.__index = self
    return o
end

function DepthFinder.getDepth()
    return DepthFinder.currentDepth
end


function DepthFinder:setTargetDepth()
    if not ShaderService.isEnabled("jop_dof") then
        logger:debug("Depth shader not enabled")
        return
    end

    if not self.photoMenu.isLooking then
        logger:debug("Not looking")
        return
    end

    --Get distance to target
    local result = tes3.rayTest({
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = {tes3.player},
        accurateSkinned = true,
    })
    if result then

        ShaderService.setUniform("jop_dof", "target_depth", result.distance)
        logger:debug("Set depth to %s", result.distance)
        if result.reference then
            local bb = result.reference.object.boundingBox
            local width = bb.max.x - bb.min.x
            local height = bb.max.y - bb.min.y
            local radius = math.max(width, height)
            ShaderService.setUniform("jop_dof", "focus_range", radius)
            logger:debug("Set focus range to %s", radius)
        end
    else
        ShaderService.setUniform("jop_dof", "target_depth", 1000000)
        logger:debug("No hit, setting depth to 1000000")
    end
end

function DepthFinder:registerEvents()
    logger:debug("Registering depth finder events")
    self.checkTimer = timer.start{
        type = timer.simulate,
        duration = 0.2,
        iterations = -1,
        callback = function()
            self:setTargetDepth()
        end,
    }
end

function DepthFinder:unregisterEvents()
    self.checkTimer:cancel()
    self.checkTimer = nil
end

return DepthFinder