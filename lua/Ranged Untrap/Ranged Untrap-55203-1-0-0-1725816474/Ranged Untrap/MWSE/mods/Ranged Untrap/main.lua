local logger = require("logging.logger")

local config = require("Ranged Untrap.config").config
local log = logger.new({
	name = "Ranged Untrap",
	logLevel = config.logLevel,
})

dofile("Ranged Untrap.mcm")

--- @type tes3skill, tes3skill
local security, marksman

event.register(tes3.event.initialized, function()
	security = tes3.getSkill(tes3.skill.security)
	marksman = tes3.getSkill(tes3.skill.marksman)
end)

--- @param reference tes3reference
local function getTrap(reference)
	return reference.lockNode and reference.lockNode.trap
end

-- This info comes from Skill menu in the CS.
local DEFEAT_TRAP_INDEX = 1
local SUCCESSFUL_ATTACK_INDEX = 1

--- @param reference tes3reference
local function untrap(reference)
	tes3.setTrap({ reference = reference })
	tes3.playSound({ sound = "Disarm Trap" })
	tes3.messageBox(tes3.findGMST(tes3.gmst.sTrapSuccess).value)
	tes3.game:clearTarget()
	tes3.mobilePlayer:exerciseSkill(tes3.skill.security, 0.7 * security.actions[DEFEAT_TRAP_INDEX])
	tes3.mobilePlayer:exerciseSkill(tes3.skill.marksman, 0.3 * marksman.actions[SUCCESSFUL_ATTACK_INDEX])
end

local marksmanWeapons = {
	[tes3.weaponType.arrow] = true,
	[tes3.weaponType.bolt] = true,
	[tes3.weaponType.marksmanBow] = true,
	[tes3.weaponType.marksmanCrossbow] = true,
	[tes3.weaponType.marksmanThrown] = true,
}

--- @param object tes3object
local function isMarksmanWeapon(object)
	--- @cast object tes3weapon|tes3misc
	local weaponType = object.type
	if weaponType and marksmanWeapons[weaponType] then
		return true
	end
	return false
end

--- @param reference tes3reference
--- @param trap tes3spell
local function triggerTrapSpell(reference, trap)
	tes3.cast({
		reference = reference,
		target = tes3.player,
		spell = trap,
	})
	tes3.setTrap({ reference = reference })
	tes3.game:clearTarget()
end

local function playFailSound()
	if not config.soundOnFail then return end
	tes3.playSound({ sound = "Disarm Trap Fail" })
end

--- @param e projectileHitActorEventData
event.register(tes3.event.projectileHitObject, function(e)
	if not isMarksmanWeapon(e.firingWeapon) then return end
	local target = e.target
	local trap = getTrap(target)
	if not trap then return end

	local x = 0.2 * tes3.mobilePlayer.agility.current + 0.1 * tes3.mobilePlayer.luck.current
	x = x + config.fSecurityMult * tes3.mobilePlayer.security.current
	      + config.fMarksmanMult * tes3.mobilePlayer.marksman.current
	x = x + (-1) * config.fTrapCostMult * trap.magickaCost
	x = x * (e.velocity:length() / tes3.findGMST(tes3.gmst.fProjectileMaxSpeed).value)
	x = x * tes3.mobilePlayer:getFatigueTerm()

	-- "Critical" fail.
	if x <= 0 then
		if not config.castTrapOnCriticalFail then
			playFailSound()
			return
		end
		triggerTrapSpell(target, trap)
		return
	end

	local roll = math.random(100)
	-- "Regular" fail.
	if roll > x then
		if not config.castTrapOnFail then
			playFailSound()
			return
		end
		triggerTrapSpell(target, trap)
		return
	end

	untrap(target)
end)
