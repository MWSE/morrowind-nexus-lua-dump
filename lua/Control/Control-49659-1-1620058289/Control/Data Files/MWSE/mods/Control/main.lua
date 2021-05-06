local cf = mwse.loadConfig("Control", {mbret = 3, cpkey = {keyCode = 46}, enemy = 5, telmult = 10, livmult = 20, mc = 10})
local p, mp, ad, D, DM, MMana, wc, ic, MB		local CPR = {}		local G = {}

local function hitp(x) local pos = tes3.getPlayerEyePosition()	local vec = tes3.getPlayerEyeVector()	local hit = tes3.rayTest{position = pos, direction = vec}
return hit and hit.intersection:distance(pos) < 4800 and hit.intersection - vec * (x or 40) or pos + vec*4800 end


local function KEYDOWN(e) if not tes3ui.menuMode() then
	if MB[1] == 128 then for r, t in pairs(CPR) do if t.tim then CPR[r] = nil end end -- Роспуск снарядов
	elseif e.isControlDown then if DM.cpm then DM.cpm = false tes3.messageBox("Mines: simple mode") else DM.cpm = true tes3.messageBox("Mines: teleport mode") end
	elseif ic:isKeyDown(ic.inputMaps[1].code) then DM.cp = 3 tes3.messageBox("Teleport projectiles")
	elseif ic:isKeyDown(ic.inputMaps[2].code) then DM.cp = 1 tes3.messageBox("Homing projectiles")
	elseif ic:isKeyDown(ic.inputMaps[3].code) then if DM.cpt then DM.cpt = false tes3.messageBox("Simple mode") else DM.cpt = true tes3.messageBox("Smart mode") end
	elseif ic:isKeyDown(ic.inputMaps[4].code) then DM.cp = 4 tes3.messageBox("Magic mines")
	else DM.cp = 0 tes3.messageBox("Target projectiles") end
end end		event.register("keyDown", KEYDOWN, {filter = cf.cpkey.keyCode})

--Режимы: 0 = простой на цель, 1 = умный на цель, 2 = самонаведение, 4 = мины, 7 - магические шары врагов 		 11 - стрелы контроль
local function SimulateCP(e)	G.dt = wc.deltaTime		G.cpfr = G.cpfr + 1		G.pep = tes3.getPlayerEyePosition()	G.pev = tes3.getPlayerEyeVector()
	if MB[cf.mbret] == 128 then G.hit = G.pep + G.pev * 150 else G.hit = tes3.rayTest{position = G.pep, direction = G.pev, ignore = {p}}	if G.hit then G.hit = G.hit.intersection else G.hit = G.pep + G.pev * 4800 end end
	for r, t in pairs(CPR) do if t.tim then	t.tim = t.tim - G.dt
		if t.tim < 0 then CPR[r] = nil
		elseif t.mod == 1 then t.s.velocity = (G.hit - r.position):normalized()*1500
		elseif t.mod == 0 then t.s.velocity = G.pev*2000
		elseif t.mod == 2 then t.s.velocity = (t.tar.position + tes3vector3.new(0,0,100) - r.position):normalized()*1000
		elseif t.mod == 4 then t.s.velocity = tes3vector3.new(50,50,50)	r.position = t.pos end
	else
		if t.mod == 11 then
			if t.liv then t.liv = t.liv - G.dt		t.m.velocity = G.pev*2000	if G.cpfr == 30 then r.orientation = p.orientation	G.cpfr = 0 end			if t.liv < 0 then t.liv = nil	t.v = t.m.velocity end
			else t.m.velocity = t.v end
		elseif t.mod == 7 then if t.liv > 0 then t.v = G.pep - r.position	t.liv = t.v:length() < 120 and 0 or t.liv - G.dt	t.v = t.v:normalized()*2000 end		t.s.velocity = t.v end
	end end		if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	G.cpfr = nil end
end


local function MOBILEACTIVATED(e) local m = e.mobile	local r = e.reference		if m and m.firingMobile then	local si = m.spellInstance	-- только m.flags есть
if m.firingMobile == mp then
	if si then	local mc
		if mp.magicka.current > cf.mc then		local live = (mp.willpower.current + mp.intelligence.current)/200 * cf.livmult
			if DM.cp == 3 then mc = 0.8		timer.delayOneFrame(function() r.position = hitp() end)
			else -- Сперва проверяем мины, затем автонаведение, затем умный режим на цель, затем простой режим
				if DM.cp == 4 then
					if DM.cpm then mc = 1	CPR[r] = {mod = 4, tim = live*2, s = r.sceneNode, pos = hitp()}
					else mc = 0.6		CPR[r] = {mod = 4, tim = live*2, s = r.sceneNode, pos = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*100} end
				else	if si.source.name == "4b_SG" then return end	local tar
					if DM.cp == 1 then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {p}}
						tar = hit and hit.reference and hit.reference.mobile and not hit.reference.mobile.isDead and hit.reference
					if not tar then local mindist = 8000	for ref in tes3.iterate(p.cell.actors) do if ref.mobile and not ref.mobile.isDead and mindist > p.position:distance(ref.position)
					and tes3.getCurrentAIPackageId(ref.mobile) ~= 3 then mindist = p.position:distance(ref.position)	tar = ref end end end end
					if tar then mc = 1		CPR[r] = {mod = 2, tim = live, s = r.sceneNode, tar = tar}
					elseif DM.cpt then mc = 0.6		CPR[r] = {mod = 1, tim = live, s = r.sceneNode}
					else mc = 0.4	CPR[r] = {mod = 0, tim = live, s = r.sceneNode} end
				end
				if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
			end
			mp.magicka.current = mp.magicka.current - mc * cf.mc		MMana.current = mp.magicka.current
		end
	else	local cont = tes3.getEffectMagnitude{reference = p, effect = 59}
		if cont > 0 then CPR[r] = {mod = 11, m = m, liv = cont/cf.telmult}		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end end
	end
elseif si and cf.enemy > 0 and m.firingMobile.actionData.target == mp then 
	CPR[r] = {mod = 7, s = r.sceneNode, liv = m.firingMobile.object.level * cf.enemy / 100}		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
end
end end		event.register("mobileActivated", MOBILEACTIVATED)


local function OBJECTINVALIDATED(e) local ob = e.object
	if CPR[ob] then CPR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		ad = mp.actionData		D = p.data		if not D.Mmod then D.Mmod = {} end	DM = D.Mmod
	MMana = tes3ui.findMenu(-526):findChild(-865).widget
end		event.register("loaded", loaded)


local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Control")	tpl:saveOnClose("Control", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Mouse button to return controlled projectiles in Smart mode: 1 - left, 2 - right, 3 - middle", min = 1, max = 5, step = 1, jump = 1, variable = var{id = "mbret", table = cf}}
p0:createKeyBinder{variable = var{id = "cpkey", table = cf}, label = "Projectile control mode key (Requires game restart). Press with: Move buttons = switch modes; Left = turn Smart mode; CTRL = turn Mine mode; LMB = release projectiles"}
p0:createSlider{label = "Time multiplier for control magic projectiles", min = 5, max = 100, step = 1, jump = 5, variable = var{id = "livmult", table = cf}}
p0:createSlider{label = "Mana cost multiplier for control magic projectiles", min = 3, max = 30, step = 1, jump = 5, variable = var{id = "mc", table = cf}}
p0:createSlider{label = "Enemies' ability for homing magic projectiles (0 = no homing)", min = 0, max = 50, step = 1, jump = 5, variable = var{id = "enemy", table = cf}}
p0:createSlider{label = "Telekinesis magnitude required for 1 second of arrow control", min = 1, max = 50, step = 1, jump = 5, variable = var{id = "telmult", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
	tes3.findGMST("fTargetSpellMaxSpeed").value = 2000
end		event.register("initialized", initialized)