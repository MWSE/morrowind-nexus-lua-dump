local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local anim = require("openmw.animation")

local REWARD_ANIM_DURATION = 4  -- tune to actual animation length

local function cleanup()
    if self:isActive() and not types.Actor.isDead(self.object) then
        self:enableAI(true)
        self.object:sendEvent("detd_SetIgnoreWeaponReaction", false)
    end
    core.sendGlobalEvent("BH_RequestRewardScriptRemoval", self.object)
end

local function playRewardAnimation()
    if types.Actor.isDead(self.object) then
        core.sendGlobalEvent("BH_RequestRewardScriptRemoval", self.object)
        return
    end

    self.object:sendEvent("detd_SetIgnoreWeaponReaction", true)

    self:enableAI(false)
    I.AnimationController.playBlendedAnimation("give01", {
        startKey = "start",
        stopKey  = "stop",
        priority = anim.PRIORITY.Scripted,
        speed    = 1,
    })

    async:newUnsavableSimulationTimer(REWARD_ANIM_DURATION, cleanup)
end

return {
    eventHandlers = {
        BH_PlayRewardAnimation = playRewardAnimation,
    },
}