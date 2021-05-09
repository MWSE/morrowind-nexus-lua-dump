local cf = mwse.loadConfig("Auramancer", {KEY = {keyCode = 44}, snd = true, agr = true, mc = 10, rad = 5, mag = 20})
local p, mp, MMana, B, BE, Flag		local T = timer		local ME = {[4] = 14, [5] = 15, [6] = 16}

local function CrimeAt(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end

local function AuraTik()
	local M = {[14] = math.ceil(tes3.getEffectMagnitude{reference = p, effect = 4}*cf.mag/100),
	[15] = math.ceil(tes3.getEffectMagnitude{reference = p, effect = 5}*cf.mag/100),
	[16] = math.ceil(tes3.getEffectMagnitude{reference = p, effect = 6}*cf.mag/100)}
	local mc = (M[14] + M[15] + M[16]) * cf.mc/100
	
	if mc > 0 then local m
		local rad = (mp.willpower.current + mp:getSkillValue(11)) * cf.rad
		if M[14] > 0 then BE[1].id = 14		BE[1].max = M[14]	else BE[1].id = -1 end
		if M[16] > 0 then BE[2].id = 16		BE[2].max = M[16]	else BE[2].id = -1 end
		if M[15] > 0 then BE[3].id = 15		BE[3].max = M[15]	else BE[3].id = -1 end
		for r in tes3.iterate(p.cell.actors) do m = r.mobile	if m and not m.isDead and p.position:distance(r.position) < rad and (cf.agr or m.actionData.target == mp) and tes3.getCurrentAIPackageId(m) ~= 3 then
			if mp.magicka.current > mc then mp.magicka.current = mp.magicka.current - mc	MMana.current = mp.magicka.current		tes3.applyMagicSource{reference = r, source = B}	CrimeAt(r.mobile) end
		end end
	else T:cancel() end
end


local function SPELLRESIST(e)	if e.target == p and ME[e.effect.id] then	
	if Flag and not T.timeLeft then T = timer.start{duration = math.max(3 - mp.alteration.base/100, 2), iterations = -1, callback = AuraTik} end
end end		event.register("spellResist", SPELLRESIST)


local function KEYDOWN(e) if not tes3ui.menuMode() then Flag = not Flag
	if Flag then	if T.timeLeft then T:cancel() else T = timer.start{duration = math.max(3 - mp.alteration.base/100, 2), iterations = -1, callback = AuraTik} end
	elseif T.timeLeft then T:cancel() end
	if cf.snd then tes3.playSound{sound = Flag and "mysticism cast" or "enchant fail"} end		tes3.messageBox("Damage from auras = %s", Flag)
end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		--ad = mp.actionData		--D = p.data
	MMana = tes3ui.findMenu(-526):findChild(-865).widget
	if Flag then T = timer.start{duration = math.max(3 - mp.alteration.base/100, 2), iterations = -1, callback = AuraTik} end
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Auramancer")	tpl:saveOnClose("Auramancer", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Key to switch damage aura mode (requires restarting the game)"}
p0:createSlider{label = "Damage multiplier for aura damage", min = 10, max = 50, step = 1, jump = 5, variable = var{id = "mag", table = cf}}
p0:createSlider{label = "Manacost multiplier for aura damage", min = 1, max = 30, step = 1, jump = 5, variable = var{id = "mc", table = cf}}
p0:createSlider{label = "Radius multiplier for aura damage", min = 1, max = 20, step = 1, jump = 5, variable = var{id = "rad", table = cf}}
p0:createYesNoButton{label = "Aggressive mode for your auras", variable = var{id = "agr", table = cf}}
p0:createYesNoButton{label = "Play damage aura toggle sound", variable = var{id = "snd", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	--wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
	B = tes3.getObject("4b_AUR") or tes3alchemy.create{id = "4b_AUR", name = "4b_AUR", icon = "s\\b_tx_s_sun_dmg.dds"} 	B.sourceless = true		BE = B.effects
	BE[1].duration = 3	BE[2].duration = 3	BE[3].duration = 3
end		event.register("initialized", initialized)