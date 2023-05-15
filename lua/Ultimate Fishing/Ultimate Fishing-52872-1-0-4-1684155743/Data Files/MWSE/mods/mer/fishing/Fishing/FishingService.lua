local common = require("mer.fishing.common")
local logger = common.createLogger("FishingService")
local config = require("mer.fishing.config")
local FishingSpot = require("mer.fishing.Fishing.FishingSpot")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local SwimService = require("mer.fishing.Fishing.SwimService")
local FishGenerator = require("mer.fishing.Fish.FishGenerator")
local TrophyMenu = require("mer.fishing.ui.TrophyMenu")
local LineManager = require("mer.fishing.FishingLine.LineManager")
local Animations = require("mer.fishing.Fish.Animations")
local FightManager = require("mer.fishing.Fishing.FightManager")
local Bait = require("mer.fishing.Bait.Bait")
local FishingSkill = require("mer.fishing.FishingSkill")

---@class Fishing.FishingService
local FishingService = {}




---@param lure tes3reference
---@param landCallback function
local function launchLure(lure, landCallback)
    do --update speed opn object (TODO: Fix this with praticle bindings later)
        local mesh = tes3.loadMesh("mer_fishing\\LureParticle.nif")
        local particles = mesh:getObjectByName("Particles")

        local castStrength = FishingStateManager.getCastStrength()
        particles.controller.speed = math.remap(castStrength, 0, 1,
            config.constants.MIN_CAST_SPEED, config.constants.MAX_CAST_SPEED)
    end

    local vfx = tes3.createVisualEffect{
        object = "mer_lure_particle",
        position = lure.position,
    }
    FishingStateManager.setParticle(vfx.effectNode)
    local effectNode = vfx.effectNode
    local particles = effectNode:getObjectByName("Particles") --[[@as niParticles]]
    local controller = particles.controller --[[@as niParticleSystemController]]

    effectNode.rotation:toRotationZ(tes3.player.orientation.z)

    logger:debug("Setting lure speed to %s", controller.speed)

    local safeLure = tes3.makeSafeObjectHandle(lure)
    local safeParticle = tes3.makeSafeObjectHandle(vfx)
    local updateLurePosition

    local function finish(success)
        event.unregister("simulate", updateLurePosition)
        if success then
            landCallback()
        else
            FishingStateManager.endFishing()
        end
    end

    updateLurePosition = function()
        if not (safeLure and safeLure:valid()) then
            logger:debug("Lure is not valid, stopping updateLurePosition")
            finish(false)
            return
        end
        if not (safeParticle and safeParticle:valid()) then
            logger:debug("Particle is not valid, stopping updateLurePosition")
            finish(false)
            return
        end
        local transform = vfx.effectNode.worldTransform
        local vertex = particles.data.vertices[1]
        lure.position = transform * vertex

        --check for collision with ground
        local result = tes3.rayTest{
            position = lure.position + tes3vector3.new(0, 0, 10),
            direction = tes3vector3.new(0, 0, -1),
            ignore = { lure },
        }
        if result then
            local hitGround =  result.intersection.z > lure.cell.waterLevel
                and result.distance < 10
            if hitGround then
                logger:debug("Lure hit ground, stopping updateLurePosition")
                finish(false)
                return
            end
        end
        if lure.position.z < lure.cell.waterLevel then
            local pos = tes3vector3.new(lure.position.x, lure.position.y, lure.cell.waterLevel)

            if FishingSpot.getDepth(pos, {lure, vfx.effectNode}) < config.constants.MIN_DEPTH then
                logger:debug("Lure is not deep enough, stopping updateLurePosition")
                finish(false)
                tes3.messageBox("Not deep enough.")
            else
                logger:debug("Lure is underwater, stopping updateLurePosition")
                finish(true)
            end
        end
    end
    event.register("simulate", updateLurePosition)
end

local function spawnLure(lurePosition)
    logger:debug("Spawning lure")
    if not lurePosition then
        logger:error("Could not get lure position")
        return
    end
    local fishingRod = FishingRod.getEquipped()
    if not fishingRod then
        logger:error("Could not get fishing rod")
        return
    end
    logger:debug("Attaching bait mesh")
    local bait = fishingRod:getEquippedBait()
    if not bait then
        logger:debug("No bait equipped, spawning default lure bait")
        bait = Bait.get("mer_lure_01")
        if not bait then
            logger:error("Could not get default lure bait")
            return
        end
    end
    local lure = tes3.createReference({
        object = "mer_lure_anim",
        position = lurePosition,
        cell = tes3.player.cell,
    })
    bait:attachToAnim(lure)
    FishingStateManager.setLure(lure)
    return lure
end

---Cast a line if player attacks with a fishing rod
local function startCasting()
    logger:debug("Casting fishing rod")
    local lurePosition = FishingRod.getPoleEndPosition()
    local lure = spawnLure(lurePosition)
    if lure then
        FishingStateManager.setCastStrength()
        local castStrength = FishingStateManager.getCastStrength()
        FishingRod.playCastSound(castStrength)
        Animations.clampWaves()
        -- common.disablePlayerControls()
        FishingStateManager.setState("CASTING")
        launchLure(lure, function()
            Animations.lureLand(lure)
            logger:debug("Finished casting")
            FishingStateManager.setState("WAITING")
            FishingSkill.landLure()
        end)
        timer.start{
            duration = 0.1,
            callback = function()
                lure = FishingStateManager.getLure()
                if lure then
                    FishingStateManager.setFishingLine(LineManager.attachLines(lure))
                end
            end
        }
    else
        logger:error("Could not spawn lure")
        FishingStateManager.endFishing()
    end
end



local function endBite()
    local state = FishingStateManager.getCurrentState()
    if state == "BITING" then
        logger:debug("Fish stopped biting")
        FishingStateManager.setState("WAITING")
    else
        logger:debug("Not biting, state is %s", state)
    end
end

local function realBite()
    logger:debug("Fish is biting")
    FishingStateManager.setState("BITING")
    local lure = FishingStateManager.getLure()
    if lure then
        logger:debug("Playing bite animation")
        Animations.lureBite(lure)
        timer.start{
            duration = FishingService.getBiteDuration(),
            callback = function()
                endBite()
            end
        }
    end
end


local function startFish()
    logger:debug("Starting fish")
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("No lure found")
        return
    end
    local depth = FishingSpot.getDepth(lure.position)
    local fish = FishGenerator.generate{ depth = depth }
    if not fish then
        logger:warn("Unable to generate fish")
        return
    end
    FishingStateManager.setActiveFish(fish)


    local to = lure.position
    local min, max = fish.fishType:getStartDistance()
    local from = SwimService.findTargetPosition{
        origin = to,
        minDistance = min,
        maxDistance = max,
    }
    if from then
        FishingStateManager.setState("CHASING")
        SwimService.startSwimming{
            speed = fish:getChaseSpeed(),
            turnSpeed = 5.0,
            from = from,
            to = to,
            callback = function()
                timer.start{
                    duration = 0.4,
                    callback = realBite
                }
            end
        }
    else
        logger:warn("Unable to find start position")
    end
end

function FishingService.triggerFish()
    local state = FishingStateManager.getCurrentState()
    if state == "WAITING" then
        if FishingService.calculateRealBite() then
            logger:debug("SwimService is biting")
            startFish()
        else
            logger:debug("SwimService is nibbling")
            local lure = FishingStateManager.getLure()
            if lure then
                Animations.lureNibble(lure)
            end
        end
    end
end


function FishingService.release()
    logger:debug("Releasing Swing")
    local state = FishingStateManager.getCurrentState()
    if state == "IDLE" then
        local fishingRod = FishingRod.getEquipped()
        if not (fishingRod and fishingRod:hasBait()) then
            tes3.messageBox("You are out of bait.")
            return
        end
        timer.start{
            duration = 0.020,
            callback = function()
                logger:debug("IDLE - start casting")
                startCasting()
                logger:debug("Activate blocked by state - %s", state)
            end
        }
    end
end

local function catchFish()
    logger:debug("Catching fish")
    FishingStateManager.setState("CATCHING")
    local fish = FishingStateManager.getCurrentFish()
    if not fish then
        logger:warn("No fish found")
        return
    end
    local fishObj = fish:getInstanceObject()

    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("No lure found")
        return
    end

    Animations.playSplashSound()
    Animations.splash(lure.position, fish:getSplashSize())
    timer.start{
        duration = 0.75,
        callback = function()

            TrophyMenu.createMenu(fish.fishType, function()
                tes3.addItem{
                    reference = tes3.player,
                    item = fishObj,
                    count = 1,
                }
                FishingStateManager.endFishing()
                FishingSkill.catchFish(fish.fishType)
            end)
        end
    }
end

local function startFight()
    logger:debug("Starting fight")
    local fish = FishingStateManager.getCurrentFish()
    if not fish then
        logger:warn("No fish to fight")
        return
    end
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:warn("No lure found")
        return
    end
    Animations.splash(lure.position, fish:getSplashSize())
    FightManager.new{
        fish = fish,
        callback = function(_fightManager, success, failMessage)
            if success then
                catchFish()
            else
                tes3.messageBox(failMessage or "It got away...")
                FishingStateManager.endFishing()
            end
        end
    }:start()
end

function FishingService.startSwing()
    local state = FishingStateManager.getCurrentState()

    local rod = FishingRod:getEquipped()
    if (state == "WAITING") then
        Animations.reverseSwing()
    end

    if (state == "WAITING") or (state == "CHASING") then
        logger:debug("%s cancel fishing", state)
        tes3.messageBox("You fail to catch anything.")
        local lure = FishingStateManager.getLure()
        if not lure then
            logger:warn("No lure found")
            return
        end
        Animations.splash(lure.position, 1.5)
        if rod then rod:useBait() end
        FishingStateManager.endFishing()
    elseif state == "BITING" then
        logger:debug("BITING - catch a fish")
        if rod then rod:useBait() end
        startFight()
    else
        logger:debug("Activate blocked by state - %s", state)
    end
end

--[[
    Bite interval determined by:
    - LUCK attribute
    - Fishing skill
]]
function FishingService.generateBiteInterval()
    if config.mcm.cheatMode then
        logger:trace("Cheat mode enabled, bite interval set to 1 second")
        return 1
    end
    local defaultInterval = 5
    local skill = FishingSkill.getCurrent()
    local skillEffect = math.remap(skill,
        0, 100,
        1.0, 0.70)
    local luck = math.clamp(0, 100, tes3.mobilePlayer.luck.current)
    local luckEffect = math.remap(luck,
        0, 100,
        1.0, 0.5)
    local random = math.random(5)
    local interval = defaultInterval * skillEffect * luckEffect + random
    logger:trace("Bite interval: %s", interval)
    return interval
end

function FishingService.getBiteDuration()
    if config.mcm.cheatMode then
        return 2.0
    end


    --TODO: base on fishing skill
    local skill = FishingSkill.getCurrent()

    local min = math.remap(skill,
        0, 100,
        0.1, 0.3
    )

    local max = math.remap(skill,
        0, 100,
        0.3, 0.6
    )
    local biteDuration = math.random(
        math.floor(min*100),
        math.floor(max*100)
    )/100

    logger:debug("Bite duration: %s", biteDuration)
    return biteDuration
end

---Calculate the chance a bite is real or just a nibble
function FishingService.calculateRealBite()
    if config.mcm.cheatMode then
        return true
    end

    --Roll based on bait hook chance
    local roll = math.random()
    local fishingRod = FishingRod.getEquipped()
    local bait = fishingRod and fishingRod:getEquippedBait()
    if bait then
        local baitMultiplier = 1 / bait:getType():getHookChance()
        logger:debug("Bait hook multiplier: %s", baitMultiplier)
        roll = roll * baitMultiplier
    end

    --Skill determines chance needed
    local skill = FishingSkill.getCurrent()
    local chanceNeeded = math.remap(skill,
        0, 100,
        config.constants.MIN_BITE_CHANCE, config.constants.MAX_BITE_CHANCE
    )

    logger:debug("Real bite chance: %s, needed: %s", roll, chanceNeeded)
    return roll < chanceNeeded
end

return FishingService
