local common = require("mer.fishing.common")
local logger = common.createLogger("RippleGenerator")
local config = require("mer.fishing.config")

---@class Fishing.RippleGenerator
local RippleGenerator = {}

---Generate a ripple at the given position

---@class Fishing.RippleGenerator.generateRipple.params
---@field position tes3vector3
---@field scale number
---@field amount number
---@field duration number


local function getEffectiveWaterHeight()
    local effectiveWaterHeight

    local waterLevel = tes3.player.cell.waterLevel
    if not mge.render.dynamicRipples then
        effectiveWaterHeight = waterLevel
    else
        effectiveWaterHeight = waterLevel
            + (mge.distantLandRenderConfig.waterWaveHeight/2)
    end
    logger:debug("Effective water height: %s", effectiveWaterHeight)
    --return effectiveWaterHeight
    return waterLevel
end

function RippleGenerator.generateRipple(params)
    local ripple = tes3.getObject("mer_ripple") --[[@as tes3activator]]
    local function makeRipple()
        logger:debug("making ripple at %s, size %s", params.position, params.scale)
        local vfx = tes3.createVisualEffect({
            object = ripple,
            position = tes3vector3.new(
                params.position.x,
                params.position.y,
                getEffectiveWaterHeight()
            ),
            repeatCount = 1,
            scale = params.scale or 1,
        })
    end

    local duration = params.duration or 0
    local amount = params.amount or 1
    if duration > 0 then
        timer.start{
            duration = duration / amount,
            iterations = amount,
            callback = function()
                logger:trace("*ripple*")
                makeRipple()
            end
        }
    else
        makeRipple()
    end
end

return RippleGenerator