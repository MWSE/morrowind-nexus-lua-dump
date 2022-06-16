local util = require("mer.realisticArchery.util")
local config = util.config
local logger = util.createLogger("NoiseService")

local NoiseService = {}

--Get the fatigue multiplier applied to the noise added to a mobile's fired projectile.
---@param mobile tes3mobileNPC|tes3mobileCreature
---@return number fatigueTerm The effect fatigue has on the noise level of the projectile.
local function getFatigueTerm(mobile)
    local fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value
    logger:trace("fFatigueMult: %s", fFatigueMult)
    local fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value
    logger:trace("fatigueBase: %s", fFatigueBase)
    local normalisedFatigue = mobile.fatigue.normalized
    logger:trace("normalisedFatigue %s", normalisedFatigue)
    local fatigueTerm = fFatigueBase - fFatigueMult * (1 - normalisedFatigue)
    logger:debug("fatigueTerm: %s", fatigueTerm)
    return fatigueTerm
end


--Get the effect of the mobile's stats (marksman skill, agility and luck) on the noise added to the projectile direction.
---@param mobile tes3mobileNPC|tes3mobileCreature
---@return number attackTerm The effect of the mobile's stats on the noise of the projectile, based on the vanilla hit chance algorithm.
local function getAttackTerm(mobile)
    local fatigueTerm = getFatigueTerm(mobile)
    local skill = util.getNPCOrCreatureMarksmanSkill(mobile)
    local agility = mobile.agility.current
    local luck = mobile.luck.current
    local attackTerm = (skill + (0.2 * agility) +( 0.1 * luck)) * fatigueTerm
    attackTerm = attackTerm + mobile.attackBonus - mobile.blind
    logger:trace("Raw attackTerm: %s", attackTerm)
    --Convert to normalised value where higher values means more noise
    attackTerm = math.remap(attackTerm, 0, 100, 1, 0)
    logger:debug("getAttackTerm: %s", attackTerm)
    return attackTerm
end

---@param mobile tes3mobileNPC|tes3mobileCreature
---@return number sneakingTerm The noise muiltiplier applied based on whether the attacking mobile is sneaking.
local function getSneakingTerm(mobile)
    local sneakingTerm = 1
    if mobile.isSneaking then
        --25% reduction == 0.75x noise multiplier
        sneakingTerm = 1 - config.mcm.sneakReduction / 100
    end
    logger:debug("getSneakingTerm: %s", sneakingTerm)
    return sneakingTerm
end

--Get the max amount of noise that can be applied to the projectile direction based on the firing mobile's stats.
---@param firingMobile tes3mobileNPC|tes3mobileCreature
---@return number maxNoise The max angle of noise applied to the projectile's velocity direction.
NoiseService.getMaxNoiseForMobile = function(firingMobile)
    --how many degrees of variance based on marksman skill
    local maxNoise = config.mcm.maxNoise
        * getAttackTerm(firingMobile)
        * getSneakingTerm(firingMobile)
    maxNoise = math.max(maxNoise, 0)
    logger:debug("getMaxNoiseForMobile: %s", maxNoise)
    return maxNoise
end



--Generate a random amount of projectile noise based on the stats of the attacking mobile
---@return tes3matrix33 noise The noise vector applied to the projectile's velocity direction.
NoiseService.getNoise = function(firingMobile)
    logger:debug("Getting noise for mobile: %s", firingMobile.object.name)
    local maxNoise = NoiseService.getMaxNoiseForMobile(firingMobile)
    local xNoise = util.getNormalDistributionRandom(maxNoise)
    local yNoise = util.getNormalDistributionRandom(maxNoise)
    local zNoise = util.getNormalDistributionRandom(maxNoise)
    local noise = tes3matrix33.new()
    noise:fromEulerXYZ(
        math.sin(2 * math.pi * xNoise / 360 ),
        math.sin(2 * math.pi * yNoise / 360 ),
        math.sin(2 * math.pi * zNoise / 360 )
    )
    logger:debug("getNoise: %s", noise)
    return noise
end

--Modifies the velocity and rotation of a projectile by a given noise vector
---@param projectile tes3mobileProjectile
NoiseService.applyNoiseToProjectile = function(projectile, noise)
    logger:debug("applyNoiseToProjectile")
    logger:debug("Previous Velocity: %s", projectile.velocity)
    projectile.velocity = noise * projectile.velocity
    projectile.reference.sceneNode.rotation = noise * projectile.reference.sceneNode.rotation
    logger:debug("New Velocity: %s", projectile.velocity)
end

return NoiseService