local cf = mwse.loadConfig("N'wah Shooter", {Proj = true, Prench = true, gravi = 2000, shake = 10, fatshake = 20, mbarc = 1, mbshot = 2, sklim = 100, fatmult = 30, enacc = true, bug1 = true, bug2 = true, arcdiv = true, auto = true,
spellspd = 4000, minspd = 2000, maxspd = 8000, maxspdthr = 6000, returnch = 100})

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("N'wah Shooter")	tpl:saveOnClose("N'wah Shooter", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Gravity power", min = 0, max = 5000, step = 100, jump = 500, variable = var{id = "gravi", table = cf}}

--p0:createSlider{label = "Hand shaking multiplier when archery", min = 0, max = 30, step = 1, jump = 1, variable = var{id = "shake", table = cf}}
p0:createSlider{label = "Mouse button to hold breath when archery (select 1 (LMB) for automatic hold)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbarc", table = cf}}
p0:createSlider{label = "Stamina consumption per second of breath holding when archery", min = 5, max = 50, step = 1, jump = 5, variable = var{id = "fatshake", table = cf}}
p0:createSlider{label = "Mouse button for alternative shots (press while holding LMB for bows and throwing weapons", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbshot", table = cf}}
p0:createSlider{label = "Marksman skill, upon reaching which you will have access to a multi-shot and fan throw", min = 50, max = 150, step = 1, jump = 10, variable = var{id = "sklim", table = cf}}
--p0:createSlider{label = "Stamina consumption per multi-shot", min = 10, max = 100, step = 1, jump = 10, variable = var{id = "fatmult", table = cf}}

p0:createYesNoButton{label = "Enable arrow spread for low agility and marksman skill", variable = var{id = "arcdiv", table = cf}}
p0:createYesNoButton{label = "Improved ranged enemy accuracy against a moving player", variable = var{id = "enacc", table = cf}}
p0:createYesNoButton{label = "Bug fix for non-shooting archers", variable = var{id = "bug1", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "Bug fix for arrows not hitting at point blank range", variable = var{id = "bug2", table = cf}}
p0:createYesNoButton{label = "Automatically equip arrows if necessary", variable = var{id = "auto", table = cf}}
p0:createYesNoButton{label = "Arrows get stuck on hit", variable = var{id = "Proj", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "Stuck arrows lose their enchantment", variable = var{id = "Prench", table = cf}}

p0:createSlider{label = "Spell projectile speed", min = 1000, max = 10000, step = 500, jump = 1000, variable = var{id = "spellspd", table = cf}, restartRequired = true}
p0:createSlider{label = "Minimum projectile speed", min = 1000, max = 5000, step = 500, jump = 1000, variable = var{id = "minspd", table = cf}, restartRequired = true}
p0:createSlider{label = "Maximum projectile speed (arrows)", min = 3000, max = 12000, step = 500, jump = 1000, variable = var{id = "maxspd", table = cf}, restartRequired = true}
p0:createSlider{label = "Maximum projectile speed (thrown)", min = 2000, max = 10000, step = 500, jump = 1000, variable = var{id = "maxspdthr", table = cf}, restartRequired = true}
p0:createSlider{label = "Chance to return the projectile", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "returnch", table = cf}, restartRequired = true}
end		event.register("modConfigReady", registerModConfig)


local p, mp, pp, PST, ad, wc, ic, MB, Sim, crot		local PRR = {}		local CPR = {}		local M = {}			local Matr = tes3matrix33.new()
local L = {BlackAmmo = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true, ["4nm_stone"] = true},
Summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["4nm_daedraspider_s"] = true,["4nm_dremora_mage_s"] = true,["4nm_skaafin_s"] = true,["4nm_xivkyn_s"] = true,["4nm_xivilai_s"] = true,["4nm_mazken_s"] = true,["4nm_ogrim_s"] = true,["4nm_skeleton_mage_s"] = true,["4nm_lich_elder_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true}}

local T = {Arb = timer, Met = timer}
local V = {METR = {}, up100 = tes3vector3.new(0,0,100), up = tes3vector3.new(0,0,1), up2 = tes3vector3.new(0,0,0.5), up3 = tes3vector3.new(0,0,0.2666), up64 = tes3vector3.new(0,0,64), up20 = tes3vector3.new(0,0,20),
down = tes3vector3.new(0,0,-1), down10 = tes3vector3.new(0,0,-10), nul = tes3vector3.new(0,0,0)}
local G = {LPP = V.nul, PspdNfr = 0}

L.GetArcVec = function(a,b)
	Matr:toRotationZ(math.random(-a,a)/200*G.ArcDiv)	local vec = crot * Matr
	Matr:toRotationX(math.random(-b,b)/200*G.ArcDiv)	vec = vec * Matr	return vec:transpose().y
end

L.UprPPos = function(rpos,spd,reset)	local newpos
	if not G.pcent or reset then
		if not mp.canMove then G.PspdR = 0 end
		G.pcent = pp + G.mph07
		G.PvelZ = mp.velocity.z
	end

	if G.PspdR > 0 then
	--	if V.dfr then G.PspdR = G.Pspd end
	--	local a = spd/G.PspdR
		local A = (spd/G.PspdR)^2
		local AB = rpos - G.pcent
		local b = AB:length()
		local c = math.cos(G.Pvec:angle(AB))
	--	local C = 2*b*c		-- local B = b^2
		
		local x = --A > 1 and 
		((b^2*(A + c^2 - 1))^0.5 - b*c) / (A-1)		--or ((b^2*(A + c^2 - 1))^0.5 + b*c) / (1-A)
		
		if x > 0 then
			newpos = G.pcent + G.Pvec * x
			if G.PvelZ ~= 0 then newpos.z = math.lerp(G.pcent.z, newpos.z, 0.25) end
		end
		
	--	tes3.messageBox("A = %.3f   Cos = %.3f   Dist = %d    Z = %d -> %d", A, c, x, G.pcent.z, newpos and newpos.z)
	end
	--	A*x^2 = B + x^2 - 2*b*x*c
	--	B + x^2 - C*x - A*x^2 = 0
	return newpos or G.pcent
end


local function ATTACK(e) local a = e.mobile
	if a ~= mp and a.actionData.physicalAttackType == 4 then
		if a.readiedAmmoCount == 0 then
			if not a.readiedAmmo then a.object:reevaluateEquipment() end		
			a.readiedAmmoCount = 1		tes3.messageBox("AMMO FIX!  %s", ar)
		end
	end
end		if cf.bug1 then event.register("attack", ATTACK) end


local function ATTACKHIT(e)
	if e.mobile == mp then	local rw = mp.readiedWeapon		local w = rw and rw.object		local wt = w and w.type or -1
		if wt > 8 then M.CombK.text = ("%s"):format((mp.readiedAmmoCount or 1) - 1) end
	end
end		--if cf.ammoc then event.register("attackHit", ATTACKHIT) end



local function CALCMOVESPEED(e) if e.mobile == mp then
	local Pvec = pp - G.LPP
	local delt = Pvec:length()
	if delt > 0 then
		if G.PspdNfr < 2 then
			G.Pvec = Pvec:normalized()
			G.PspdR = delt / wc.deltaTime
			G.LPP = pp:copy()
		--	tes3.messageBox("real %d   espd %d    vel = %d   delt = %d   Nulfr = %s", G.Pspd, e.speed, mp.velocity:length(), G.PspdR, G.PspdNfr)
		end
		G.PspdNfr = 0
	else
		if G.PspdNfr > 0 then
			G.Pvec = V.nul
			G.PspdR = 0
		--	tes3.messageBox("NULL %d   espd %d    vel = %d   delt = %d   Nulfr = %s", G.Pspd, e.speed, mp.velocity:length(), G.PspdR, G.PspdNfr)
		end
		G.PspdNfr = G.PspdNfr + 1
	end
end end		event.register("calcMoveSpeed", CALCMOVESPEED)




L.ArcSim = function(e) if mp.weaponDrawn and MB[1] == 128 then	local AS = ad.animationAttackState
	if G.arcf then
		if AS == 2 then	-- АС превращается из 2 в 4 а в следующем фрейме в 5 так как ЛКМ зажата.	Происходит выстрел и существующий nockedProjectile становится нил в следущем фрейме
			if ad.nockedProjectile and G.arcf < 5 then		ad.attackSwing = 0.5	ad.animationAttackState = 4		mp.animationController.weaponSpeed = 0.0001		G.arcf = G.arcf + 1
			else G.arcf = nil 	--mp.animationController.weaponSpeed = 1000000	--G.arcspd 	
				ad.nockedProjectile = nil 	ad.animationAttackState = 0		MB[1] = 0
			end
		elseif AS == 4 then		mp.animationController.weaponSpeed = G.arcspd
		elseif AS == 5 then ad.animationAttackState = 0	end		-- АС превращается из 5 в 0 а следующем фрейме в 2 так как ЛКМ зажата. nockedProjectile в этом фрейме нил но заряжается новый в следующем фрейме
		--tes3.messageBox("%s   AS = %s --> %s   %s   %s   Swing = %d", G.arcf, AS, ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, mp.readiedAmmoCount, ad.attackSwing*100)
	elseif AS == 2 then local dt = wc.deltaTime
		if MB[cf.mbarc] == 128 and PST.current > 10 then PST.current = PST.current - dt * cf.fatshake		dt = -dt end	G.artim = math.clamp((G.artim or 0) + dt,0,4)
		if G.artim > 0 then	local MS = ic.mouseState
			local x = (5 + mp.readiedWeapon.object.weight/4) * (1 - (math.min(mp.strength.current + mp.agility.current + mp:getSkillValue(23),300)/400)) * G.artim/4
			MS.x = MS.x + math.random(-2*x,2*x)		MS.y = MS.y + math.random(-x,x)
		end
	else G.artim = nil end
else event.unregister("simulate", L.ArcSim)	G.artim = nil	if G.arcf then G.arcf = nil		mp.animationController.weaponSpeed = G.arcspd end end end


L.MetSim = function(e) if mp.weaponDrawn and MB[1] == 128 and G.met < 5 then	local AS = ad.animationAttackState
	if AS == 0 then mp.animationController.weaponSpeed = 1000000
	elseif AS == 2 then	
		if ad.nockedProjectile then	ad.attackSwing = G.metsw		ad.animationAttackState = 4		G.met = G.met + 1		--if G.met == 0 then mp.animationController.weaponSpeed = 1000000	end
		else	mp.animationController.weaponSpeed = 1000000 end
	elseif AS == 4 then		mp.animationController.weaponSpeed = 1000000
	elseif AS == 5 then		
		if ad.nockedProjectile then ad.animationAttackState = 0 else	 mp.animationController.weaponSpeed = 1000000 end
	end
	--tes3.messageBox("%s   AS = %s --> %s   %s    Swing = %d", G.met, AS, ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, ad.attackSwing*100)
else event.unregister("simulate", L.MetSim)		G.met = nil		mp.animationController.weaponSpeed = G.arcspd end end




local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() then if e.button == 0 then
	if mp.weaponDrawn then	local w = mp.readiedWeapon	w = w and w.object
		if w and w.type == 9 then
			if not G.artim then G.artim = 0		event.register("simulate", L.ArcSim) end
		end
	end
elseif e.button + 1 == cf.mbshot then
	if G.artim and mp:getSkillValue(23) >= cf.sklim then	G.arcf = 0		G.arcspd = math.max(mp.animationController.weaponSpeed, 0.4)
		local w = mp.readiedWeapon		local wgt = (w and w.object.weight or 10) + 5
		PST.current = math.max(PST.current - wgt * 2, 0)
		
	elseif ad.animationAttackState == 2 then	local w = mp.readiedWeapon		w = w and w.object		local wt = w and w.type or -1	
		if wt == 11 and mp:getSkillValue(23) >= cf.sklim and not G.met then		local wgt = w.weight + 5
			--local ws = w.speed	G.metmax = ws > 1.4 and 5 or (ws > 1.2 and 4) or (ws > 0.9 and 3) or 2
			
			if T.Met.timeLeft then G.metsw = math.max(0.75 - T.Met.timeLeft/4, 0.25)	T.Met:reset() else G.metsw = 0.75		T.Met = timer.start{duration = 2, callback = function() end} end
			event.register("simulate", L.MetSim)		G.met = 1	ad.attackSwing = G.metsw	ad.animationAttackState = 4		mp.animationController.weaponSpeed = 1000000	G.arcspd = mp.animationController.weaponSpeed
			
			PST.current = math.max(PST.current - wgt * 5, 0)
		end
	end
end end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)



L.CPF = {
[10] = function(r,t)	-- Стрелы игрока
	t.m.velocity = t.m.velocity + tes3vector3.new(0,0,-cf.gravi * G.dt)
	Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
end
}


local function SimulateCP(e)	G.dt = wc.deltaTime		--G.pep = tes3.getPlayerEyePosition()		G.pev = tes3.getPlayerEyeVector()	G.hit = nil		G.prbase = nil		G.PrL = nil		G.pcent = nil	--G.cpfr = G.cpfr + 1	
	for r, t in pairs(CPR) do 
		L.CPF[t.mod](r,t)
		--if t.tim then	t.tim = t.tim - G.dt	if t.tim < 0 then CPR[r] = nil end end
		--tes3.messageBox("Anim = %.2f  Tim = %.2f   Sw = %.2f  Dam = %.2f  InSpd = %.2f   V = %d", t.m.animTime, t.tim or 0, t.m.attackSwing, t.m.damage, t.m.initialSpeed, t.m.velocity:length())
	end
	if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	Sim = nil end
end


local function MOBILEACTIVATED(e) local m = e.mobile		if m then local firm = m.firingMobile	if firm then 	local r = e.reference	local si = m.spellInstance
	if cf.bug2 and not si then r.position = r.position - m.velocity:normalized()*100 end
	
	if firm == mp then
		if not si then
			CPR[r] = {mod = 10, m = m, liv = 0}		if not Sim then event.register("simulate", SimulateCP)	Sim = 0 end
			local marstat = cf.arcdiv and mp.agility.current + mp:getSkillValue(23) or 200
			G.ArcDiv = ((G.arcf or G.met) and 3 or 1) - math.min(marstat/100, 1) + (mp.isRunning and 1 - math.min(marstat/200, 1) or 0)
			if G.ArcDiv > 0 then m.velocity = L.GetArcVec(20,10) * m.initialSpeed end		--tes3.messageBox("div =  %s ", G.ArcDiv)
		end
	elseif cf.enacc and firm.actionData.target == mp then
		local spd = m.initialSpeed
		local rpos = r.position
		m.velocity = L.UprPPos(rpos,spd,true) - rpos
		Matr:lookAt(m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
		m.velocity = m.velocity:normalized() * spd
	end
end end end		event.register("mobileActivated", MOBILEACTIVATED)



L.AMIC = {
["w\\tx_arrow_iron.tga"] = "iron arrow",
["w\\tx_arrow_bonemold.tga"] = "bonemold arrow",
["w\\tx_arrow_corkbulb.tga"] = "corkbulb arrow",
["w\\tx_arrow_chitin.tga"] = "chitin arrow",
["w\\tx_arrow_silver.tga"] = "silver arrow",
["w\\tx_arrow_glass.tga"] = "glass arrow",
["w\\tx_arrow_ebony.tga"] = "ebony arrow",
["w\\tx_arrow_daedric.tga"] = "daedric arrow",
["w\\tx_bolt_corkbulb.tga"] = "corkbulb bolt",
["w\\tx_bolt_iron.tga"] = "iron bolt",
["w\\tx_bolt_steel.tga"] = "steel bolt",
["w\\tx_bolt_silver.tga"] = "silver bolt",
["w\\tx_bolt_bonemold.tga"] = "bonemold bolt",
["w\\tx_bolt_orcish.tga"] = "orcish bolt",
["w\\tx_arrow_steel.tga"] = "steel arrow",
["w\\huntsman_bolt.dds"] = "BM Huntsmanbolt",
["w\\dwarven_bolt.tga"] = "dwarven bolt",
["w\\obsidian_arrow.dds"] = "6th arrow",
["w\\adamant_arrow.dds"] = "adamantium arrow",
["w\\adamant_bolt.dds"] = "adamantium bolt",
["w\\glass_bolt.dds"] = "glass bolt",
["w\\daedric_bolt.dds"] = "daedric bolt",
["w\\ebony_bolt.dds"] = "ebony bolt",
["w\\ice_arrow.dds"] = "BM ice arrow",
["w\\goblin_arrow.dds"] = "goblin arrow",
["w\\orcish_arrow.dds"] = "orcish arrow",
["w\\huntsman_arrow.dds"] = "BM huntsman arrow",
["w\\imp_arrow.dds"] = "imperial arrow",
["w\\imp_bolt.dds"] = "imperial bolt",
["w\\dwarven_arrow.dds"] = "dwarven arrow",
["w\\rawglass_arrow.dds"] = "rawglass arrow",
["w\\sky\\daedric_arrow.dds"] = "daedric_sky arrow",
["w\\sky\\dwarven_bolt2.dds"] = "dwarven_sky bolt",
["w\\sky\\dwarven_arrow.dds"] = "dwarven_sky arrow",
["w\\sky\\ebony_arrow.dds"] = "ebony_sky arrow",
["w\\sky\\elven_arrow.dds"] = "elven_sky arrow",
["w\\sky\\glass_arrow.dds"] = "glass_sky arrow",
["w\\sky\\iron_arrow.dds"] = "iron_sky arrow",
["w\\sky\\nord_arrow.dds"] = "nordic_sky arrow",
["w\\sky\\orcish_arrow.dds"] = "orcish_sky arrow",
["w\\sky\\steel_bolt.dds"] = "steel_sky bolt",
["w\\sky\\steel_arrow.dds"] = "steel_sky arrow",
["w\\cir\\daedric_arrow.dds"] = "daedric_obl arrow",
["w\\cir\\dwarven_arrow.dds"] = "dwarven_obl arrow",
["w\\cir\\ebony_arrow.dds"] = "ebony_obl arrow",
["w\\cir\\elven_arrow.dds"] = "elven_obl arrow",
["w\\cir\\glass_arrow.dds"] = "glass_obl arrow",
["w\\cir\\iron_arrow.dds"] = "iron_obl arrow",
["w\\cir\\silver_arrow.dds"] = "silver_obl arrow",
["w\\cir\\steel_arrow.dds"] = "steel_obl arrow",
["w\\tx_star_glass.tga"] = "glass throwing star",
["w\\tx_silver_star.tga"] = "silver throwing star",
["w\\tx_star_ebony.tga"] = "ebony throwing star",
["w\\tx_chitin_star.tga"] = "chitin throwing star",
["w\\tx_steel_star.tga"] = "steel throwing star",
["w\\adamant_star.tga"] = "adamantium star",
["w\\daedric_star.dds"] = "daedric star",
["w\\dwarven_star.tga"] = "dwarven star",
["w\\iron_star.tga"] = "iron star",
["w\\imp_star.dds"] = "imperial star",
["w\\nord_star.dds"] = "nordic star",
["w\\orcish_star.dds"] = "orcish star",
["w\\tx_w_dwarvenspheredart.dds"] = "centurion_projectile_dart",
["w\\tx_w_dart_steel.tga"] = "steel dart",
["w\\tx_dart_daedric.tga"] = "daedric dart",
["w\\tx_dart_ebony.tga"] = "ebony dart",
["w\\tx_dart_silver.tga"] = "silver dart",
["w\\orcish_dart.dds"] = "orcish dart",
["w\\adamant_dart.tga"] = "adamantium dart",
["w\\glass_dart.dds"] = "glass dart",
["w\\iron_dart.tga"] = "iron dart",
["w\\chitin_dart.dds"] = "chitin dart",
["w\\imp_dart.dds"] = "imperial dart",
["w\\nord_dart.dds"] = "nordic dart",
["w\\tx_steel_knife.dds"] = "steel throwing knife",
["w\\tx_knife_glass.tga"] = "glass throwing knife",
["w\\tx_knife_iron.tga"] = "iron throwing knife",
["w\\tx_dagger_dragon.tga"] = "steel throwing knife",
["w\\adamant_throwingknife.tga"] = "adamantium throwingknife",
["w\\chitin_throwingknife.tga"] = "chitin throwingknife",
["w\\daedric_throwingknife.tga"] = "daedric throwingknife",
["w\\ebony_throwingknife.tga"] = "ebony throwingknife",
["w\\silver_throwingknife.tga"] = "silver throwingknife",
["w\\obsidian_throwingknife.tga"] = "6th throwingknife",
["w\\chitin_throwingknife.dds"] = "chitin throwingknife",
["w\\dwarven_throwingknife.dds"] = "dwarven throwingknife",
["w\\imp_throwingknife.dds"] = "imperial throwingknife",
["w\\nord_throwingknife.dds"] = "nordic throwingknife",
["w\\orcish_throwingknife.dds"] = "orcish throwingknife",
["w\\iron_throwingaxe.dds"] = "iron throwingaxe",
["w\\nord_throwingaxe.dds"] = "nordic throwingaxe",
["w\\silver_throwingaxe.dds"] = "silver throwingaxe",
["w\\glass_throwingaxe.dds"] = "glass throwingaxe",
["w\\chitin_throwingaxe.dds"] = "chitin throwingaxe",
["w\\daedric_throwingaxe.dds"] = "daedric throwingaxe",
["w\\goblin_throwingaxe.dds"] = "goblin throwingaxe",
["w\\riekling_javelin.dds"] = "BM riekling javelin"}



local function onProj(e) local r = e.mobile.reference	local ob = r.object		local firr = e.firingReference		if not L.BlackAmmo[ob.id] and firr and not L.Summon[firr.baseObject.id] then
	local cp = e.collisionPoint		if cf.Prench and ob.enchantment then ob = L.AMIC[ob.icon:lower()]	ob = ob and tes3.getObject(ob) end	
	if ob and math.abs(cp.x) < 9000000 then		local vel = e.velocity		local pos, hr
		local hit = tes3.rayTest{position = cp - vel:normalized()*10, direction = vel, maxDistance = 250, findAll = true}			--cp + e.velocity * 0.7 * wc.deltaTime
		if hit then
			for i, h in pairs(hit) do hr = h.reference
				if not hr or not hr.mobile then pos = h.intersection	break end
			end
		end 
		if not pos then local hitd = tes3.rayTest{position = cp, direction = V.down, ignore = tes3.game.worldPickRoot}		pos = hitd and hitd.intersection end
		if pos then 
			Matr:lookAt(ob.type == 11 and ob.speed > 0.99 and ob.speed < 1.26 and vel * -1 or vel, V.up)
			local ref = tes3.createReference{object = ob, cell = p.cell, orientation = Matr:toEulerXYZ(), position = pos}	ref.modified = false	PRR[ref] = true
		end
	end
end end		if cf.Proj then event.register("projectileHitObject", onProj)	event.register("projectileHitTerrain", onProj) end




local function OBJECTINVALIDATED(e) local ob = e.object
	if CPR[ob] then CPR[ob] = nil end
	if PRR[ob] then PRR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)



local function EQUIPPED(e) if cf.auto and e.reference == p then	local o = e.item
	if o.objectType == tes3.objectType.weapon then local wt = o.type		--timer.delayOneFrame(function() L.GetWstat() end, timer.real)
		if wt == 9 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 12 then
			for _, s in pairs(p.object.inventory) do if s.object.type == 12 then mwscript.equip{reference = p, item = s.object} break end end
		elseif wt == 10 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 13 then
			for _, s in pairs(p.object.inventory) do if s.object.type == 13 then mwscript.equip{reference = p, item = s.object} break end end
		end
	end
end end		event.register("equipped", EQUIPPED)


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		pp = p.position		ad = mp.actionData		PST = mp.fatigue
	G.mph = mp.height		G.mph07 = tes3vector3.new(0,0,G.mph*0.7)			crot = wc.worldCamera.cameraRoot.rotation
	for ref, _ in pairs(PRR) do ref:delete() end		PRR = {}
	
--	local MU = tes3ui.findMenu("MenuMulti")
--	local WeIC = MU:findChild("MenuMulti_weapon_icon")
--	M.CombK = WeIC:createLabel{text = ""}	M.CombK.color = {1,1,1}		M.CombK.absolutePosAlignX = 1	M.CombK.absolutePosAlignY = 0


end		event.register("loaded", loaded)


local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = wc.inputController.mouseState.buttons
	wc.mobManager.terminalVelocity.z = -15000
	tes3.findGMST("fTargetSpellMaxSpeed").value = cf.spellspd
	tes3.findGMST("fProjectileMinSpeed").value = cf.minspd
	tes3.findGMST("fProjectileMaxSpeed").value = cf.maxspd
	tes3.findGMST("fThrownWeaponMinSpeed").value = cf.minspd	
	tes3.findGMST("fThrownWeaponMaxSpeed").value = cf.maxspdthr
	tes3.findGMST("fProjectileThrownStoreChance").value = cf.returnch
end		event.register("initialized", initialized)