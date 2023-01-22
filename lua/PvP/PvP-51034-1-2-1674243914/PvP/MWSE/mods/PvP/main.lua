
local cf = mwse.loadConfig("PvP", {animsw = true, npcsw = true, pvp = true, pvp1 = true, par = true, aspd = true, tim = true, hitr = 0, m3 = false})

local function registerModConfig()		local template = mwse.mcm.createTemplate("PvP")	template:saveOnClose("PvP", cf)	template:register()		local p0 = template:createPage()	local var = mwse.mcm.createTableVariable
p0:createYesNoButton{label = "Enable PvP-mode (NPCs move better in combat)", variable = var{id = "pvp", table = cf}}
p0:createYesNoButton{label = "NPCs will try to dodge your projectiles", variable = var{id = "pvp1", table = cf}}
p0:createYesNoButton{label = "Enable parrying combat", variable = var{id = "par", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "Increase attack frequency of enemies", variable = var{id = "aspd", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "Fix a bug inconsistency between power and swing animation", variable = var{id = "animsw", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "NPCs can now hold a swing", variable = var{id = "npcsw", table = cf}, restartRequired = true}
p0:createSlider{label = "Increase global hit chance (percentage)", min = 0, max = 200, step = 10, jump = 50, variable = var{id = "hitr", table = cf}}
p0:createYesNoButton{label = "Enable slow time on successful parry", variable = var{id = "tim", table = cf}}
p0:createYesNoButton{label = "Show parry messages", variable = var{id = "m3", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local p, mp, wc, ic, MB		local DOM = {}		local L = {}	local T = {Dom = timer, Tim = timer}		local N = {}	local AF = {}
local V = {up = tes3vector3.new(0,0,1), up2 = tes3vector3.new(0,0,0.5), down = tes3vector3.new(0,0,-1), nul = tes3vector3.new(0,0,0)}
L.ASN = {[1] = 1, [14] = 1, [15] = 1, [18] = 1, [19] = 1}		L.AG = {[34] = "KO", [35] = "KO"}
L.PSO = {{{1,4},{2,4},{2,4}}, {{2,4},{2,4},{3,3}}, {{2,4},{3,3},{3,3}}}
local WT = {[-1]={s=26,p1="hand1",p2="hand2",p3="hand3",p4="hand4",p5="hand5",p6="hand6",p8="hand8",pc="hand12"},
[0]={s=22,p1="short1",p2="short2",p3="short3",p4="short4",p5="short5",p6="short6",p7="short7",p8="short8",p9="short9",p="short0",pc="short13",h1=true,dw=true,pso=1},
[1]={s=5,p1="long1a",p2="long2a",p3="long3a",p4="long4a",p5="long5a",p6="long6a",p7="long7a",p8="long8a",p9="long9a",p="long0",pc="long9",h1=true,dw=true,pso=1},
[2]={s=5,p1="long1b",p2="long2b",p3="long3b",p4="long4b",p5="long5b",p6="long6b",p7="long7b",p8="long8b",p9="long9b",p="long0",pso=1},
[3]={s=4,p1="blu1a",p2="blu2a",p3="blu3a",p4="blu4a",p5="blu5a",p6="blu6a",p7="blu7a",p8="blu8a",p9="blu9a",p="blu0a",h1=true,dw=true,pso=3},
[4]={s=4,p1="blu1b",p2="blu2b",p3="blu3b",p4="blu4b",p5="blu5b",p6="blu6b",p7="blu7b",p8="blu8b",p9="blu9b",p="blu0a",pso=3},
[5]= {s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",pso=3},
[-3]={s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",h1=true,dw=true,pso=3},
[6]={s=7,p1="spear1",p2="spear2",p3="spear3",p4="spear4",p5="spear5",p6="spear6",p7="spear7",p8="spear8",p9="spear9",p="spear0",pso=2},
[-2]={s=7,p1="spear1a",p2="spear2a",p3="spear3a",p4="spear4a",p5="spear5a",p6="spear6a",p7="spear7a",p8="spear8a",p9="spear9a",p="spear0",h1=true,dw=true,pso=2},
[7]={s=6,p1="axe1a",p2="axe2a",p3="axe3a",p4="axe4a",p5="axe5a",p6="axe6a",p7="axe7a",p8="axe8a",p9="axe9a",p="axe0",h1=true,dw=true,pso=2},
[8]={s=6,p1="axe1b",p2="axe2b",p3="axe3b",p4="axe4b",p5="axe5b",p6="axe6b",p7="axe7b",p8="axe8b",p9="axe9b",p="axe0",pso=2},
[9]={s=23,p1="mark1a",p2="mark2a",p3="mark3a",p4="mark4a",p5="mark5a",p6="mark6a",p="mark0a"},
[10]={s=23,p1="mark1b",p2="mark2b",p3="mark3b",p4="mark4b",p5="mark5b",p6="mark6b",p="mark0b"},
[11]={s=23,p1="mark1c",p2="mark2c",p3="mark3c",p4="mark4c",p5="mark5c",p6="mark6c",p="mark0c",h1=true}}


L.CDOD = {["atronach_flame"] = 1, ["atronach_flame_summon"] = 1, ["atronach_flame_lord"] = 1, ["scamp"] = 1, ["clannfear"] = 1, ["clannfear_lesser"] = 1, ["clannfear_summon"] = 1, ["vermai"] = 1,
["hunger"] = 1, ["hunger_summon"] = 1, ["winged twilight"] = 1, ["winged twilight_summon"] = 1, ["daedraspider"] = 1, ["daedraspider_s"] = 1,
["bonelord"] = 1, ["bonelord_summon"] = 1, ["BM_draugr01"] = 1, ["draugr"] = 1, ["ancestor_ghost"] = 1, ["ancestor_ghost_greater"] = 1, ["dwarven ghost"] = 1,
["centurion_sphere"] = 1, ["centurion_sphere_summon"] = 1, ["centurion_projectile"] = 1,
["goblin_bruiser"] = 1, ["fabricant_verminous"] = 1, ["fabricant_summon"] = 1,
["kwama forager"] = 1, ["kwama forager blighted"] = 1, ["Rat"] = 1, ["rat_diseased"] = 1, ["rat_blighted"] = 1, ["nix-hound"] = 1, ["nix-hound blighted"] = 1, ["nix_mount"] = 1,
["dreugh"] = 1, ["dreugh_soldier"] = 1, ["dreugh_land"] = 1, ["slaughterfish"] = 1, ["Slaughterfish_Small"] = 1, ["slaughterfish_electro"] = 1,
["BM_wolf_grey"] = 1, ["BM_wolf_red"] = 1, ["BM_wolf_grey_lvl_1"] = 1, ["BM_wolf_snow_unique"] = 1, ["BM_wolf_grey_summon"] = 1, ["BM_wolf_skeleton"] = 1, ["BM_wolf_bone_summon"] = 1, ["BM_spriggan"] = 1}


L.SectorDod = function() for r, t in pairs(N) do local ang = mp:getViewToActor(t.m)		if t.m.inCombat and math.abs(ang) < 15 and math.abs(t.m:getViewToActor(mp)) < 45 then
	local ch = t.m.agility.current + t.m.sanctuary		if ch + (N[r].dod and 30 or 0) > math.random(100) then
		local spd = math.clamp((100 + ch + t.m.speed.current*2) * (1 - math.min(t.m.encumbrance.normalized,1)*0.8) * (0.5 + t.m.fatigue.normalized/2), 150, 400)
		t.m:doJump{velocity = (r.sceneNode.rotation:transpose().x * (ang > 0 and -1 or 1) + V.up2) * spd, applyFatigueCost = false}
		--tes3.messageBox("Dodge %s   %d%%   spd = %d   fov = %s   Ang = %d", r, ch, spd, t.m.isMovingForward, ang)
	end
end end end

L.DodM = function(r,m) if not L.ASN[m.actionData.animationAttackState] and not m.isFalling then
	local ch = m.agility.current + m.sanctuary		if ch + (N[r].dod and 30 or 0) > math.random(100) then
	local spd = math.min((200 + ch + m.speed.current*2) * (1 - math.min(m.encumbrance.normalized,1)*0.8) * (0.5 + m.fatigue.normalized/2), 500)			local rot = r.sceneNode.rotation:transpose()
	DOM[m] = {v = (rot.x * table.choice{1,-1} + rot.y):normalized() * spd, fr = 0.4}
	--tes3.messageBox("Dodge %s   %d%%   spd = %d", r, ch, spd)
end end end


local function CALCMOVESPEED(e) local m = e.mobile
	if DOM[m] then	local t = DOM[m]
		m.impulseVelocity = t.v		t.fr = t.fr - wc.deltaTime
		if t.fr < 0 then DOM[m] = nil end
	end
end		event.register("calcMoveSpeed", CALCMOVESPEED)


local function ATTACKSTART(e) local a = e.mobile		
	if a ~= mp and e.attackType ~= 4 then	local ar = e.reference
		if cf.pvp and not AF[ar].part then L.DodM(ar, a) end
	end
end		event.register("attackStart", ATTACKSTART)



local function CALCHITCHANCE(e)
	e.hitChance = e.hitChance + cf.hitr
end		event.register("calcHitChance", CALCHITCHANCE)


local function ATTACK(e) local a = e.mobile		if a ~= mp then		local ad = a.actionData		local dir = ad.physicalAttackType		local ar = e.reference	
	if dir == 4 then ad.attackSwing = math.lerp(0.75, 1, ad.attackSwing)	
	else ad.attackSwing = math.lerp(0.5, 1, ad.attackSwing)		if cf.pvp and not AF[ar].part then L.DodM(ar, a) end end
end end		event.register("attack", ATTACK)


local function ATTACKHIT(e) local a = e.mobile	local ad = a.actionData		local dir = ad.physicalAttackType
	if a ~= mp and dir ~= 4 and not ad.hitTarget and ad.target == mp then ad.hitTarget = mp end
end		event.register("attackHit", ATTACKHIT)



local function DAMAGE(e) if e.source == "attack" and not e.projectile then	local a = e.attacker	local t = e.mobile		local tad = t.actionData
local ar = e.attackerReference	local tr = e.reference	local ad = a.actionData
if tad.animationAttackState == 4 then
	local rw = a.readiedWeapon	local w = rw and rw.object		local wt = w and w.type or -1		
	local tw = t.readiedWeapon	local two = tw and tw.object	local twt = two and two.type or -1
	local WS	if a.actorType == 0 then WS = a.combat.current else WS = a:getSkillValue(WT[wt].s)	end
	if wt < 9 and w and tw and twt < 9 then		local sw = ad.attackSwing
		local Kbonus = a.attackBonus/5 + (a == mp and 0 or ar.object.level)
		local Kstam = math.min(math.lerp(0.5, 1, a.fatigue.normalized*1.1), 1)
		local PK1 = (w.weight*5 + WS + a.strength.current + a.agility.current + a:getSkillValue(0) + Kbonus*2) * (a == mp and sw or 0.3 + sw) * Kstam * (WT[wt].h1 and 1 or 1.25) 
		local PK2 = (two.weight*10 + t:getSkillValue(WT[twt].s) + t.strength.current + t.agility.current + t.attackBonus) * (WT[twt].h1 and 0.75 or 1)
		* tad.attackSwing * (t == mp and math.clamp(t.animationController.weaponSpeed - 0.5, 0.2, 1) or 1)
		local park = PK1 / PK2
		rw.variables.condition = math.max(rw.variables.condition - tad.physicalDamage / 20, 0)
		tw.variables.condition = math.max(tw.variables.condition - ad.physicalDamage / 20, 0)
	--	if not AF[tr] then AF[tr] = {} end
		if park > 0.8 then
			local min = (a == mp and 0.2) or (t == mp and 0.1) or 0.2
			local max = (a == mp and 1) or (t == mp and (1 - math.min(t.agility.current,100)/200)) or 1
			AF[tr].part = timer.start{duration = math.clamp(park - 1, min, max), callback = function() if AF[tr] then if park < 2 then
				if t == mp then if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
				else tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}		tad.animationAttackState = 0 end
			end AF[tr].part = nil end end}

			if t == mp then MB[1] = 0		tad.animationAttackState = 0	
			else tad.animationAttackState = 0	
				tes3.playAnimation{reference = tr, group = tes3.animationGroup[(t.actorType == 1 or t.object.biped) and table.choice{"hit2", "hit3", "hit4", "hit5"} or "hit1"], loopCount = 0}	DOM[t] = nil
			end

			if a == mp and cf.tim and not T.Tim.timeLeft then	local lasttime = wc.simulationTimeScalar	wc.simulationTimeScalar = wc.simulationTimeScalar/2
				T.Tim = timer.start{duration = 0.5, callback = function() wc.simulationTimeScalar = lasttime end}
			end
		else	tad.physicalDamage = tad.physicalDamage * (1 - park)
			--AF[tr].park = 1 - park		AF[tr].fiz = tad.physicalDamage	
		end
		local parcost = 10 * math.min(PK2/PK1, 1)		a.fatigue.current = math.max(a.fatigue.current - parcost, 0)
		
		if cf.m3 then tes3.messageBox("Par! %s (%s)    %.2f = %d/%d    fiz = %.2f/%.2f    spd = %.2f   Cost = %d", ar.baseObject.name, tad.animationAttackState, park, PK1, PK2, ad.physicalDamage, tad.physicalDamage,
		t.animationController.weaponSpeed, parcost) end
		if t ~= mp then for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end end
		local tab = L.PSO[WT[wt].pso][WT[twt].pso]		tes3.playSound{reference = (a==mp or t==mp) and p or ar, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2]))}
		
		if a == mp then mp:exerciseSkill(0, 1) end
		
		e.damage = 0	 return
	end
end
--if AF[ar] and AF[ar].park and AF[ar].fiz == ad.physicalDamage then e.damage = e.damage * AF[ar].park	AF[ar].park = nil end
end end		if cf.par then event.register("damage", DAMAGE) end


local function MOBILEACTIVATED(e)	local m = e.mobile 		if m then
	if m.firingMobile == mp then	
		if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.4, callback = function() end}  	L.SectorDod() end
	else	local actort = m.actorType 
		if actort and not m.isDead then local r = e.reference	AF[r] = {}		N[r] = {m = m, dod = actort == 1 or r.object.usesEquipment or L.CDOD[r.baseObject.id]} end
	end
end	end		event.register("mobileActivated", MOBILEACTIVATED)


local function MOBILEDEACTIVATED(e) local r = e.reference
	N[r] = nil
	if AF[r] then	if AF[r].part then AF[r].part:cancel() end	AF[r] = nil end
end		event.register("mobileDeactivated", MOBILEDEACTIVATED)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		AF[p] = {} end		event.register("loaded", loaded)


local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = ic.mouseState.buttons	
if cf.aspd then tes3.findGMST("fCombatDelayCreature").value = -0.4		tes3.findGMST("fCombatDelayNPC").value = -0.4 end
if cf.animsw then	--Величина свинга теперь соответствует анимации
	mwse.memory.writeBytes{address = 0x541530, bytes = { 0x8B, 0x15, 0xDC, 0x67, 0x7C, 0x00, 0xD9, 0x42, 0x2C, 0x8B, 0x41, 0x3C, 0xD8, 0x88, 0xDC, 0x04, 0x00, 0x00, 0x8B, 0x51, 0x38, 0x8D, 0x82, 0xCC, 0x00, 0x00, 0x00, 0xD8, 0x40, 0x08, 0xD9, 0x58, 0x08, 0xC7, 0x41, 0x10, 0x00, 0x00, 0x80, 0xBF, 0xC6, 0x40, 0x11, 0x03, 0xD9, 0x41, 0x2C, 0xD8, 0x1D, 0x68, 0x64, 0x74, 0x00, 0xDF, 0xE0, 0xF6, 0xC4, 0x40, 0x75, 0x0B, 0x8B, 0x41, 0x2C, 0x89 } }
	mwse.memory.writeBytes{address = 0x5414E0, bytes = { 0x8B, 0x46, 0x3C, 0xD8, 0x88, 0xDC, 0x04, 0x00, 0x00, 0x8B, 0x46, 0x38, 0xD8, 0x80, 0xD4, 0x00, 0x00, 0x00, 0xD9, 0x98, 0xD4, 0x00, 0x00, 0x00, 0xD9, 0x46, 0x20, 0xD8, 0x1D, 0x68, 0x64, 0x74, 0x00, 0xDF, 0xE0, 0xF6, 0xC4, 0x40, 0x75, 0x1F, 0x8B, 0x46, 0x3C, 0xD9, 0x40, 0x5C, 0x8B, 0x0D, 0xDC, 0x67, 0x7C, 0x00, 0xD8, 0x41, 0x2C, 0xD8, 0x5E, 0x20, 0xDF, 0xE0, 0xF6, 0xC4, 0x01, 0x75, 0x06, 0x8B, 0x56, 0x20, 0x89, 0x56, 0x10, 0x5E, 0x5B, 0xC2, 0x04, 0x00 } }
end
if cf.npcsw then	--Нпс теперь могут удерживать свинг
	mwse.memory.writeBytes{address = 0x54147A, bytes = { 0x8B, 0x90, 0x88, 0x03, 0, 0, 0x0A, 0x90, 0x28, 0x02, 0, 0, 0x85, 0xD2, 0x75, 0x04, 0x84, 0xDB, 0x75, 0x3D } }
	mwse.memory.writeBytes{address = 0x5414B4, bytes = { 0xD9, 0x46, 0x20, 0xD8, 0x66, 0x18, 0xDE, 0xF9, 0xEB, 0x03 } }
end
end		event.register("initialized", initialized)