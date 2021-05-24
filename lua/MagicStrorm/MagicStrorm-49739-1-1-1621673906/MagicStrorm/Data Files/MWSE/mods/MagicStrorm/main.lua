local cf = mwse.loadConfig("MagicStrorm", {msg = true, KEY = {keyCode = 44}, fps = 20})
local p, mp, wc, ic, MB, D, MMana, mc, SimFl, Sim		local CPR = {}		local B = {}	local CastK

local function Shot(n, x) tes3.applyMagicSource{reference = p, source = B.SG} 	if n > 1 then timer.delayOneFrame(function()
Shot(n-1, x)	timer.delayOneFrame(function() ic.mouseState.x = ic.mouseState.x + math.random(-2*x,2*x)	ic.mouseState.y = ic.mouseState.y + math.random(-x,x) end) end) end end

local function RaySim()	local dt = 1/cf.fps
	if CastK() and mp.magicka.current > mc then	SimFl = SimFl + wc.deltaTime
		if SimFl > dt then SimFl = SimFl - dt
			tes3.applyMagicSource{reference = p, source = B.RAY}
			mp.magicka.current = mp.magicka.current - mc		MMana.current = mp.magicka.current
		end
	else event.unregister("simulate", RaySim)	SimFl = nil end
end


local function SPELLCASTED(e) if e.caster == p then local s = e.source		if s.castType == 0 and CastK() then		local eff = s.effects	if eff[1].rangeType > 0 then
	local min, max		mc = 0		local rad = mp:getSkillValue(11)/20
	if D.RayT > 0 then	local E = B.RAY.effects
		for i, ef in ipairs(eff) do if ef.rangeType > 0 then E[i].id = ef.id		min = math.floor(ef.min/10)		max = math.ceil(ef.max/10)
			E[i].min = min	E[i].max = max	E[i].radius = D.RayT == 1 and 0 or rad		E[i].attribute = ef.attribute		E[i].skill = ef.skill
			mc = mc + (min + max) * ef.object.baseMagickaCost/20 * (D.RayT == 1 and 0.5 or 1)
		else E[i].id = -1 end end
		if not SimFl then event.register("simulate", RaySim)	SimFl = 1/cf.fps + 0.01 end
		if cf.msg then tes3.messageBox("Spell = %s   cost = %.2f", s.name, mc) end
	else	local E = B.SG.effects
		for i, ef in ipairs(eff) do if ef.rangeType > 0 then E[i].id = ef.id		min = math.floor(ef.min/2)		max = math.ceil(ef.max/2)
			E[i].min = min	E[i].max = max	E[i].radius = math.min(ef.radius, rad*2)		E[i].attribute = ef.attribute		E[i].skill = ef.skill
			mc = mc + (min + max) * ef.object.baseMagickaCost/20 * 3
		else E[i].id = -1 end end
		if mp.magicka.current > mc then tes3.modStatistic{reference = p, name = "magicka", current = -mc}
			if eff[1].rangeType == 2 then timer.delayOneFrame(function() Shot(math.floor(3 + mp:getSkillValue(11)/50), 50 * (1 - math.min(mp.agility.current + mp:getSkillValue(23),200)/250)) end)
			else Shot(math.floor(3 + mp:getSkillValue(11)/50), 50 * (1 - math.min(mp.agility.current + mp:getSkillValue(23),200)/250)) end
			if cf.msg then tes3.messageBox("Spell = %s   cost = %.2f", s.name, mc) end
		end
	end
end end end end		event.register("spellCasted", SPELLCASTED)


local function SimulateCP(e)	local dt = wc.deltaTime
	for r, t in pairs(CPR) do 
		if t.mod == 12 then t.liv = t.liv - dt		if t.liv < 0 then t.si.state = 6	CPR[r] = nil end end
	end
	if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	Sim = nil end
end


local function MOBILEACTIVATED(e) local m = e.mobile	if m and m.firingMobile == mp then	local si = m.spellInstance
	if si and si.source.name == "4b_RAY" and D.RayT == 1 then
		CPR[e.mobile.reference] = {mod = 12, si = si, liv = (50 + mp.willpower.current/2 + mp:getSkillValue(11))/600}		if not Sim then event.register("simulate", SimulateCP)	Sim = 0 end
	end
end end		event.register("mobileActivated", MOBILEACTIVATED)


local function OBJECTINVALIDATED(e) local ob = e.object
	if CPR[ob] then CPR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)


local function KEYDOWN(e) if not tes3ui.menuMode() then 
	D.RayT = D.RayT == 2 and 0 or D.RayT + 1
	tes3.messageBox("%s", (D.RayT == 0 and "Shotgun") or (D.RayT == 1 and "Spray") or "Ray")
end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer			D = p.data		D.RayT = D.RayT or 0
	MMana = tes3ui.findMenu(-526):findChild(-865).widget
	local CKEY = ic.inputMaps[tes3.keybind.readyMagic + 1].code		CastK = CKEY < 8 and (function() return ic:isMouseButtonDown(CKEY) end) or (function() return ic:isKeyDown(CKEY) end)
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("MagicStrorm")	tpl:saveOnClose("MagicStrorm", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Key to switch the casting mode"}
p0:createSlider{label = "Maximum shots per second (cannot exceed your fps)", min = 10, max = 300, step = 5, jump = 10, variable = var{id = "fps", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
	tes3.findGMST("fTargetSpellMaxSpeed").value = 2000
	B.RAY = tes3.getObject("4b_RAY") or tes3alchemy.create{id = "4b_RAY", name = "4b_RAY", icon = "s\\b_tx_s_sun_dmg.dds"} 	B.RAY.sourceless = true		for i, ef in ipairs(B.RAY.effects) do ef.rangeType = 2	ef.duration = 1 end
	B.SG = tes3.getObject("4b_SG") or tes3alchemy.create{id = "4b_SG", name = "4b_SG", icon = "s\\b_tx_s_sun_dmg.dds"} 	B.SG.sourceless = true			for i, ef in ipairs(B.SG.effects) do ef.rangeType = 2	ef.duration = 1 end
end		event.register("initialized", initialized, {priority = -1000})