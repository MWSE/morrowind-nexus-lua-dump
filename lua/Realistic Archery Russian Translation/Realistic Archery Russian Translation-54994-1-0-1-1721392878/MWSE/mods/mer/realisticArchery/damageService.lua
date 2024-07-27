local util = require("mer.realisticArchery.util")
local config = util.config
local logger = util.createLogger("DamageService")
local DamageService = {}

---@param mobile tes3mobileNPC|tes3mobileCreature
---@return number minDamageMulti The damage multiplier when the target is at 0 distance from the attacker
function DamageService.getMinDamageMulti(mobile)
    local minDamageMulti = 1 - config.mcm.maxCloseRangeDamageReduction / 100
    logger:debug("getMinDamageMulti: %s", minDamageMulti)
    return minDamageMulti
end

--Higher marksman skill requires less distance before doing max damage
---@param mobile tes3mobileNPC|tes3mobileCreature
---@return number skillEffect Value between 0.5 and 1.0, a multiplier to be applied to the minimum distance for max damage.
function DamageService.getSkillDistanceEffect(mobile)
    local skill = util.getNPCOrCreatureMarksmanSkill(mobile)
    local skillEffect = math.remap(skill, 0, 100, 1, 0.5)
    logger:debug("getSkillDistanceEffect: %s", skillEffect)
    return skillEffect
end

---@param mobile tes3mobileNPC|tes3mobileCreature
function DamageService.getMinDistanceForMaxDamage(mobile)
    local skillDistanceEffect = DamageService.getSkillDistanceEffect(mobile)
    local minDistance = config.mcm.minDistanceFullDamage * skillDistanceEffect
    logger:debug("getMinDistanceForMaxDamage: %s", minDistance)
    return minDistance
end

---@param projectile tes3mobileProjectile
---@param attacker tes3mobileNPC
---@return number distance The distance between the projectile and the mobile that fired it.
function DamageService.getprojectileDistance(projectile, attacker)
    local distance = projectile.position:distance(attacker.position)
    logger:debug("getprojectileDistance: %s", distance)
    return distance
end

function DamageService.getDoReduceDamage(projectile, attacker)
    local distance = DamageService.getprojectileDistance(projectile, attacker)
    local minDistance = DamageService.getMinDistanceForMaxDamage(attacker)
    local doReduceDamage = distance < minDistance
    logger:debug("getDoReduceDamage: %s", doReduceDamage)
    return doReduceDamage
end

--Get the damage multiplier based on the projectiles' distance from the mobile that fired it.
---@param projectile tes3mobileProjectile
---@param attacker tes3mobileNPC
---@return number distanceMulti The multiplier to apply to damage based on the projectile's distance from the mobile that fired it.
function DamageService.getDistanceMulti(projectile, attacker)
    local distance = DamageService.getprojectileDistance(projectile, attacker)
    local minDamageMulti = DamageService.getMinDamageMulti(attacker)
    local minDistance = DamageService.getMinDistanceForMaxDamage(attacker)
    local distanceMulti = math.clamp(distance / minDistance, 0, 1)
    distanceMulti = math.max(minDamageMulti, distance / minDistance)
    logger:debug("getDistanceMulti: %s", distanceMulti)
    return distanceMulti
end

return DamageService