---@omw-context local
local I                = require("openmw.interfaces")
local core             = require('openmw.core')
local self             = require('openmw.self')
local anim             = require('openmw.animation')
local types            = require('openmw.types')
local Constants        = require('scripts.canttouchthis.helpers.constants')
local isDead           = types.Actor.isDead
local isFleeing        = I.AI.isFleeing
local getActivePackage = I.AI.getActivePackage
local random           = math.random
local releaseActor     = false
local isStaggered      = false
local fatigue          = self.type.stats.dynamic.fatigue(self)
local activeEffects    = self.type.activeEffects(self)
local getStance        = types.Actor.getStance


local function isAnimationPlaying(checkFor)
    if type(checkFor) == "table" then
        for _, animation in ipairs(checkFor) do
            if anim.getActiveGroup(self, anim.BONE_GROUP.RightArm) == animation or
                anim.getActiveGroup(self, anim.BONE_GROUP.LeftArm) == animation or
                anim.getActiveGroup(self, anim.BONE_GROUP.Torso) == animation or
                anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody) == animation then
                return true
            end
        end
    elseif type(checkFor) == "string" then
        if anim.getActiveGroup(self, anim.BONE_GROUP.RightArm) == checkFor or
            anim.getActiveGroup(self, anim.BONE_GROUP.LeftArm) == checkFor or
            anim.getActiveGroup(self, anim.BONE_GROUP.Torso) == checkFor or
            anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody) == checkFor then
            return true
        end
    end
    return false
end

local function checkStaggerState()
    if (getStance(self) == types.Actor.STANCE.Weapon) then
        if activeEffects:getEffect(core.magic.EFFECT_TYPE.Paralyze).magnitude > 0 or
            isAnimationPlaying(Constants.staggerAnimations) or
            fatigue.current < 0 then
            isStaggered = true
            return
        end
    end
    isStaggered = false
end

I.Combat.addOnHitHandler(function(attack)
    if not releaseActor then -- turning the onHitHandler into noop if the script is detached
        if not attack.successful then
            local dodgeAnimations = Constants.h2hdodgeAnimations
            local dodge = dodgeAnimations[random(1, #dodgeAnimations)]
            I.AnimationController.playBlendedAnimation(dodge, {
                startKey = 'start',
                stopKey = 'stop',
                priority = Constants.dodgePriority,
                autoDisable = true,
                blendMask = Constants.dodgeBlendMask,
                speed = 1
            })
        end
    end
end)

local function onUpdate(dt)
    if core.isWorldPaused() then return end
    --#endregion
    local activeAIPackage = getActivePackage()
    if isDead(self) or
        isFleeing() or
        releaseActor or
        (activeAIPackage and (activeAIPackage.type:lower() == "cast" or
            activeAIPackage.type:lower() == "unknown")) then
        if isStaggered == true then
            isStaggered = false
        end
        return
    end
    checkStaggerState()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
