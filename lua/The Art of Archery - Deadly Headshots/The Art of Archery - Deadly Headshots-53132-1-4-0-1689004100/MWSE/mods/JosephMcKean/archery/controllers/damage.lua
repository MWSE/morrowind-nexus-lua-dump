local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("damage")
local config = require("JosephMcKean.archery.config")

-- Store the damage value in reference tempData
---@param e damageEventData
local function damage(e)
	-- Check if the damage was caused by attack
	if not e.source == tes3.damageSource.attack then return end

	-- Check if the damage was caused by a projectile, but not by a spell, so it must be an arrow or a bolt
	if not e.projectile or e.magicSourceInstance then return end

	log:trace("before damage apply, health: %s", e.reference.mobile.health.current)
	log:trace("damage: %s", e.damage)

	-- if you're moving, you'll do 20% less damage.
	if config.enableDamageReduction then
		local attackerReference = e.attackerReference
		if attackerReference.tempData.isMoving then
			e.damage = (1 - 0.2) * e.damage
			log:trace("after moving damage reduction: %s", e.damage)
		end
	end

	-- Log the damage instead of double the damage since damage is before projectileHitActor
	e.reference.tempData.archeryDamage = e.damage
end

return damage
