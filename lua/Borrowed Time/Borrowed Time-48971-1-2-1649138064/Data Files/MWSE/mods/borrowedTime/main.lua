local function isDamagedByEffects(reference)
	if tes3.isAffectedBy{reference = reference, effect = tes3.effect.fireDamage} then -- and reference.mobile.resistFire < 100
		return true
	elseif tes3.isAffectedBy{reference = reference, effect = tes3.effect.shockDamage} then -- and reference.mobile.resistShock < 100 
		return true
	elseif tes3.isAffectedBy{reference = reference, effect = tes3.effect.frostDamage} then -- and reference.mobile.resistFrost < 100 
		return true
	elseif tes3.isAffectedBy{reference = reference, effect = tes3.effect.poison} then -- and reference.mobile.resistPoison < 100 
		return true
	elseif tes3.isAffectedBy{reference = reference, effect = tes3.effect.damageHealth} then -- and reference.mobile.resistMagicka < 100 
		return true
	elseif tes3.isAffectedBy{reference = reference, effect = tes3.effect.absorbHealth} then -- and reference.mobile.resistMagicka < 100 
		return true
	end
	return false
end

local function onDamage(e)
	if e.damage < 0 then
		if e.mobile.health.current - math.abs(e.damage) <= 1 and not isDamagedByEffects(e.reference) then
			e.mobile.health.current = 1.1
			e.damage = 0
		end
	end
end

local function initialized(e)
	event.register("damage", onDamage)
end

event.register("initialized", initialized)

