local cf = mwse.loadConfig("PvP", {animsw = true, npcsw = true, pvpspd = 1, pvpproj = 1, pvpprdod = true, par = true, duel = true, pvpcont = true, aspd = true, tim = true, wspd = true, cone = true, round = true,
fastanim = true,
hitr = 0, volimp = 0.8, dmgmult = 0.5, atkmult = 0.25, dodcost = 30, dodmult = 1, acr = 75, agil = 100, scan = 1, dodkey = {keyCode = 54}, dmgind = true, m3 = false})

local function registerModConfig()		local template = mwse.mcm.createTemplate("PvP")	template:saveOnClose("PvP", cf)	template:register()		local p0 = template:createPage()	local var = mwse.mcm.createTableVariable
p0:createYesNoButton{label = "Enable parrying combat", variable = var{id = "par", table = cf}}
p0:createYesNoButton{label = "Duel mode: if an enemy parries you, you will lose stamina instead of losing balance, but you will no longer be able to break through the enemy parry", variable = var{id = "duel", table = cf}}
p0:createYesNoButton{label = "NPCs have a chance to instantly counterattack after parrying", variable = var{id = "pvpcont", table = cf}}
p0:createYesNoButton{label = "Increase attack frequency of enemies", variable = var{id = "aspd", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "Fix a bug inconsistency between attack power and swing animation", variable = var{id = "animsw", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "NPCs can now hold a swing", variable = var{id = "npcsw", table = cf}, restartRequired = true}
p0:createSlider{label = "Increase global hit chance (percentage)", min = 0, max = 500, step = 10, jump = 50, variable = var{id = "hitr", table = cf}}
p0:createYesNoButton{label = "Enable slow time on successful parry", variable = var{id = "tim", table = cf}}
p0:createDecimalSlider{label = "How fast NPCs move in melee combat (1 by default, 0 to disable)", variable = var{id = "pvpspd", table = cf}}
p0:createDecimalSlider{label = "How fast NPCs dodge your projectiles (1 by default, 0 to disable)", variable = var{id = "pvpproj", table = cf}}
p0:createYesNoButton{label = "Normal type of projectile dodging instead of jumping", variable = var{id = "pvpprdod", table = cf}}

p0:createYesNoButton{label = "Attacker stats affect attack speed", variable = var{id = "wspd", table = cf}}
p0:createYesNoButton{label = "Attacker stats and attack type affect the range and angle of attack", variable = var{id = "cone", table = cf}, restartRequired = true}
p0:createDecimalSlider{label = "How much does a weapon skill affect attack damage (0 to disable the effect)", variable = var{id = "dmgmult", table = cf}}
p0:createDecimalSlider{label = "How much does a attack bonus affect attack damage (0 to disable the effect)", variable = var{id = "atkmult", table = cf}}

p0:createYesNoButton{variable = var{id = "fastanim", table = cf}, label =
[[Use sharp animations for combo attacks instead of smooth ones if possible. Sharp animations look better in 1st person, smooth ones look better in 3rd person]]}

p0:createKeyBinder{variable = var{id = "dodkey", table = cf}, label = "Active dodge key"}
p0:createSlider{label = "Stamina cost for dodges", min = 10, max = 50, step = 5, jump = 10, variable = var{id = "dodcost", table = cf}}
p0:createDecimalSlider{label = "Dodge speed multiplier", min = 0.5, max = 2, variable = var{id = "dodmult", table = cf}}
p0:createSlider{label = "Acrobatics skill required to dodge in the air", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "acr", table = cf}}
p0:createSlider{label = "Agility required to break free of hitstun and instantly get back on your feet after being knocked down with dodge", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "agil", table = cf}}

p0:createYesNoButton{label = "You can make round attacks (two-handed weapons with full swing only)", variable = var{id = "round", table = cf}}
p0:createDecimalSlider{label = "NPC reaction time to player appearance (1 by default)", min = 0, max = 3, variable = var{id = "scan", table = cf}}
p0:createDecimalSlider{label = "Parry sound volume", variable = var{id = "volimp", table = cf}}
p0:createYesNoButton{label = "Show combat indicator", variable = var{id = "dmgind", table = cf}}
p0:createYesNoButton{label = "Show parry messages", variable = var{id = "m3", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local p, mp, ad, wc, ic, prm, MB, PST		local DOM = {}		local L = {FIL = {}}	local T = {Dom = timer, Tim = timer, EDMG = timer}		local AF = {}	local M = {}	
local G = {swingmult = 1, atspd = 1}	local W = {}
local V = {up = tes3vector3.new(0,0,1), up2 = tes3vector3.new(0,0,0.5), down = tes3vector3.new(0,0,-1), down10 = tes3vector3.new(0,0,-10), nul = tes3vector3.new(0,0,0)}
L.ASN = {[1] = 1, [14] = 1, [15] = 1, [18] = 1, [19] = 1}		L.AG = {[34] = "KO", [35] = "KO"}
L.PSO = {{1, 2, 3, 3}, {2, 2, 3, 3}, {3, 3, 3, 4}, {3, 3, 4, 4}}
L.CLR = {[1]={1,0,0}, [2]={1,0.5,0}, [3]={1,1,0}, [4]={0,1,0}, [5]={0,1,1}, [6]={0,0,1}, [7]={1,0,1}}
L.RSound = function(d) if not L.FIL[d] then L.FIL[d] = {}	for file in lfs.dir("data files\\sound\\4NM\\" .. d) do if file:endswith("wav") then table.insert(L.FIL[d], file) end end	end	return ("4NM\\%s\\%s"):format(d, table.choice(L.FIL[d])) end

local WT = {[-1]={s=26,p1="hand1",p2="hand2",p3="hand3",p4="hand4",p5="hand5",p6="hand6",p8="hand8",pc="hand12",snd="DmgFist",sws="SwingFist"},
[0]={s=22,p1="short1",p2="short2",p3="short3",p4="short4",p5="short5",p6="short6",p7="short7",p8="short8",p9="short9",p="short0",pc="short13",h1=true,dw=true,pso=1,iso=1,snd="DmgShort",sws="SwingShort",isnd="Short"},
[1]={s=5,p1="long1a",p2="long2a",p3="long3a",p4="long4a",p5="long5a",p6="long6a",p7="long7a",p8="long8a",p9="long9a",p="long0",pc="long9",h1=true,dw=true,pso=2,iso=2,snd="DmgLong",sws="SwingLong1",isnd="Long"},
[2]={s=5,p1="long1b",p2="long2b",p3="long3b",p4="long4b",p5="long5b",p6="long6b",p7="long7b",p8="long8b",p9="long9b",p="long0",pso=2,iso=2,snd="DmgLong",sws="SwingLong2",isnd="Long"},
[3]={s=4,p1="blu1a",p2="blu2a",p3="blu3a",p4="blu4a",p5="blu5a",p6="blu6a",p7="blu7a",p8="blu8a",p9="blu9a",p="blu0a",h1=true,dw=true,pso=4,iso=4,snd="DmgBlunt",sws="SwingBlunt1",isnd="Blunt"},
[4]={s=4,p1="blu1b",p2="blu2b",p3="blu3b",p4="blu4b",p5="blu5b",p6="blu6b",p7="blu7b",p8="blu8b",p9="blu9b",p="blu0a",pso=4,iso=4,snd="DmgBlunt",sws="SwingBlunt2",isnd="Blunt"},
[5]= {s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",pso=4,iso=4,snd="DmgBlunt",sws="SwingSpear",isnd="Blunt"},
[-3]={s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",h1=true,dw=true,pso=4,iso=4,snd="DmgBlunt",sws="SwingSpear",isnd="Blunt"},
[6]={s=7,p1="spear1",p2="spear2",p3="spear3",p4="spear4",p5="spear5",p6="spear6",p7="spear7",p8="spear8",p9="spear9",p="spear0",pso=3,iso=2,snd="DmgSpear",sws="SwingSpear",isnd="Spear"},
[-2]={s=7,p1="spear1a",p2="spear2a",p3="spear3a",p4="spear4a",p5="spear5a",p6="spear6a",p7="spear7a",p8="spear8a",p9="spear9a",p="spear0",h1=true,dw=true,pso=3,iso=2,snd="DmgSpear",sws="SwingSpear",isnd="Spear"},
[7]={s=6,p1="axe1a",p2="axe2a",p3="axe3a",p4="axe4a",p5="axe5a",p6="axe6a",p7="axe7a",p8="axe8a",p9="axe9a",p="axe0",h1=true,dw=true,pso=3,iso=3,snd="DmgAxe",sws="SwingAxe1",isnd="Axe"},
[8]={s=6,p1="axe1b",p2="axe2b",p3="axe3b",p4="axe4b",p5="axe5b",p6="axe6b",p7="axe7b",p8="axe8b",p9="axe9b",p="axe0",pso=3,iso=3,snd="DmgAxe",sws="SwingAxe2",isnd="Axe"},
[9]={s=23,p1="mark1a",p2="mark2a",p3="mark3a",p4="mark4a",p5="mark5a",p6="mark6a",p="mark0a",snd="DmgArrow",isnd="Bow"},
[10]={s=23,p1="mark1b",p2="mark2b",p3="mark3b",p4="mark4b",p5="mark5b",p6="mark6b",p="mark0b",snd="DmgBolt",isnd="Cross"},
[11]={s=23,p1="mark1c",p2="mark2c",p3="mark3c",p4="mark4c",p5="mark5c",p6="mark6c",p="mark0c",h1=true,snd="DmgArrow",sws="SwingThrow",isnd="Throw"},
[12]={isnd="Ammo"},
[13]={isnd="Ammo"}}

L.DmgInd = function(DMG, NewHP, BaseHP, Krit) M.EDB.current = NewHP		M.EDB.max = BaseHP	local n = NewHP/BaseHP	M.EDB.fillColor = {2-n*2, n*2, 0}	M.EDT.text = ("%d%s"):format(DMG, Krit and "!" or "")	M.EDBL.visible = true	T.EDMG:reset() end
L.ParInd = function(imp, col) M.EDB.current = 1		M.EDB.max = 1		M.EDB.fillColor = L.CLR[col]	M.EDT.text = ("%d"):format(imp)		M.EDBL.visible = true		T.EDMG:reset() end

L.NoBorder = function(el, x) el.contentPath = "meshes\\menu_thin_border_0.nif"	if not x then el:findChild("PartFillbar_colorbar_ptr").borderAllSides = 0 end end
L.CrimeAt = function(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end

L.SectorDod = function() if cf.pvpproj > 0 and not T.Dom.timeLeft then		T.Dom = timer.start{duration = 0.3, callback = function() end}
	for i, m in pairs(prm.allMobileActors) do
		if not L.ASN[m.actionData.animationAttackState] and not m.isFalling and not m.isHitStunned then	local ang = mp:getViewToActor(m)
			if m.inCombat and math.abs(ang) < 15 and math.abs(m:getViewToActor(mp)) < 45 then	local ch = m.agility.current + m.sanctuary		
				if ch > math.random(100) then
					local spd = math.min(((m.isMovingForward and 200 or 100) + ch + m.speed.current*2) * (1 - math.min(m.encumbrance.normalized,1)*0.75) * (0.5 + m.fatigue.normalized/2), 500) * cf.pvpproj
					local r = m.reference
					if cf.pvpprdod then
						DOM[m] = {v = r.rightDirection * ((ang > 0 and -1 or 1) * spd), fr = 0.4}
					else
						local vec = r.rightDirection * (ang > 0 and -1 or 1) + V.up2	if m.isMovingForward then vec = vec + r.forwardDirection end
						m:doJump{velocity = vec * spd, applyFatigueCost = false}
					end
					--tes3.messageBox("Dodge %s   %d%%   spd = %d   fov = %s   Ang = %d", r, ch, spd, m.isMovingForward, ang)
				end
			end
		end
	end
end end


L.DodM = function(r,m,pos) if not L.ASN[m.actionData.animationAttackState] and not m.isFalling and not m.isHitStunned then		local spd		local ch = m.agility.current + m.sanctuary		local rand = math.random(100)
	if ch > rand then spd = 1 elseif ch*2 > rand then spd = 0.5 end
	if spd then
		spd = math.min((200 + ch + m.speed.current*2) * (1 - math.min(m.encumbrance.normalized,1)*0.75) * (0.5 + m.fatigue.normalized/2), 500) * cf.pvpspd * spd
		local w = m.readiedWeapon		local rng = 20 + 130 * (w and w.object.reach or 0.7)
		DOM[m] = {v = (pos + r.rightDirection * table.choice{rng,-rng} - r.position):normalized() * spd, fr = 0.4}
	end
end end


local function CALCMOVESPEED(e) local m = e.mobile
if m == mp then
	if V.dfr then	if V.djf then mp.isJumping = true end
		mp.impulseVelocity = V.d		V.dfr = V.dfr - wc.deltaTime
		if V.dfr <= 0 then	V.dfr = nil
			if V.djf then V.djf = nil	mp.isJumping = false end
		--	if G.daf then mp.animationController.weaponSpeed = G.daf	G.daf = nil end
		--	if V.dkik then V.dkik = nil		L.KIK() end
		--	G.DashD = 0
		end
	end
else
	if DOM[m] then	local t = DOM[m]
		m.impulseVelocity = t.v		t.fr = t.fr - wc.deltaTime
		if t.fr < 0 then DOM[m] = nil end
	end
end
end		event.register("calcMoveSpeed", CALCMOVESPEED)



local function KEYDOWN(e) if not tes3ui.menuMode() then		if e.keyCode == cf.dodkey.keyCode and mp.paralyze < 1 then
	if mp.hasFreeAction then
		local stam = cf.dodcost * (1 + mp.encumbrance.normalized)
		if not V.dfr and (mp.acrobatics.current >= cf.acr or not mp.isFalling) and stam < PST.current then	V.d = nil
			if mp.isMovingRight then V.d = p.rightDirection elseif mp.isMovingLeft then V.d = p.rightDirection * -1 end
			if mp.isMovingForward then V.d = (V.d or V.nul) + p.forwardDirection elseif mp.isMovingBack then V.d = (V.d or V.nul) + p.forwardDirection * -1 elseif not V.d then V.d = p.forwardDirection end
			local Base = 100 + mp.sanctuary + mp.agility.current/2 + mp.speed.current/2 + mp.acrobatics.current/2
			local StamK = math.min(math.lerp(0.75, 1, PST.normalized * 2), 1)
			G.dodm = Base * StamK * cf.dodmult
			V.d = V.d:normalized() * G.dodm / 0.1			V.dfr = 0.1		
			PST.current = PST.current - stam
			tes3.playSound{soundPath = L.RSound("Dodge"), volume = 1, pitch = math.random(90,110)/100}
			if mp.agility.current >= cf.agil and mp.isHitStunned and ad.animationAttackState == 1 then ad.animationAttackState = 0 end
			if not mp.isJumping then V.djf = true	mp.isJumping = true end
		end
	elseif mp.isKnockedDown and mp.agility.current >= cf.agil then
		local stc = cf.dodcost * (1 + mp.encumbrance.normalized) * 3
		if PST.current > stc then PST.current = PST.current - stc		ad.animationAttackState = 0 end
	end	
end end end		event.register("keyDown", KEYDOWN)



L.AS = {[0]=2, [2]=2, [3]=0, [4]=0, [5]=1, [6]=1, [7]=1}		L.COMOV = {[0]=2, [1]=3, [2]=1, [3]=2}			--L.ASAR = {[4]=1, [5]=1, [6]=1, [7]=1}
L.WCO = {[1] =	{[1] = {[2]=1}, 				[2] = {[2]=1},					[3] = {[0]=2, [2]=1, [3]=2}},
[3] =			{[1] = {[0]=1, [2]=1}, 			[2] = {[2]=1},					[3] = {[0]=2, [2]=1, [3]=2}},
[2] =			{[1] = {[0]=2, [2]=1, [3]=2},	[2] = {},						[3] = {[0]=2, [2]=1, [3]=2}},
[0] =			{[1] = {[2]=1},					[2] = {[0]=3, [1]=3, [2]=1},	[3] = {[2]=1},	[4] = {}}
}


L.WComb = function() local dir = ad.physicalAttackType	
	local w = mp.readiedWeapon		w = w and w.object		G.cot = w and (w.isOneHanded and 1 or 2) or 0
	local mov = ((mp.isMovingForward or mp.isMovingBack) and 1 or 0) + ((mp.isMovingLeft or mp.isMovingRight) and 2 or 0)		local newd = L.COMOV[mov]		local sw = ad.attackSwing
	local new = L.WCO[G.cot][dir][mov]
	
	if new then
		G.swingmult = 1 + sw
		if G.cot == 0 or not cf.fastanim then MB[1] = 0 end
		ad.animationAttackState = 0		G.NewAtDir = new
		
		if swap then L.DWSwap() end
	--	tes3.messageBox("Ideal  SW %.3f  Mult %.3f    Dir = %s  New = %s", sw, G.swingmult, dir, new)
	elseif newd ~= dir then
		G.swingmult = 1 + sw
		MB[1] = 0		ad.animationAttackState = 0	
	--	tes3.messageBox("Half   SW %.3f  Mult %.3f    Dir = %s  NewD = %s", sw, G.swingmult, dir, newd)
	end
end

L.WSim = function(e) if mp.weaponDrawn and MB[1] == 128 then
	if L.AS[ad.animationAttackState] == 1 then
		L.WComb() 	event.unregister("simulate", L.WSim)	W.Wsim = nil
	end
else event.unregister("simulate", L.WSim)	W.Wsim = nil end end


local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() then local But = e.button + 1		if But == 1 then
	if mp.weaponDrawn then	local w = mp.readiedWeapon		w = w and w.object		local wt = w and w.type or -1		local as = ad.animationAttackState
		if wt < 9 then
			if as > 0 then
				if L.AS[as] == 1 then	L.WComb()
				elseif not W.Wsim then event.register("simulate", L.WSim)	W.Wsim = 1 end
			end
		end
	end
end end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)




local function ATTACKSTART(e) local a = e.mobile		local w = a.readiedWeapon	w = w and w.object 		local wt = w and w.type or -1		
	if a ~= mp and e.attackType ~= 4 then	local ar = e.reference		local tar = a.actionData.target
		if cf.pvpspd > 0 and tar then L.DodM(ar, a, tar.reference.position) end
	end
	
	if cf.wspd then
		e.attackSpeed = e.attackSpeed * (0.8
		+ a.speed.current/1000
		+ a:getSkillValue(WT[wt].s)/500
		- (1 - math.min(a.fatigue.normalized,1)) * 0.1
		- math.min(a.encumbrance.normalized * 0.1, 0.5)  )
	end
	
	if a == mp then
		if wt < 9 then
			if G.NewAtDir then e.attackType = G.NewAtDir 	G.NewAtDir = nil end
			G.atspd = e.attackSpeed
			e.attackSpeed = G.atspd * G.swingmult * (mp.isHitStunned and 0.5 or 1)
		--	tes3.messageBox("AtStart! (%s)  dir = %s  spd = %.3f -> %.3f   Mult = %s   HS = %s", wt, e.attackType, G.atspd, e.attackSpeed, G.swingmult, mp.isHitStunned)
			G.swingmult = 1
		end
	end
end		event.register("attackStart", ATTACKSTART)


local function CALCHITDETECTIONCONE(e) local a = e.attackerMobile	local w = a.readiedWeapon	w = w and w.object 		local wt = w and w.type or -1
	if wt < 9 then	local ad = a.actionData		local dir = ad.physicalAttackType
		e.reach = e.reach
		+ math.min(a.agility.current,100)/2000
		+ math.min(a:getSkillValue(WT[wt].s),100)/2000
		+ (dir == 3 and 0.05 or 0)
		
		if a == mp then		W.rng = e.reach
			if dir == 1 then e.angleXY = 90
			elseif dir == 2 then e.angleXY = 30		e.angleZ = 60
			elseif dir == 3 then e.angleXY = 20 end
		end
		--tes3.messageBox("Cone %s   At = %s   Rea = %.3f  %d     Ang = %.3f   %.3f    %s", e.attacker, dir, e.reach, e.reach * 128, e.angleXY, e.angleZ, e.target or "")
	end
end		if cf.cone then event.register("calcHitDetectionCone", CALCHITDETECTIONCONE) end



local function CALCHITCHANCE(e)		local a = e.attackerMobile	local ad = a.actionData		local dir = ad.physicalAttackType
	if a ~= mp then
		if dir ~= 4 then ad.attackSwing = math.lerp(0.5, 1, ad.attackSwing) end
	end
--	tes3.messageBox("Hit chance!  Sw = %.3f  FizD = %.2f", ad.attackSwing, ad.physicalDamage)
	e.hitChance = e.hitChance + cf.hitr
end		event.register("calcHitChance", CALCHITCHANCE)


local function ATTACK(e) local a = e.mobile		local ad = a.actionData		local ar = e.reference		local dir = ad.physicalAttackType
	local rw = a.readiedWeapon	local w = rw and rw.object		local wt = w and w.type or -1
	
	
	
	if a == mp then
		if dir ~= 4 then
			mp.animationController.weaponSpeed = G.atspd
		--	tes3.messageBox("Swing = %.4f   AtSpd = %.3f  HS = %s", ad.attackSwing, G.atspd, mp.isHitStunned)
		end
	else	
		if dir == 4 then
			ad.attackSwing = wt == 10 and 1 or math.lerp(0.75, 1, ad.attackSwing)
			if a.readiedAmmoCount == 0 then		if not a.readiedAmmo then a.object:reevaluateEquipment() end		a.readiedAmmoCount = 1		tes3.messageBox("AMMO FIX!  %s", ar) end
		else
			local tr = e.targetReference
			if cf.pvpspd > 0 and ar.tempData.hum and tr then L.DodM(ar, a, tr.position) end
		end
	--	tes3.messageBox("Attack!  Sw = %.3f  FizD = %.2f", ad.attackSwing, ad.physicalDamage)
	end
	
	if w then
		ar.tempData.Parried = nil 
	--	ad.physicalDamage = ad.physicalDamage * (100 + a:getSkillValue(WT[wt].s) * cf.dmgmult + a.attackBonus * cf.atkmult)/100
	end	
end		event.register("attack", ATTACK)


local function ATTACKHIT(e) local a = e.mobile	local ar = e.reference		local ad = a.actionData		local t = e.targetMobile
	local rw = a.readiedWeapon	local w = rw and rw.object		local wt = w and w.type or -1
--	tes3.messageBox("At hit!  Sw = %.3f  FizD = %.2f", ad.attackSwing, ad.physicalDamage)
	
	if a == mp then		
		if wt < 9 then
			if not t then	
				local hit = tes3.rayTest{position = tes3.getPlayerEyePosition() + V.down10, direction = tes3.getPlayerEyeVector(), maxDistance = 135 * (w and w.reach or 0.5), ignore = {p}}
				if hit then local ref = hit.reference	local mob = ref and ref.mobile		
					if mob and not mob.isDead and not ad.hitTarget then ad.hitTarget = mob		t = mob end
				end
			end
		end
		
		if w then
			if cf.round and w.isTwoHanded and ad.physicalAttackType == 1 and ad.attackSwing > 0.95 then
				local dmg = ad.physicalDamage/2		local fdmg = 0	local num = 0	local ref
				for _, m in pairs(tes3.findActorsInProximity{reference = p, range = w.reach * 150}) do if m ~= mp and m ~= t and tes3.getCurrentAIPackageId(m) ~= 3 then	num = num + 1	ref = m.reference
					if m.actionData.animationAttackState == 4 and m.readiedWeapon and m.readiedWeapon.object.type < 9 then
						m.actionData.animationAttackState = 0		tes3.playAnimation{reference = ref, group = 0x0, loopCount = 0}
						tes3.playSound{reference = ref, soundPath = L.RSound("Parry" .. L.PSO[WT[wt].pso][WT[m.readiedWeapon.object.type].pso]), volume = cf.volimp, pitch = math.random(80,120)/100}
					else --G.DmgR[ref] = WT[wt].snd
						fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true, resistAttribute = not (w.enchantment or w.ignoresNormalWeaponResistance) and 12 or nil}		L.CrimeAt(m)
					end
					if cf.m3 then tes3.messageBox("Round attack! %s (%d)  Dmg = %d/%d",  m.object.name, num, fdmg, dmg) end
				end end
			end
		end
		
	elseif wt < 9 and not ad.hitTarget and ad.target == mp then ad.hitTarget = mp	t = mp end
	
	if cf.par and t then	local tad = t.actionData		if tad.animationAttackState == 4 then		local tr = t.reference
		local trw = t.readiedWeapon		local tw = trw and trw.object		local twt = tw and tw.type or -1
		if w and wt < 9 and tw and twt < 9 and not ar.tempData.Parried and (w.reach + tw.reach) * 150 > ar.position:distance(tr.position) then
			local TFD = tad.physicalDamage		local FD = ad.physicalDamage		local wgt = w.weight	local twgt = tw.weight
			local AFiz = ((WT[wt].h1 and 100 or 150) + a.strength.current/2 + a:getSkillValue(WT[wt].s)/2 + a.attackBonus/5) * math.min(math.lerp(0.75, 1, a.fatigue.normalized*1.1), 1)
			local TFiz = ((WT[twt].h1 and 100 or 150) + t.strength.current/2 + t:getSkillValue(WT[twt].s)/2 + t.attackBonus/5) * math.min(math.lerp(0.75, 1, t.fatigue.normalized*1.1), 1)
			
			local PK1 = (wgt*5 + AFiz + a.agility.current/2 + a:getSkillValue(0)) * (ad.attackSwing + (a == mp and 0 or 0.25)) * (WT[wt].h1 and 1 or 1.25)
			local PK2 = (twgt*5 + TFiz + t.agility.current/2) * tad.attackSwing * (WT[twt].h1 and 1 or 1.25) * (t == mp and math.clamp(t.animationController.weaponSpeed, 0.25, 1) or 1)
			local park = PK1 / PK2		local imp = (PK1 - PK2) * (1 + t.encumbrance.normalized/2)
			rw.variables.condition = math.max(rw.variables.condition - FD * 0.1, 0)
			trw.variables.condition = math.max(trw.variables.condition - FD * 0.1, 0)
			ad.physicalDamage = 0
		
			if park > 1 then	tad.physicalDamage = 0
				if t == mp then
					if cf.duel then
						MB[1] = 0		tad.animationAttackState = 0
						mp.fatigue.current = math.max(mp.fatigue.current - imp/20, 0)
					else
						AF[tr].part = timer.start{duration = math.clamp(imp/500, 0.1, 1), callback = function()
							if imp < 500 then
								--tes3.messageBox("Player! %s  HS = %s", tad.animationAttackState, t.isHitStunned)
								if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
							end 
						AF[tr].part = nil end}
						MB[1] = 0		tad.animationAttackState = 0	t:hitStun()
					end
				else 
					AF[tr].part = timer.start{duration = math.clamp(imp/500, 0.1, 1), callback = function() if AF[tr] then
						--tes3.messageBox("    %s  HS = %s  Imp = %d", tad.animationAttackState, t.isHitStunned, imp)
						if imp < 500 then
							tad.animationAttackState = 0
						end 
					AF[tr].part = nil end end}
					tad.animationAttackState = 1	t:hitStun()
					DOM[t] = nil
				end
				
				if a == mp then	
					if cf.tim and not T.Tim.timeLeft then	local lasttime = wc.simulationTimeScalar	wc.simulationTimeScalar = wc.simulationTimeScalar/2
						T.Tim = timer.start{duration = 0.5, callback = function() wc.simulationTimeScalar = lasttime end}
					end
				end
				
			elseif park > 0.75 then		tad.physicalDamage = 0
				if t == mp then		tr.tempData.Parried = true
				else
					DOM[t] = nil		tad.animationAttackState = 0		tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}
				end	
			else
				tr.tempData.Parried = true
				if t == mp and cf.duel then	tad.physicalDamage = 0
				else
					local NewTFD = TFD * (1 - park)		if NewTFD < 3 then NewTFD = 0 end
					tad.physicalDamage = NewTFD
				end
			end
			
			if cf.m3 then tes3.messageBox("Par! %s (%s)    %.2f = %d/%d    fiz = %.2f/%.2f    spd = %.2f   Imp = %d",
			ar.baseObject.name, tad.animationAttackState, park, PK1, PK2, FD, TFD, t.animationController.weaponSpeed, imp) end

			tes3.playSound{reference = (a==mp or t==mp) and p or ar, soundPath = L.RSound("Parry" .. L.PSO[WT[wt].pso][WT[twt].pso]), volume = cf.volimp, pitch = math.random(80,120)/100}
			tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = (ar.position + tes3vector3.new(0,0,a.height*0.9) + tr.position + tes3vector3.new(0,0,t.height*0.9)) / 2}
			
			if a == mp then
				if cf.dmgind then L.ParInd(imp/20, park > 1 and 5 or 3) end
				mp:exerciseSkill(WT[wt].s, 1)		mp:exerciseSkill(0, 1)
			else
				ad.animationAttackState = 0		tes3.playAnimation{reference = ar, group = 0x0, loopCount = 0}
				if cf.pvpcont and a:getSkillValue(WT[wt].s) + a.agility.current > math.random(200) then a:forceWeaponAttack() end
			
				if t == mp then		if cf.dmgind then L.ParInd(imp/20, park > 1 and 1 or 2) end		end
			end
		end
	end end

end		event.register("attackHit", ATTACKHIT)


local function damage(e) if e.source == "attack" then	local a = e.attacker	local rw = a.readiedWeapon		local pr = e.projectile		local WS		
	local w = pr and pr.firingWeapon or (rw and rw.object)		local wt = w and w.type or -1
	if a.actorType == 0 then WS = a.combat.current else WS = a:getSkillValue(WT[wt].s) end	
	
	e.damage = e.damage * (100 + WS * cf.dmgmult + a.attackBonus * cf.atkmult)/100
end	end		event.register("damage", damage)

local function damaged(e) if cf.dmgind and e.source == "attack" then	local t = e.mobile
	if e.attacker == mp then	local hp = e.mobile.health		L.DmgInd(e.damage, hp.current, hp.base) end
end	end		event.register("damaged", damaged)


local function MOBILEACTIVATED(e)	local m = e.mobile 		if m then	local r = e.reference	local firm = m.firingMobile
	if firm then	local si = m.spellInstance
		if firm == mp then L.SectorDod() end

--		if not si then		
--			local w = m.firingWeapon	local wt = w.type	local WS = firm.actorType == 0 and firm.combat.current or firm:getSkillValue(WT[wt].s)	
--			m.damage = m.damage * (100 + WS * cf.dmgmult + firm.attackBonus * cf.atkmult)/100
--		end
		
	else	local actort = m.actorType 
		if actort then	local ob = r.object		AF[r] = {}
			if actort == 1 or ob.biped then r.tempData.hum = true end
			if m.fight > 49 then m.scanInterval = cf.scan end
		end
	end
end end		event.register("mobileActivated", MOBILEACTIVATED)


local function MOBILEDEACTIVATED(e) local r = e.reference
	if AF[r] then	if AF[r].part then AF[r].part:cancel() end	AF[r] = nil end
end		event.register("mobileDeactivated", MOBILEDEACTIVATED)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		AF[p] = {}		W = {}		PST = mp.fatigue		ad = mp.actionData
if cf.tim then wc.simulationTimeScalar = 1 end

M.EDBL = tes3ui.findMenu("MenuMulti"):createBlock{}	M.EDBL.autoHeight = true	M.EDBL.autoWidth = true		M.EDBL.absolutePosAlignX = 0.5	M.EDBL.absolutePosAlignY = 0.52		M.EDBL.flowDirection = "top_to_bottom"		M.EDBL.visible = false
M.EDb = M.EDBL:createFillBar{current = 100, max = 100}	M.EDb.width = 30	M.EDb.height = 5	L.NoBorder(M.EDb)	M.EDB = M.EDb.widget
M.EDT = M.EDBL:createLabel{text = ""}	M.EDT.absolutePosAlignX = 0.5	M.EDT.color = {1,1,1}	M.EDT.font = 1
T.EDMG = timer.start{duration = 1, iterations = 1, callback = function() M.EDBL.visible = false end}	T.EDMG:cancel()
end		event.register("loaded", loaded)


local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = ic.mouseState.buttons		prm = wc.mobManager.processManager

G.VFXspark = tes3.createObject{objectType = tes3.objectType.static, id = "VFX_WSparks", mesh = "e\\spark.nif"}

if cf.aspd then tes3.findGMST("fCombatDelayCreature").value = -0.4		tes3.findGMST("fCombatDelayNPC").value = -0.4 end
if cf.animsw then
	mwse.memory.writeBytes{address = 0x541530, bytes = { 0x8B, 0x15, 0xDC, 0x67, 0x7C, 0x00, 0xD9, 0x42, 0x2C, 0x8B, 0x41, 0x3C, 0xD8, 0x88, 0xDC, 0x04, 0x00, 0x00, 0x8B, 0x51, 0x38, 0x8D, 0x82, 0xCC, 0x00, 0x00, 0x00, 0xD8, 0x40, 0x08, 0xD9, 0x58, 0x08, 0xC7, 0x41, 0x10, 0x00, 0x00, 0x80, 0xBF, 0xC6, 0x40, 0x11, 0x03, 0xD9, 0x41, 0x2C, 0xD8, 0x1D, 0x68, 0x64, 0x74, 0x00, 0xDF, 0xE0, 0xF6, 0xC4, 0x40, 0x75, 0x0B, 0x8B, 0x41, 0x2C, 0x89 } }
	mwse.memory.writeBytes{address = 0x5414E0, bytes = { 0x8B, 0x46, 0x3C, 0xD8, 0x88, 0xDC, 0x04, 0x00, 0x00, 0x8B, 0x46, 0x38, 0xD8, 0x80, 0xD4, 0x00, 0x00, 0x00, 0xD9, 0x98, 0xD4, 0x00, 0x00, 0x00, 0xD9, 0x46, 0x20, 0xD8, 0x1D, 0x68, 0x64, 0x74, 0x00, 0xDF, 0xE0, 0xF6, 0xC4, 0x40, 0x75, 0x1F, 0x8B, 0x46, 0x3C, 0xD9, 0x40, 0x5C, 0x8B, 0x0D, 0xDC, 0x67, 0x7C, 0x00, 0xD8, 0x41, 0x2C, 0xD8, 0x5E, 0x20, 0xDF, 0xE0, 0xF6, 0xC4, 0x01, 0x75, 0x06, 0x8B, 0x56, 0x20, 0x89, 0x56, 0x10, 0x5E, 0x5B, 0xC2, 0x04, 0x00 } }
end
if cf.npcsw then	
	mwse.memory.writeBytes{address = 0x54147A, bytes = { 0x8B, 0x90, 0x88, 0x03, 0, 0, 0x0A, 0x90, 0x28, 0x02, 0, 0, 0x85, 0xD2, 0x75, 0x04, 0x84, 0xDB, 0x75, 0x3D } }
	mwse.memory.writeBytes{address = 0x5414B4, bytes = { 0xD9, 0x46, 0x20, 0xD8, 0x66, 0x18, 0xDE, 0xF9, 0xEB, 0x03 } }
end


end		event.register("initialized", initialized)