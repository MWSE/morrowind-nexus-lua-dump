local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("AnimatedActivator")
local ANIM_TIMER_EVENT = "JOP:AnimatedActivator:playAnimation:timer"

local AnimatedActivator = {
    ---@type JoyOfPainting.AnimatedActivator[]
    activators = {}
}

---@class JoyOfPainting.AnimatedActivator.callbackParams
---@field target tes3reference?
---@field item tes3item?
---@field itemData tes3itemData?
---@field ownerRef tes3reference? The owner of the itemStack

---
---@class JoyOfPainting.AnimatedActivator
---@field id? string
---@field onActivate fun(e:JoyOfPainting.AnimatedActivator.callbackParams)
---@field onPickup? fun(e:JoyOfPainting.AnimatedActivator.callbackParams)
---@field isActivatorItem fun(e:JoyOfPainting.AnimatedActivator.callbackParams):boolean
---@field blockStackActivate? boolean
---@field getAnimationGroup? fun(reference:tes3reference):number? Returns the current active animation group to play


---@param activator JoyOfPainting.AnimatedActivator
function AnimatedActivator.registerActivator(activator)
    logger:assert(type(activator.onActivate) == "function", "onActivate must be a function")
    logger:assert(type(activator.isActivatorItem) == "function", "isActivatorItem must be a function")
    table.insert(AnimatedActivator.activators, activator)
end

---@param e activateEventData
function AnimatedActivator.doBlockActivate(e)
    if e.activator ~= tes3.player then
        logger:debug("Not player, skip")
        return true
    end

    return false
end

local function animationCallback(e)
    local reference, nextAnimation = unpack(e.timer.data)
    logger:debug("Animation callback")
    if e.nextAnimation then
        logger:debug("Playing next animation %s", nextAnimation)
        tes3.playAnimation{
            reference = reference,
            group = nextAnimation,
            startFlag = tes3.animationStartFlag.normal,
            loopCount = 0,
        }
    end
    logger:debug("Unblocking activate")
    common.unblockActivate()
end
timer.register(ANIM_TIMER_EVENT, animationCallback)

---@class JOP.AnimatedActivator.playAnimation.params
---@field reference tes3reference? Reference to play the animation on
---@field group table? Animation group to play
---@field sound string? Sound to play
---@field duration number? Duration of the animation
---@field callback function? Called after the animation is done
---@field nextAnimation number? The animation to play if this one is interrupted by save/load

---@param e JOP.AnimatedActivator.playAnimation.params
function AnimatedActivator.playActivatorAnimation(e)

    logger:debug("Playing animation %s for %s", e.group.group, e.reference)
    --play animation
    tes3.playAnimation{
        reference = e.reference,
        group = e.group.group,
        startFlag = tes3.animationStartFlag.immediate,
        loopCount = 0,
    }
    if e.sound then
        tes3.playSound{
            reference = e.reference,
            sound = e.sound,
        }
    end
    if e.group.duration then
        common.blockActivate()
        --persistent timer to play the next animation
        timer.start{
            duration = e.group.duration,
            type = timer.simulate,
            callback = ANIM_TIMER_EVENT,
            data = { e.reference, e.nextAnimation},
            persist = true,
        }
        --non persistent timer to do custom calback
        timer.start{
            duration = e.group.duration,
            type = timer.real,
            callback = function()
                logger:debug("Animation timer callback")
                if e.callback then
                    logger:debug("Calling callback")
                    e.callback()
                end
            end,
        }
    end
end

return AnimatedActivator