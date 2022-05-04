local function mehrunesCallback(e)
	if e.mobile.readiedWeapon ~= nil and e.mobile.readiedWeapon.object.id == "mehrunes'_razor_unique" and (e.targetMobile ~= nil) then 
		local deathChance = (e.mobile.luck.current * 0.05)
		local rng = math.random(1,100)
		if rng <= deathChance then
			e.targetMobile:kill()
			tes3.messageBox("Mehrunes Dagon claims the soul of " .. e.targetReference.object.name)
		end
	end
end

event.register(tes3.event.attack, mehrunesCallback)