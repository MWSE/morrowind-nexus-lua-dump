
local common = require("mer.darkShard.common")
local logger = common.createLogger("aurora")
local CometEffect = require("mer.darkShard.components.CometEffect")
local ShardCell = require("mer.darkShard.components.ShardCell")
local shader = require("mer.darkShard.shaders.aurora")

local MIN_INTENSITY = 0.0
local MAX_INTENSITY = 1.0

---@param e DarkShard.CometEffect.ConditionChangedEventData
event.register(CometEffect.conditionChangedEvent, function(e)
    if e.isActive and not ShardCell.isOnShard() then
        local intensity = math.remap(e.effectStrength, 0, 1, MIN_INTENSITY, MAX_INTENSITY)
        intensity = math.clamp(intensity, 0, 1)
        logger:debug("Enabling Aurora Shader, setting intensity to %s", intensity)
        shader.enabled = true
        shader.Intensity = intensity
    elseif shader.enabled then
        logger:debug("Disabling Aurora Shader")
        shader.enabled = false
        shader.Intensity = 0
    end
end)

