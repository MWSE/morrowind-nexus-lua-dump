local function onThrownDamage(e)
	-- Halves the damage recieved from thrown weapons, because in-game thrown weapons count as both projectile and firing weapon and their damage gets doubled
	if e.projectile and e.projectile.reference.baseObject.type == tes3.weaponType.marksmanThrown then
		-- tes3.messageBox("Halving damage of %f.", e.damage)
		e.damage = e.damage / 2
		-- tes3.messageBox("Halved damage: %f.", e.damage)
	end	
end

event.register("damage", onThrownDamage)