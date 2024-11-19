--[[
    Increase the size of MGE XE waves during the comet event
]]

local common = require("mer.darkShard.common")
local logger = common.createLogger("waves")
local CometEffect = require("mer.darkShard.components.CometEffect")

local MIN_WAVE_HEIGHT = 0
local MAX_WAVE_HEIGHT = 400
local defaultWaveHeight = mge.distantLandRenderConfig.waterWaveHeight

---@param e DarkShard.CometEffect.ConditionChangedEventData
event.register(CometEffect.conditionChangedEvent, function(e)
    if not mge.render.dynamicRipples then return end
    if e.isActive then
        local effectStrength = CometEffect.getEffectStrength()
        local waveHeight = math.remap(effectStrength, 0, 1, defaultWaveHeight + MIN_WAVE_HEIGHT, MAX_WAVE_HEIGHT)
        mge.distantLandRenderConfig.waterWaveHeight = waveHeight
        logger:debug("Set wave size to %s", waveHeight)
    else
        if not mge.distantLandRenderConfig.waterWaveHeight == defaultWaveHeight then
            logger:debug("Resetting wave size")
            mge.distantLandRenderConfig.waterWaveHeight = defaultWaveHeight
        end
    end
end)

