local common = require("mer.fishing.common")
local logger = common.createLogger("Animations")
local RippleGenerator = require("mer.fishing.Fishing.RippleGenerator")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
---@class Fishing.Animations
local Animations = {}

function Animations.playSplashSound()
    logger:debug("Playing splash sound")
    local sound = (math.random() < 0.5)
        and "Swim Left" or "Swim Right"
    tes3.playSound{ sound = sound }
end

function Animations.splash(position, size)
    logger:debug("Generating Splash")
    --Create Splash
    local splash = tes3.getObject("mer_fish_splash") --[[@as tes3activator]]
    tes3.createVisualEffect({
        object = splash,
        position = position,
        repeatCount = 1,
        scale = size or 1,
    })
end

function Animations.lureLand(lure)
    tes3.playAnimation{
        reference = lure,
        group = tes3.animationGroup.idle,
        loopCount = -1,
    }

    Animations.playSplashSound()
    Animations.splash(lure.position)
    RippleGenerator.generateRipple{
        position = lure.position,
        scale = 2.5,
        -- duration = 1.0,
        -- amount = 20,
    }
end

function Animations.lureNibble(lure)
    logger:debug("Playing nibble animation")
    tes3.playAnimation{
        reference = lure,
        group = tes3.animationGroup.idle3,
        startFlag = tes3.animationStartFlag.immediate,
        loopCount = 0,
    }
    tes3.playAnimation{
        reference = lure,
        group = tes3.animationGroup.idle,
        startFlag = tes3.animationStartFlag.normal,
        loopCount = -1,
    }
    RippleGenerator.generateRipple{
        position = lure.position,
        scale = 1,
        -- duration = 1.0,
        -- amount = 20,
    }
    Animations.playSplashSound()
end

function Animations.lureBite(lure)
        --Animate lure
        tes3.playAnimation{
            reference = lure,
            group = tes3.animationGroup.idle2,
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 0,
        }
        tes3.playAnimation{
            reference = lure,
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.normal,
            loopCount = -1,
        }
        Animations.splash(lure.position)
        RippleGenerator.generateRipple{
            position = lure.position,
            scale = 1.5,
            -- duration = 1.0,
            -- amount = 20,
        }
        Animations.playSplashSound()
end

function Animations.clampWaves()
    if FishingStateManager.getPreviousWaveHeight() then return end
    if mge.render.dynamicRipples then
        local height = mge.distantLandRenderConfig.waterWaveHeight
        FishingStateManager.setPreviousWaveHeight(height)
        local duration = 0.5
        local iterations = duration / 0.01

        local from = height
        local to = 0.0

        timer.start{
            iterations = iterations,
            duration = duration / iterations,
            callback = function(e)
                local newHeight = math.lerp(
                    to,
                    from,
                    e.timer.iterations / iterations
                )
                logger:trace("Setting wave height to %s", newHeight)
                mge.distantLandRenderConfig.waterWaveHeight = newHeight
            end
        }
    end
end


function Animations.reverseSwing()
    logger:debug("Playing snap animation")
    --cancelling swing animation
    timer.start{
        duration = 0.2,
        callback = function()
            tes3.mobilePlayer.animationController.weaponSpeed = -tes3.mobilePlayer.animationController.weaponSpeed
            timer.start{duration = 0.2, callback = function()
                tes3.mobilePlayer.actionData.animationAttackState = tes3.animationState.idle
                tes3.mobilePlayer.animationController.weaponSpeed = 1
            end}
        end
    }
end

function Animations.unclampWaves()
    local previousWaveHeight = FishingStateManager.getPreviousWaveHeight()
    if not previousWaveHeight then return end
    local currentWaveHeight = mge.distantLandRenderConfig.waterWaveHeight
    --smooth transition
    local duration = 0.5
    local iterations = duration / 0.01
    local from = currentWaveHeight
    local to = previousWaveHeight
    timer.start{
        iterations = iterations,
        duration = duration / iterations,
        callback = function(e)
            local newHeight = math.lerp(
                to,
                from,
                e.timer.iterations / iterations
            )
            logger:trace("Re-Setting wave height to %s", newHeight)
            mge.distantLandRenderConfig.waterWaveHeight = newHeight
        end
    }
    timer.start{
        duration = duration,
        callback = function()
            FishingStateManager.setPreviousWaveHeight(nil)
        end
    }
end
event.register("Fishing:UnclampWaves", Animations.unclampWaves)


return Animations