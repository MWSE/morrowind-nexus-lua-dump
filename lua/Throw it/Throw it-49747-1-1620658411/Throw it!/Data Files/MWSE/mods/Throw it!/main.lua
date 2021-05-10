
local cf = mwse.loadConfig("Throw it!", {mbmet = 2, pow = 100, msg = false, KEY = {keyCode = 44}})
local p, mp, ad, wc, ic, MB, Sim		local CPR = {}		local W = {}	local V = {}	local L = {}

local function GetArmor(m) if m.actorType == 0 then 	return m.shield else local st = tes3.getEquippedItem{actor = m.reference, objectType = tes3.objectType.armor, slot = math.random(4) == 1 and 1 or math.random(0,8)}
return m.shield + (st and st.object:calculateArmorRating(m) or m:getSkillValue(17)*0.3) end end

L.METW = function(e) if not e:trigger() then return end		local sn = e.sourceInstance.serialNumber	local dmg, wd	local r = e.effectInstance.target		local m = r.mobile		local arm = GetArmor(m)
	if V.MET[sn] then dmg = V.MET[sn].dmg	wd = V.MET[sn].r.attachments.variables		V.MET[sn] = nil end
	if dmg then
		local fdmg = dmg*dmg/(dmg + arm)		m:applyHealthDamage(fdmg)
		if wd then wd.condition = math.max(wd.condition - dmg * tes3.findGMST("fWeaponDamageMult").value, 0) end
		if cf.msg then tes3.messageBox("Throw! %s  dmg = %d (start = %d   armor = %d)", r.object.name, fdmg, dmg, arm) end
	end		e.effectInstance.state = tes3.spellState.retired
end

local function SimMET(e)
for r, t in pairs(V.METR) do if t.f then
	r.position = r.position:interpolate(p.position, wc.deltaTime * 1000 * t.retacs)
	if p.position:distance(r.position) < 150 then p:activate(r)		if not mp.readiedWeapon	then timer.delayOneFrame(function() mp:equip{item = r.object} end) end	V.METR[r] = nil end
end end
if table.size(V.METR) == 0 then event.unregister("simulate", SimMET)	W.metflag = nil end
end


local function SimulateCP(e)	local dt = wc.deltaTime
	for r, t in pairs(CPR) do 
		if t.mod == 6 then t.v = t.v + tes3vector3.new(0,0,-dt*0.75/t.pow)		t.s.velocity = (t.con and (t.v + tes3.getPlayerEyeVector() * t.con):normalized() or t.v) * 1000*t.pow		t.r.position = r.position:copy() end
	end
	if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	Sim = nil end
end


local function ATTACK(e) if e.mobile == mp then		local w = mp.readiedWeapon	local ob = w and w.object
if w and ob.weight > 0 and ob.isMelee and MB[cf.mbmet] == 128 then	local wd = w.variables
	local ow = ob.weight	local kw = ow/(1 + ow/20) / 20
	local sdmg = math.max(math.max(ob.chopMax, ob.thrustMax) * math.max(wd.condition/ob.maxCondition, 0.3), ow/2) * 0.75
	local Kstr = mp.strength.current 		local Kstam = 50 * math.max(1-mp.fatigue.normalized,0)		local Kskill = mp:getSkillValue(23) * 0.3		local Kbonus = mp.attackBonus/5		
	W.acs = math.clamp((ad.attackSwing * (100 + Kstr - Kstam)/100 - kw) * cf.pow/100, 0.5, 4)
	W.metd = sdmg * (ad.attackSwing * (100 + Kstr - Kstam + Kskill + Kbonus)/100)
	W.met = tes3.dropItem{reference = p, item = ob, itemData = wd}		--if W.DWM then L.DWMOD(false) end
	if cf.msg then tes3.messageBox("Throw %s!  Acs = %.2f (%.2f w)  Dmg = %.1f (%.1f +%d%% str -%d%% stam +%d%% skill +%d%% atb)", ob.name, W.acs, kw, W.metd, sdmg, Kstr, Kstam, Kskill, Kbonus) end
	tes3.applyMagicSource{reference = p, name = "4nm_met", effects = {{id = 610, range = 2}}}	return
end end end		event.register("attack", ATTACK)


local function MOBILEACTIVATED(e) local m = e.mobile	if m and m.firingMobile == mp then	local si = m.spellInstance
	if si and si.source.name == "4nm_met" then local r = e.mobile.reference		r.sceneNode.appCulled = true
		timer.delayOneFrame(function() r.position = tes3.getPlayerEyePosition() + tes3vector3.new(0,0,20) end)
		CPR[r] = {mod = 6, s = r.sceneNode, v = tes3.getPlayerEyeVector(), r = W.met, pow = W.acs, dmg = W.metd}	W.met.orientation = p.orientation
		V.MET[si.serialNumber] = {r = W.met, dmg = W.metd}
		if mp.telekinesis > 0 then 	CPR[r].con = math.max(mp.telekinesis/20/(W.met.object.weight + 5), 0.05)
			V.METR[W.met] = {retacs = math.clamp(mp.telekinesis/20/(W.met.object.weight + 5), 0.3, 3), sn = si.serialNumber}
			if not W.metflag then event.register("simulate", SimMET)	W.metflag = true end
		end
		if not Sim then event.register("simulate", SimulateCP)	Sim = 0 end	return
	end
end end		event.register("mobileActivated", MOBILEACTIVATED)


local function PROJECTILEEXPIRE(e) if e.firingReference == p then local m = e.mobile	local si = m.spellInstance		if si then local sn = si.serialNumber	
	if V.MET[sn] then local wr = V.MET[sn].r
		if V.METR[wr] then
			if not V.METR[wr].f and V.METR[wr].retacs then V.METR[wr].f = 1 end
			if not V.METR[wr].f then V.METR[wr] = nil	local hit = tes3.rayTest{position = wr.position - m.reference.sceneNode.velocity:normalized()*100, direction = tes3vector3.new(0,0,-1)}
				if hit then wr.position = hit.intersection + tes3vector3.new(0,0,5) end
			end
		else
			local hit = tes3.rayTest{position = wr.position - m.reference.sceneNode.velocity:normalized()*100, direction = tes3vector3.new(0,0,-1)}
			if hit then wr.position = hit.intersection + tes3vector3.new(0,0,5) end
		end
	end
end end end		event.register("projectileExpire", PROJECTILEEXPIRE)


-- ЦеллЧЕйнджед НЕ триггерит инвалидейтед обычных референций, но триггерит Прожектайл Экспире.
local function CELLCHANGED(e)
	if W.metflag and e.previousCell and (e.cell.isInterior or e.previousCell.isInterior) then for r, t in pairs(V.METR) do p:activate(r) end	V.METR = {}		CPR = {} end
end		event.register("cellChanged", CELLCHANGED)


local function OBJECTINVALIDATED(e) local ob = e.object
	if CPR[ob] then CPR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)


local function KEYDOWN(e) if not tes3ui.menuMode() then
	for r, t in pairs(V.METR) do if not t.f then	t.f = 1		local si = tes3.getMagicSourceInstanceBySerial{serialNumber = t.sn}		if si then si.state = 6 end end end
end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer	ad = mp.actionData			W = {}		V.MET = {}	V.METR = {}
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Throw it!")	tpl:saveOnClose("Throw it!", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Mouse button for throwing weapons (hold while attacking): 2 - right, 3 - middle", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbmet", table = cf}}
p0:createSlider{label = "Throwing power multiplier", min = 50, max = 500, step = 5, jump = 10, variable = var{id = "pow", table = cf}}
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Key for telekinetic return of thrown weapons (requires restarting the game)"}
p0:createYesNoButton{label = "Show messages", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons

local S = {[0] = {l = {0.5,0,1}, p = "vfx_alt_glow.tga", sc = "alteration cast", sb = "alteration bolt", sh = "alteration hit", sa = "alteration area", vc = "VFX_AlterationCast", vb = "VFX_AlterationBolt", vh = "VFX_AlterationHit", va = "VFX_AlterationArea"},
[1] = {l = {1,1,0}, p = "vfx_conj_flare02.tga", sc = "conjuration cast", sb = "conjuration bolt", sh = "conjuration hit", sa = "conjuration area", vc = "VFX_ConjureCast", vb = "VFX_DefaultBolt", vh = "VFX_DefaultHit", va = "VFX_DefaultArea"},
[2] = {l = {1,0,0}, p = "vfx_alpha_bolt01.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_DestructCast", vb = "VFX_DestructBolt", vh = "VFX_DefaultHit", va = "VFX_DestructArea"},
[3] = {l = {0,1,0.5}, p = "vfx_greenglow.tga", sc = "illusion cast", sb = "illusion bolt", sh = "illusion hit", sa = "illusion area", vc = "VFX_IllusionCast", vb = "VFX_IllusionBolt", vh = "VFX_IllusionHit", va = "VFX_IllusionArea"},
[4] = {l = {1,0.5,1}, p = "vfx_myst_flare01.tga", sc = "mysticism cast", sb = "mysticism bolt", sh = "mysticism hit", sa = "mysticism area", vc = "VFX_MysticismCast", vb = "VFX_MysticismBolt", vh = "VFX_MysticismHit", va = "VFX_MysticismArea"},
[5] = {l = {0,0.5,1}, p = "vfx_bluecloud.tga", sc = "restoration cast", sb = "restoration bolt", sh = "restoration hit", sa = "restoration area", vc = "VFX_RestorationCast", vb = "VFX_RestoreBolt", vh = "VFX_RestorationHit", va = "VFX_RestorationArea"},
[6] = {l = {1,0.5,0}, p = "vfx_firealpha00A.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_FireCast", vb = "VFX_FireBolt", vh = "VFX_FireHit", va = "VFX_FireArea"},
[7] = {l = {0,1,1}, p = "vfx_icestar.tga", sc = "frost_cast", sb = "frost_bolt", sh = "frost_hit", sa = "frost area", vc = "VFX_FrostCast", vb = "VFX_FrostBolt", vh = "VFX_FrostHit", va = "VFX_FrostArea"},
[8] = {l = {1,0,1}, p = "vfx_map39.tga", sc = "shock cast", sb = "shock bolt", sh = "shock hit", sa = "shock area", vc = "VFX_LightningCast", vb = "VFX_ShockBolt", vh = "VFX_LightningHit", va = "VFX_LightningArea"},
[9] = {l = {0.5,1,0}, p = "vfx_poison.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_PoisonCast", vb = "VFX_PoisonBolt", vh = "VFX_PoisonHit", va = "VFX_PoisonArea"},
[10] = {l = {1,0,0.5}, p = "vfx_alpha_bolt01.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_DestructCast", vb = "VFX_DestructBolt", vh = "VFX_DestructHit", va = "VFX_DestructArea"}}

local MEN = {{610, "bolt", "Dummy bolt", 0.01, s=2, ss=2, "Dummy bolt", c0=0, c1=0, h=1, nod=1, nom=1, unr=1, ale=0, als=0, vfa = "VFX_DefaultArea", vfb = "VFX_DefaultBolt", sb = "Sound Test", tik = L.METW}}
for _,e in ipairs(MEN) do tes3.claimSpellEffectId(e[2], e[1])	tes3.addMagicEffect{id = e[1], name = e[3], baseCost = e[4], school = e.s, description = e[5] or e[3],
allowEnchanting = not e.ale, allowSpellmaking = not e.als, canCastSelf = not e.c0, canCastTarget = not e.c1, canCastTouch = not e.c2, isHarmful = not not e.h, hasNoDuration = not not e.nod, hasNoMagnitude = not not e.nom,
nonRecastable = not not e.nor, hasContinuousVFX = not not e.con, appliesOnce = not e.apo, unreflectable = not not e.unr, casterLinked = false, illegalDaedra = false, targetsAttributes = false, targetsSkills = false, usesNegativeLighting = false,
castSound = S[e.snd or e.ss or e.s].sc, boltSound = e.sb or S[e.snd or e.ss or e.s].sb, hitSound = S[e.snd or e.ss or e.s].sh, areaSound = S[e.snd or e.ss or e.s].sa,
castVFX = e.vfc or S[e.vfx or e.ss or e.s].vc, boltVFX = e.vfb or S[e.vfx or e.ss or e.s].vb, hitVFX = e.vfh or S[e.vfx or e.ss or e.s].vh, areaVFX = e.vfa or S[e.vfx or e.ss or e.s].va,
particleTexture = e.p or S[e.ss or e.s].p, icon = "s\\"..e[2]..".tga", speed = e.sp or 1, size = 1, sizeCap = 50, lighting = S[e.ss or e.s].l, onCollision = e.col or nil, onTick = e.tik or nil} end
	
tes3.findGMST("fTargetSpellMaxSpeed").value = 2000
end		event.register("initialized", initialized)