--init mcm
require("mer.realisticArchery.mcm")

local noiseService = require("mer.realisticArchery.noiseService")
local damageService = require("mer.realisticArchery.damageService")
local util = require("mer.realisticArchery.util")
local config = util.config
local logger = util.createLogger("main")

--Add noise to the direction of fired projectiles based on the attacker's marksman skill and other stats.
---@param e mobileActivatedEventData
local function onMobileActivated(e)
    if not config.mcm.enabled then return end
    --Apply noise to projectile velocity
    local isProjectile = e.mobile.objectType == tes3.objectType.mobileProjectile
    if isProjectile then
        ---@type tes3mobileProjectile
        local projectile = e.mobile
        if projectile.firingMobile ~= nil then
            logger:debug("Applying noise to projectile fired by: %s", projectile.firingMobile.object.name)
            local noise = noiseService.getNoise(projectile.firingMobile)
            noiseService.applyNoiseToProjectile(projectile, noise)
        end
    end
end

--Set hit chance to 100% for any fired projectiles
---@param e calcHitChanceEventData
local function onCalcHitChance(e)
    if not config.mcm.enabled then return end
    --Set hit chance to 100% for fired projectiles
    ---@type tes3mobileProjectile
    local projectile = e.projectile
    if projectile then
        logger:debug("Setting projectile hit chance to 100%%")
        e.hitChance = 100
    end
end

--At short distances, reduce the amount of damage done by projectiles.
--This is to balance low marksman skill hitting things at close range.
---@param e damageEventData
local function onDamage(e)
    if not config.mcm.enabled then return end
    --Reduce damage dealt at short range
    if e.projectile and e.attacker then
        if damageService.getDoReduceDamage(e.projectile, e.attacker) then
            logger:debug("Distance below min, reducing damage")
            local damage = e.damage
            logger:debug("Previous damage: %s", damage)
            local distanceMulti = damageService.getDistanceMulti(e.projectile, e.attacker)
            e.damage = damage * distanceMulti
            logger:debug("New damage: %s", e.damage)
        end
    end
end

local function onInit()
    event.register(tes3.event.mobileActivated, onMobileActivated)
    event.register(tes3.event.calcHitChance, onCalcHitChance, { priority = -50})
    event.register(tes3.event.damage, onDamage)
    logger:info("Initialised: %s", util.getVersion())
end
event.register(tes3.event.initialized, onInit)




