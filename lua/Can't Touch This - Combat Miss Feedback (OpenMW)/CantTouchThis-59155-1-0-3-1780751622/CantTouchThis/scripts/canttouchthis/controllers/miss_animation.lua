---@omw-context local
local types                       = require('openmw.types')
local Constants                   = require('scripts.canttouchthis.helpers.constants')
local I                           = require('openmw.interfaces')
local random                      = math.random


local missAnimationController = {}

function missAnimationController.playMissAnimation(parent,attack)
    if (not attack.successful) or attack.ngarde_glancing then
        if not parent.isStaggered then
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
end

return missAnimationController