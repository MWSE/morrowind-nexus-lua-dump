local function ACTIVATE(e) if e.activator == tes3.player then	local t = e.target		if t.object.objectType == tes3.objectType.npc and t.mobile.fatigue.current < 0 then
	if tes3.mobilePlayer.agility.current > 50 + 50*t.mobile.health.normalized + t.mobile.fatigue.current then
		for _, s in pairs(t.object.equipment) do t.mobile:unequip{item = s.object} end		timer.delayOneFrame(function() t.object:reevaluateEquipment() end)
	else if t.mobile.readiedWeapon then t.mobile:unequip{item = t.mobile.readiedWeapon.object} end		if t.mobile.readiedAmmo then t.mobile:unequip{item = t.mobile.readiedAmmo.object} end end
end	end end		event.register("activate", ACTIVATE)