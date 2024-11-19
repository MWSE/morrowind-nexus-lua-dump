--[[
Make creatures flee during the the comet event
]]

local common = require("mer.darkShard.common")
local logger = common.createLogger("animals")
local CometEffect = require("mer.darkShard.components.CometEffect")
local ShardCell = require("mer.darkShard.components.ShardCell")

local MAX_FLEE_CHANCE = 2.0

event.register(tes3.event.mobileActivated, function(e)
    if not CometEffect.isActive() then
        return
    end

    if ShardCell.isOnShard() then
        return
    end

    local isCreature = e.mobile.reference.baseObject.objectType == tes3.objectType.creature
    if not isCreature then
        return
    end

    if e.mobile.object.level > 10 then
        return
    end

    local chanceToFlee = MAX_FLEE_CHANCE * CometEffect.getEffectStrength()

    if math.random() < chanceToFlee then
        logger:debug("Fleeing %s", e.mobile.reference.object.id)
        e.mobile.flee = 100
    end
end)