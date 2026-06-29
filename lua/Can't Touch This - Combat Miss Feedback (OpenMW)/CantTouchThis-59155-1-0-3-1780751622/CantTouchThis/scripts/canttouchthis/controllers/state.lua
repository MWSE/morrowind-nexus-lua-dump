---@omw-context local
local core           = require('openmw.core')
local types          = require('openmw.types')
local Constants      = require('scripts.canttouchthis.helpers.constants')
local actorSelf      = require('openmw.self')
local anim           = require('openmw.animation')
local getStance      = types.Actor.getStance
local activeEffects  = actorSelf.type.activeEffects(actorSelf)
local fatigue        = actorSelf.type.stats.dynamic.fatigue(actorSelf)
local missAnimator   = require('scripts.canttouchthis.controllers.miss_animation')

local stateManager   = {}
stateManager.__index = stateManager

function stateManager.new()
    local self = setmetatable({}, stateManager)
    self.isStaggered = false
    return self
end

function stateManager.isAnimationPlaying(checkFor)
    if type(checkFor) == "table" then
        for _, animation in ipairs(checkFor) do
            if anim.getActiveGroup(actorSelf, anim.BONE_GROUP.RightArm) == animation or
                anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LeftArm) == animation or
                anim.getActiveGroup(actorSelf, anim.BONE_GROUP.Torso) == animation or
                anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LowerBody) == animation then
                return true
            end
        end
    elseif type(checkFor) == "string" then
        if anim.getActiveGroup(actorSelf, anim.BONE_GROUP.RightArm) == checkFor or
            anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LeftArm) == checkFor or
            anim.getActiveGroup(actorSelf, anim.BONE_GROUP.Torso) == checkFor or
            anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LowerBody) == checkFor then
            return true
        end
    end
    return false
end

function stateManager.checkStaggerState(self)
    if (getStance(actorSelf) == types.Actor.STANCE.Weapon) then
        if activeEffects:getEffect(core.magic.EFFECT_TYPE.Paralyze).magnitude > 0 or
            self.isAnimationPlaying(Constants.staggerAnimations) or
            fatigue.current < 0 then
            self.isStaggered = true
            return
        end
    end
    self.isStaggered = false
end

stateManager.playMissAnimation = function (self,attack)
    missAnimator.playMissAnimation(self,attack)
end

return stateManager
