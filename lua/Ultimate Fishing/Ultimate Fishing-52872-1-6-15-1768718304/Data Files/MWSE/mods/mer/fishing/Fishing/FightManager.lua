local common = require("mer.fishing.common")
local logger = common.createLogger("FightManager")
local config = require("mer.fishing.config")
local SwimService = require("mer.fishing.Fishing.SwimService")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local FishingNet = require("mer.fishing.FishingNet")
local FightIndicator = require("mer.fishing.ui.FightIndicator")
local FishingSkill = require("mer.fishing.FishingSkill")
local LureCamera = require("mer.fishing.Camera.LureCamera")
local DynamicCamera = require("mer.fishing.Camera.DynamicCamera")
local Animations = require("mer.fishing.Fish.Animations")

---@class Fishing.FightManager.new.params
---@field fish Fishing.FishType.instance The fish to fight
---@field lure tes3reference The lure used to catch the fish
---@field callback fun(self: Fishing.FightManager, succeeded: boolean, failMessage?: string) The callback to run when the fight is over

---@class Fishing.FightManager : Fishing.FightManager.new.params
---@field targetPosition? tes3vector3
---@field reeling boolean if the player is actively reeling in the fish
---@field lineLength number how mich fishing line is out
---@field fightIndicator Fishing.FightIndicator
---@field playerFatigue number accululation of fatigue drain, when it reaches one, subtract it from the player
---@field rodDamage number accumulation of rod damage, when it reaches one, subtract it from the rod
---@field fishPhysics table<number, Fishing.FishPhysics> physics for each fish
---@field ended boolean whether the fight has ended
---@field dynamicCamera Fishing.DynamicCamera
---@field splashTimer mwseTimer
local FightManager = {
    offsetUp = 40,
    lureOffset = 30
}
local simulateFight



---@param e Fishing.FightManager.new.params
---@return Fishing.FightManager
function FightManager.new(e)
    ---@type Fishing.FightManager
    local self = setmetatable({}, { __index = FightManager })
    self.fish = e.fish
    self.lure = e.lure
    self.fightIndicator = FightIndicator:new{
        fightManager = self
    }
    self.callback = e.callback
    self.reeling = false
    self.lineLength = 0
    self.playerFatigue = 0
    self.rodDamage = 0
    self.fishPhysics = {}
    self.ended = false
    local lureCamera = LureCamera:new({
        positionLockTarget = self.lure,
        angleLockTarget = tes3.player,
        offsetBack = 250,
        offsetUp = FightManager.offsetUp,
        grounded = self.fish.fishType.heightAboveGround ~= nil
    })
        :setPositionLockTarget(self.lure)
        :setAngleLockTarget(tes3.player)
        :setOffsetBack(250)
        :setOffsetUp(FightManager.offsetUp)
    self.dynamicCamera = DynamicCamera:new{
        camera = lureCamera,
        changeFrequencySeconds = 2,
        changeVariance = 0.05,
        startingState = tes3.player.mobile.is3rdPerson and "ThirdPerson" or "FirstPerson"
    }
    return self
end

function FightManager:endFight()
    self.dynamicCamera:stop()
    FishingRod.stopReelSound()
    event.unregister("simulate", simulateFight)
    self.reeling = nil
    if self.fightIndicator then
        self.fightIndicator:destroy()
        self.fightIndicator = nil
    end
    self.ended = true
    if self.splashTimer then
        self.splashTimer:cancel()
        self.splashTimer = nil
    end
end

function FightManager:fail(reason, didSnap)
    if self.ended then return end
    logger:debug("Fight failed: %s", reason)

    self:endFight()
    self:callback(false, reason)
    self.reeling = nil
    if didSnap then
        tes3.playSound{
            reference = tes3.player,
            sound = "mer_fish_snap",
        }
        tes3.playVoiceover({ actor = tes3.player, voiceover = tes3.voiceover.hit })
        tes3.playAnimation({
            reference = tes3.player,
            group = math.random(tes3.animationGroup.hit1, tes3.animationGroup.hit5),
        })
    end
end

---Called when the player wins the fight
function FightManager:success()
    if self.ended then return end
    logger:debug("Fight succeeded")
    self:endFight()
    self:splash(1.5)
    self:callback(true)
end

---Get the effect of the player's strength on how much distance
---is reduced when reeling in
local function getPlayerStrengthEffect()
    local strength = tes3.mobilePlayer.strength.current
    local effect = math.remap(strength, 0, 100, 0.75, 1.25)
    logger:debug("Strength effect: %s", effect)
    return effect
end


---Get the distance modifier for selecting a new target position
---This is based on the strength of the fish and the player, as
---well as the tension of the line and whether the player is reeling
function FightManager:getDistanceModifier()
    local fish = FishingStateManager.getCurrentFish()
    if not fish then
        logger:warn("Fish not found")
        return 0
    end

    --Distance based on fish strength and fatigue
    local fishDistanceModifier = fish:getDistanceModifier()

    --When tension is high, reduce fish's pull
    local tensionEffect = math.remap(FishingStateManager.getTension(),
        config.constants.TENSION_MINIMUM,
        config.constants.TENSION_MAXIMUM,
        1.0,
        config.constants.FIGHT_TENSION_DISTANCE_EFFECT_MAXIMUM
    )
    local fishPullDistance = -(fishDistanceModifier * tensionEffect)

    --When reeling, pull towards player
    local reelingDistance = (self.reeling == true)
        and (config.constants.FIGHT_REELING_DISTANCE_EFFECT * getPlayerStrengthEffect())
        or 0

    local distanceTowardsPlayer = fishPullDistance + reelingDistance
    return distanceTowardsPlayer
end

function FightManager:pickTargetPosition()
    logger:debug("Picking target position")
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("pickTargetPosition(): Lure not found")
        return
    end

    local maxDistance = config.constants.FIGHT_POSITION_MAX_DISTANCE  * (1 + math.log10(self.fish.fishType.size))
    local waterLevel = lure.cell.waterLevel or 0

    local targetPosition = SwimService.findTargetPosition{
        origin = tes3vector3.new(lure.position.x, lure.position.y, waterLevel),
        minDistance = config.constants.FIGHT_POSITION_MIN_DISTANCE,
        maxDistance = maxDistance,
    }
    if not targetPosition then
        logger:error("No target position found")
        return
    end

    ---Distance towards player to move the target position. Can be negative if fish is pulling harder than player
    local distanceTowardsPlayer = self:getDistanceModifier()
    local positionTowardsPlayer = SwimService.findPositionTowardsPlayer(targetPosition:copy(), distanceTowardsPlayer)
    if positionTowardsPlayer then
       logger:debug("Moving position %s units towards the player", distanceTowardsPlayer)
       targetPosition = positionTowardsPlayer
    else
       logger:warn("No position found towards the player")
    end
    logger:debug("Target position: %s", targetPosition)
    self.targetPosition = targetPosition
end


--[[
    Get the distance between the lure and the target position
]]
function FightManager:getLineDistance()
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("getLineDistance(): Lure not found")
        self:fail()
        return 0
    end
    local lurePosition = lure.position
    --local rodPosition = FishingRod.getPoleEndPosition()
    local rodPosition = tes3.player.position
    return lurePosition:distance(rodPosition)
end


--[[
    Compare the current Line length to the current distance,
    and set the tension accordingly
]]
function FightManager:updateTension()
    local lineLength = self.lineLength
    local actualLineLength = self:getLineDistance()
    local difference = actualLineLength - lineLength

    --At 500 units, tension is increased by 0.5
    local maxDistance = config.constants.FIGHT_MAX_DISTANCE
    --Higher skill, higher distance allowance
    local skill = FishingSkill.getCurrent()
    local skillDistanceEffect = math.remap(skill,
        0, 100,
        0.75, 1.25
    )
    maxDistance = maxDistance * skillDistanceEffect

    local neutralMaxDiff = config.constants.FIGHT_TENSION_UPPER_LIMIT
        - config.constants.TENSION_NEUTRAL

    local effect = math.remap(difference, 0, maxDistance, 0, neutralMaxDiff)
    local tension = config.constants.TENSION_NEUTRAL + effect

    --Line can only snap when reeling
    local upperLimit = config.constants.FIGHT_TENSION_UPPER_LIMIT * 0.99
    if (self.reeling ~= true) and (tension > upperLimit) then
        tension = upperLimit
    end

    --Line can only go loose when not reeling
    local lowerLimit = config.constants.FIGHT_TENSION_LOWER_LIMIT * 1.01
    if (self.reeling == true) and (tension < lowerLimit) then
        tension = lowerLimit
    end

    if config.mcm.cheatMode then
        tension = math.clamp(tension, lowerLimit, upperLimit)
    end
    FishingStateManager.setTension(tension)

    logger:trace([[
        lineLength: %s
        actualLineLength: %s
        difference: %s
        effect: %s
        neutral: %s
        tension: %s
    ]], lineLength, actualLineLength, difference, effect, config.constants.TENSION_NEUTRAL, tension)

end


---Check if the fish is still swimming,
---If it has reached its last swim position,
---pick a new position and start swimming again
function FightManager:updateSwimming()
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:debug("updateSwimming(): Lure not found")
        self:fail()
        return false
    end
    local lastSwimFinished = not self.targetPosition
    if lastSwimFinished then
        logger:debug("Last swim finished, finding a new position")
        self:pickTargetPosition()
        if not self.targetPosition then
            logger:error("updateSwimming(): No target position found")
            self:fail("Line Snagged!", true)
            return false
        end
        SwimService.startSwimming{
            speed = self.fish:getReelSpeed(),
            turnSpeed = self.fish:getTurnSpeed(),
            physics = self.fishPhysics,
            from = lure.position,
            to = self.targetPosition,
            lure = lure,
            callback = function()
                self.targetPosition = nil
            end,
            heightAboveGround = self.fish.fishType.heightAboveGround
        }
        self:splash()
    end
    return true
end

function FightManager:changeLineLength(change)
    logger:trace("updating line length by %s", change)
    self.lineLength = math.max(self.lineLength + change, config.constants.TENSION_NEUTRAL)
end

function FightManager:updateLineLength(delta)
    if self.reeling then
        local change = delta * -config.constants.REEL_LENGTH_PER_SECOND
        logger:trace("Reeling: %s", change)
        self:changeLineLength(change)
    else
        local change = delta * config.constants.RELAX_LENGTH_PER_SECOND
        logger:trace("Relaxing: %s", change)
        self:changeLineLength(change)
    end
end

---Reduce the fish's fatigue during the fight
---
---Loses fatigue faster when tension is high
---and when player strength is high
function FightManager:tireFish(delta)
    local fatigueDrain = config.constants.FIGHT_FATIGUE_DRAIN_PER_SECOND

    ---Tension Effect
    local tension = FishingStateManager.getTension()
    local maxTension = config.constants.FIGHT_TENSION_UPPER_LIMIT
    local minTension = config.constants.FIGHT_TENSION_LOWER_LIMIT
    local tensionEffect = math.remap(tension, minTension, maxTension, 0.0, 2.0)

    ---Strength Effect
    local strength = tes3.player.mobile.strength.current
    local strengthEffect = math.remap(strength, 0, 100, 0.75, 1.25)

    ---How much to reduce fatigue by
    local drain = fatigueDrain  * tensionEffect * strengthEffect * delta

    logger:trace("Draining fatigue by: %s", drain)
    self.fish.fatigue = self.fish.fatigue - drain
    logger:trace("Fish fatigue: %s", self.fish.fatigue)
end

---Reduce the player's fatigue during the fight
---
---While Reeling:
--- Loses fatigue faster when tension is high
--- and when fish strength (difficulty) is high
---
---While not Reeling:
--- Loses fatigue at a constant rate
---
---The fatigue change is cached so that it can be
---applied with modStatistic when it is greater than 1,
---so that partial fatigue loss is not lost
function FightManager:tirePlayer(delta)
    local change = 0
    if not self.reeling then
        change = config.constants.FIGHT_PLAYER_FATIGUE_RELAX_DRAIN_PER_SECOND * delta
    else
        ---Fish Strength Effect
        local fishStrength = self.fish.fishType.difficulty
        local fishStrengthEffect = math.remap(fishStrength, 0, 100, 0.5, 1.5)

        ---Tension Effect
        local tension = FishingStateManager.getTension()
        local maxTension = config.constants.FIGHT_TENSION_UPPER_LIMIT
        local minTension = config.constants.FIGHT_TENSION_LOWER_LIMIT
        local tensionEffect  = math.remap(tension, minTension, maxTension, 0.0, 2.0)

        change = config.constants.FIGHT_PLAYER_FATIGUE_REELING_DRAIN_PER_SECOND
            * tensionEffect * fishStrengthEffect * delta
        logger:trace([[
            Fish strength: %s
            Fish strength effect: %s
            Tension effect: %s
            Change: %s
            Player fatigue: %s
        ]], fishStrength,
            fishStrengthEffect,
            tensionEffect,
            change,
            self.playerFatigue
        )
    end
    self.playerFatigue = self.playerFatigue + change
    if self.playerFatigue > 1 then
        logger:trace("Draining player fatigue by: %s", self.playerFatigue)
        tes3.modStatistic{
            reference = tes3.player,
            name = "fatigue",
            current = -self.playerFatigue
        }
        self.playerFatigue = 0
    end
end

---While reeling in, damage rod based on fish strength
---
---The damage change is cached so that it can be
---applied with FishingRod:degrade() when it is greater than 1,
---so that partial damage is not lost
function FightManager:damageRod(delta)
    local change = 0
    if self.reeling then
        local fishStrength = self.fish.fishType.difficulty
        local fishStrengthEffect = math.remap(fishStrength, 0, 100, 0.5, 1.5)

        change = config.constants.FIGHT_ROD_DAMAGE_PER_SECOND
            * fishStrengthEffect * delta

        self.rodDamage = self.rodDamage + change
        if self.rodDamage > 1 then
            logger:trace("Damaging rod by: %s", self.rodDamage)
            local rod = FishingRod:getEquipped()
            if rod then
                rod:degrade(self.rodDamage)
                self.rodDamage = 0
            end
        end
    end
end


---Get the fatigue level required to catch the fish
---This is 0 unless the player has a fishing net.
function FightManager:getFishFatigueLimit()
    if FishingNet.playerHasNet() then
        return self.fish.fishType:getStartingFatigue() / 10
    else
        return 0
    end
end


function FightManager:updateDynamicCamera()
    local currentFatigue = self.fish.fatigue
    local maxFatigue = self.fish.fishType:getStartingFatigue()
    self.dynamicCamera.changeFrequencySeconds = math.remap(currentFatigue, 0, maxFatigue, 3.0, 6.0)
end

---Simulate the fight
---@param e simulateEventData
function FightManager:fightSimulate(e)
    self:updateDynamicCamera()
    self:updateTension()
    if not self:updateSwimming() then return end
    --keybind test for left click
    local inputController = tes3.worldController.inputController
    local leftMouseDown = inputController:isMouseButtonDown(0)
    local rightMouseDown = inputController:isMouseButtonDown(1)
    --local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if rightMouseDown then
        --cancel
        logger:debug("fightSimulate(): Cancelling on right click")
        self:fail()
    elseif leftMouseDown and not self.reeling then
        logger:debug("fightSimulate(): Started Reeling")
        self.reeling = true
        FishingRod.playReelSound{
            doLoop = true,
            pitch = 1.5
        }
    elseif self.reeling and not leftMouseDown then
        logger:debug("fightSimulate(): Stopped Reeling")
        self.reeling = false
        FishingRod.playReelSound{
            doLoop = true,
        }
    end

    self:tireFish(e.delta)
    self:tirePlayer(e.delta)
    self:damageRod(e.delta)
    self:updateLineLength(e.delta)

    local tension = FishingStateManager.getTension() or 0
    if tension then
        if tension >= config.constants.FIGHT_TENSION_UPPER_LIMIT then
            logger:trace("Snap Tension: %s", tension)
            self:fail("Line Snapped!", true)
            return
        end
        if tension <= config.constants.FIGHT_TENSION_LOWER_LIMIT then
            logger:trace("Escape Tension: %s", tension)
            self:fail("Fish Escaped!")
            return
        end
    end
    if self.fish.fatigue <= self:getFishFatigueLimit() then
        self:success()
        return
    end

    if tes3.player.mobile.fatigue.current <= 0 then
        --make sure the player falls over
        tes3.setStatistic{
            reference = tes3.player,
            name = "fatigue",
            current = -5
        }
        self:fail("You are exhausted!")
        return
    end
end

function FightManager:startSplashTimer()
    local interval = math.random(3, 5)
    self.splashTimer = timer.start{
        duration = interval,
        callback = function()
            logger:debug("Splash timer elapsed")
            self:splash()
            self:startSplashTimer()
        end
    }
end

function FightManager:splash(sizeMulti)
    sizeMulti = sizeMulti or 1
    Animations.splash(self.lure.position, self.fish:getSplashSize() * sizeMulti)
    Animations.playSplashSound{
        volume = sizeMulti
    }
end

---Start the fight
function FightManager:start()
    --drop lure down
    self.lure.position = self.lure.position + tes3vector3.new(0, 0, -FightManager.lureOffset)

    --Ground fish first so tension doesn't suddenly change
    if self.fish.fishType.heightAboveGround then
        SwimService.groundFish(self.lure, self.fish.fishType.heightAboveGround)
    end

    FishingRod.playReelSound{ doLoop = true }
    FishingStateManager.setState("REELING")
    if not self:updateSwimming() then return end
    self.lineLength = self:getLineDistance()


    FishingStateManager.lerpTension(
        FishingStateManager.getTension(),
        config.constants.TENSION_NEUTRAL)

    tes3.messageBox("You've hooked something!")
    logger:debug([[
        Starting Fish Fight!
        The Challenger: %s
        The Defender: %s

        Player fatigue: %s
        Fish fatigue: %s
    ]],
        tes3.player.object.name,
        self.fish.fishType:getBaseObject().name,
        tes3.mobilePlayer.fatigue.current,
        self.fish.fatigue
    )

    simulateFight = function(e)
        local currentState = FishingStateManager.getCurrentState()
        if currentState ~= "REELING" then
            self:fail("No longer reeling")
            return
        end
        self:fightSimulate(e)
    end



    event.register("simulate", simulateFight)
    self.fightIndicator:createMenu()
    common.disablePlayerControls()

    self.dynamicCamera:start()

    local doCancel
    doCancel = function()
        if FishingStateManager.isState("REELING") then
            self:fail("Cancelled")
        end
        event.unregister("Fishing:Cancel", doCancel)
    end
    event.register("Fishing:Cancel", doCancel)

    self:startSplashTimer()
end


return FightManager