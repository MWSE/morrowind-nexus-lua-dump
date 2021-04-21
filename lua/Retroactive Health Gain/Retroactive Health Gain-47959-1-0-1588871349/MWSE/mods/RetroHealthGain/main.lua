--[[
	Retroactive Health Gain
	v1.0
	by hardek
]]--

local startHP

local function healthCalc()
	local gainHP = (tes3.player.object.level - 1) * tes3.mobilePlayer.endurance.base * tes3.findGMST(tes3.gmst.fLevelUpHealthEndMult).value
	local maxHP = startHP + gainHP
	--mwse.log(string.format("[Retroactive Health Gain] Calc: endurance based HP: %s. new maximum HP: %s", gainHP, maxHP))

	--MCP fortify max health
	if (tes3.hasCodePatchFeature(44) == true) then
		local fortHP = 0
		local activeEffect = tes3.mobilePlayer.activeMagicEffects
		--sum all magnitudes; method taken from NullCascade's UI Expansion
		for _ = 1, tes3.mobilePlayer.activeMagicEffectCount do
			activeEffect = activeEffect.next
			if (activeEffect.effectId == tes3.effect.fortifyHealth) then
				fortHP = fortHP + activeEffect.magnitude
			end
		end
		maxHP = maxHP + fortHP
		--mwse.log(string.format("[Retroactive Health Gain] Calc: MCP Fortify Max Health feature detected, fortify health magnitude: %s. new maximum HP with fortification: %s", fortHP, maxHP))
	end

	local currentHP = tes3.mobilePlayer.health.normalized * maxHP
	--mwse.log(string.format("[Retroactive Health Gain] Calc: new current HP: %s", currentHP))

	tes3.setStatistic({
		reference = tes3.player,
		name = 'health',
		base = maxHP
	})
	tes3.setStatistic({
		reference = tes3.player,
		name = 'health',
		current = currentHP
	})
end

local function healthCheck()
	startHP = tes3.player.data.startHP or nil
	--mwse.log(string.format("[Retroactive Health Gain] Check: starting health: %s. will be nil on first run", startHP))
	if (startHP == nil) then
		--tes3.player.object.health doesn't always return correct value
		--.attributes does, so calc instead
		startHP = (tes3.player.object.attributes[1] + tes3.player.object.attributes[6]) / 2
		--store value in save
		tes3.player.data.startHP = startHP
		--mwse.log(string.format("[Retroactive Health Gain] Check: calced starting health: %s. stored: %s", startHP, tes3.player.data.startHP))
	end

	--delay until levelup menu closed, allowing buffs to expire if they ended while resting
	timer.start({
		duration = 0.1,
		callback = healthCalc
	})
end

local function loaded(e)
	--event also triggers on new game, so don't run then
	--check for data presence, for adding to game in progress
	--prevent immediate recalc if only level 1
	if (not e.newGame and tes3.player.data.startHP == nil and tes3.player.object.level > 1) then
		healthCheck()
	end
end

local function onInitialized()
	event.register("loaded", loaded)
	event.register("levelUp", healthCheck)
	mwse.log("[Retroactive Health Gain] Mod initialized.")
end
event.register("initialized", onInitialized)
