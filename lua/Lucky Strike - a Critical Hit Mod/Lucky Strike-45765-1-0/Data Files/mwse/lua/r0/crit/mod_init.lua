local config

local function onAttack(e)

	if e.mobile.actionData.physicalDamage == 0 then return end
	
	local target		= e.targetReference
	
	if not target then return end

	local source		= e.reference
	local luck			= e.mobile.attributes[7+1].current
	local critChance	= ((luck / 100) ^ 3 / 2)
	local roll			= math.random()
	
	local critMult		= config.damageMultiplier
	local speedMult		= e.mobile.readiedWeapon.object.speed
	
	if critChance > roll then
		e.mobile.actionData.physicalDamage = e.mobile.actionData.physicalDamage * critMult * speedMult
		tes3.playSound({ reference = target, sound = "critical damage" })
		if ((e.reference == tes3.getPlayerRef()) and config.showMessageBox) then
			tes3.messageBox{ message = tes3.getGMST("sTargetCriticalStrike").value }
		end
	end

end

local function initialized(e)
    if tes3.isModActive("Lucky Strike.ESP") then
        event.register("attack", onAttack)
		config = json.loadfile("r0_crit_config")
		print("[r0-crit] Mod initialized with configuration:")
		print(json.encode(config, { indent = true }))
	end
end
event.register("initialized", initialized)