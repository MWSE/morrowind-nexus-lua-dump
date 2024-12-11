local common = require("mer.darkShard.common")
local logger = common.createLogger("CometEffect")
---@class DarkShard.CometEffect.Condition
---@field id string --Unique identifier for the condition
---@field initEvents fun(callback: function) --Register events for this condition
---@field getEffectStrength function --Get the effect strength for this condition

---@class DarkShard.CometEffect
local CometEffect = {}

CometEffect.conditionChangedEvent = "DarkShard:CometEffectUpdate"

---@class DarkShard.CometEffect.ConditionChangedEventData
---@field condition DarkShard.CometEffect.Condition --The condition that triggered the event
---@field isActive boolean --True if the condition is active
---@field effectStrength number --The strength of the effect

--A list of conditions that must be met for the effect to be active
---@type table<string, DarkShard.CometEffect.Condition>
CometEffect.conditions = {}

function CometEffect.registerCondition(condition)
    CometEffect.conditions[condition.id] = condition
    if condition.initEvents then
        condition.initEvents(function()
            if not common.config.mcm.modEnabled then return end
            logger:trace("Condition %s changed", condition.id)
            logger:trace("- effectStrength: %s", CometEffect.getEffectStrength())
            event.trigger(CometEffect.conditionChangedEvent, {
                condition = condition,
                isActive = CometEffect.isActive(),
                effectStrength = CometEffect.getEffectStrength()
            })
        end)
    end
end

function CometEffect.isActive()
    if CometEffect.getEffectStrength() > 0 then
        return true
    end
    return false
end

--[[
    Effect of comet range from 0 to 1
]]
function CometEffect.getEffectStrength()
    local strength = 1
    for _, condition in pairs(CometEffect.conditions) do
        if condition.getEffectStrength then
            local conditionEffectStrength = condition.getEffectStrength()
            logger:trace("Condition %s effect strength: %s", condition.id, conditionEffectStrength)
            strength = strength * conditionEffectStrength
        end
    end
    return strength
end

return CometEffect