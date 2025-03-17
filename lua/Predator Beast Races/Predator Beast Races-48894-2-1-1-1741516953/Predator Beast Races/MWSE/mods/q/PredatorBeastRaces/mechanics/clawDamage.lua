-----------------------------------
-- Claw Damage for Beast Races
-----------------------------------

local common = include("q.PredatorBeastRaces.common")


local function dealDamage(damage, target, playerIsAttacker)
	if damage == 0 then return end
	target:applyDamage({
		damage = damage,
		applyArmor = true,
		resistAttribute = tes3.effectAttribute.shield,
		applyDifficulty = common.settings.clawApplyDifficulty,
		playerAttack = playerIsAttacker,
	})
end


local function clawDamage(attackerMobile)
	return common.clawRaceMod[attackerMobile.object.race.id:lower()] * attackerMobile.actionData.attackSwing * ( common.settings.clawBaseDamage + 0.01 * ( common.settings.clawH2hMod * attackerMobile.handToHand.current + common.settings.clawStrengthMod * attackerMobile.strength.current ))
end


local function onDamage(e)
	if e.source ~= "attack" then return end

	--if not e.projectile and not e.attacker.readiedWeapon then ... end by Axemagister
	if e.attacker ~= nil and -- Change unarmed damage for beast races
	   not e.attacker.readiedWeapon and
	   not e.projectile then -- Unarmed attack

		local attacker = e.attacker

		if attacker.objectType ~= tes3.objectType.mobileNPC and
		   attacker.objectType ~= tes3.objectType.mobilePlayer then
			return
		end

		if common.isBeast(e.attackerReference) then
			e.damage = clawDamage(attacker)
		end
	end
end

local function onDamageHandToHand(e)
	if e.attacker.objectType ~= tes3.objectType.mobileNPC and
	   e.attacker.objectType ~= tes3.objectType.mobilePlayer then
		return
	end

	local attacker = e.attacker
	local target = e.mobile

	if common.isBeast(e.attackerReference) then
		dealDamage( clawDamage(attacker), target, ( attacker.objectType == tes3.objectType.mobilePlayer ) )
	end
end

-----------------------------------

event.register("initialized", function ()
	event.register("damageHandToHand", onDamageHandToHand)
	event.register("damage", onDamage)
end)
