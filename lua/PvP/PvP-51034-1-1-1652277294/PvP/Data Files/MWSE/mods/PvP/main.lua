
local cf = mwse.loadConfig("PvP", {pvp = true, pvp1 = true, par = true, aspd = true, tim = true, hitr = 0, sw1 = 50, sw2 = 70, m3 = false})
local p, mp, wc, ic, MB		local DOM = {}		local L = {}	local T = {Dom = timer, Tim = timer}		local N = {}	local A = {}
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


L.SectorDod = function()
	for r, tab in pairs(N) do if tab.m.inCombat then
		local ang = mp:getViewToActor(tab.m)
		if math.abs(ang) < 20 then
			L.DodM(r, tab.m, ang > 0 and -1 or 1)
		end
	end end
end


L.DodM = function(r,m,k)
if not L.ASN[m.actionData.animationAttackState] and not m.isFalling then
	local ch = m.agility.current + m.sanctuary		if ch + (N[r] and N[r].dod and 30 or 0) > math.random(100) then	local vec
	local spd = math.min((50 + ch/2 + m.speed.current) * (1 - math.min(m.encumbrance.normalized,1)/2) * (0.5 + m.fatigue.normalized/2), k and 200 or 250) / 15			local rot = r.sceneNode.rotation
	if k then		
		vec = rot:transpose().x * spd * k
	else	
		vec = (rot:transpose().x * table.choice{1,-1} + rot:transpose().y * 1.2):normalized() * spd
	end
	DOM[m] = {v = vec, fr = 15}	
end end end


local function CALCMOVESPEED(e) local m = e.mobile	
	if DOM[m] then	local t = DOM[m]
		m.impulseVelocity = t.v * (1/wc.deltaTime)		t.fr = t.fr - 1
		if t.fr <= 0 then DOM[m] = nil end
	end
end		event.register("calcMoveSpeed", CALCMOVESPEED)


local function CALCHITCHANCE(e) local a = e.attackerMobile	
	e.hitChance = e.hitChance + cf.hitr
	if a ~= mp then a.actionData.attackSwing = math.random(cf.sw1,100)/100 end
end		event.register("calcHitChance", CALCHITCHANCE)


local function ATTACK(e) local a = e.mobile		if a ~= mp then
	if a.actionData.attackDirection == 4 then a.actionData.attackSwing = math.random(cf.sw2,100)/100
	elseif cf.pvp then L.DodM(e.reference, a) end
end end		event.register("attack", ATTACK)


local function DAMAGE(e) if e.source == "attack" and not e.projectile then	local a = e.attacker	local t = e.mobile		local tad = t.actionData
local ar = e.attackerReference	local tr = e.reference	local ad = a.actionData
if tad.animationAttackState == 4 then
	local rw = a.readiedWeapon	local w = rw and rw.object		local wt = w and w.type or -1		
	local tw = t.readiedWeapon	local two = tw and tw.object	local twt = two and two.type or -1
	local WS	if a.actorType == 0 then WS = a.combat.current else WS = a:getSkillValue(WT[wt].s)	end
	if wt < 9 and w and tw and twt < 9 then
		local Kbonus = a.attackBonus/5 + (a == mp and 0 or ar.object.level)
		local Kstam = math.min(math.lerp(0.5, 1, a.fatigue.normalized*1.1), 1)
		local PK1 = (w.weight*5 + WS + a.strength.current + a.agility.current + a:getSkillValue(0) + Kbonus*2) * (a == mp and ad.attackSwing or math.random(80,120)/100) * Kstam * (WT[wt].h1 and 1 or 1.25) 
		local PK2 = (two.weight*10 + t:getSkillValue(WT[twt].s) + t.strength.current + t.agility.current + t.attackBonus) * (WT[twt].h1 and 0.75 or 1)
		* tad.attackSwing * (t == mp and math.clamp(t.animationController.weaponSpeed - 0.5, 0.2, 1) or 1)
		local park = PK1 / PK2
		rw.variables.condition = math.max(rw.variables.condition - tad.physicalDamage / 20, 0)
		tw.variables.condition = math.max(tw.variables.condition - ad.physicalDamage / 20, 0)
		if not A[tr] then A[tr] = {} end
		if park > 0.8 then
			tad.animationAttackState = 0
			if t == mp then MB[1] = 0 else tes3.playAnimation{reference = tr, group = tes3.animationGroup[(t.actorType == 1 or t.object.biped) and table.choice{"hit2", "hit3", "hit4", "hit5"} or "hit1"], loopCount = 0} end
			local min = (a == mp and 0.2) or (t == mp and 0.1) or 0.2
			local max = (a == mp and 1) or (t == mp and (1 - math.min(t.agility.current,100)/200)) or 1
			A[tr].part = timer.start{duration = math.clamp(park - 1, min, max), callback = function() if park < 2 then
				if t == mp then if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
				else tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}		tad.animationAttackState = 0 end
			end A[tr].part = nil end}

			if a == mp and cf.tim and not T.Tim.timeLeft then	local lasttime = wc.simulationTimeScalar	wc.simulationTimeScalar = wc.simulationTimeScalar/2
				T.Tim = timer.start{duration = 0.5, callback = function() wc.simulationTimeScalar = lasttime end}
			end
		else
			A[tr].park = 1 - park		A[tr].fiz = tad.physicalDamage	
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
if A[ar] and A[ar].park and A[ar].fiz == ad.physicalDamage then e.damage = e.damage * A[ar].park	A[ar].park = nil end
end end		if cf.par then event.register("damage", DAMAGE) end


local function MOBILEACTIVATED(e)	local m = e.mobile 		if m then
	if m.firingMobile == mp then	
		if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.2, callback = function() end}  	L.SectorDod() end
	else	local actort = m.actorType  	
		if actort and not m.isDead then local r = e.reference	N[r] = {m = m, dod = actort == 1 or r.object.usesEquipment or L.CDOD[r.baseObject.id]} end
	end
end	end		event.register("mobileActivated", MOBILEACTIVATED)


local function MOBILEDEACTIVATED(e) local r = e.reference
	N[r] = nil
	if A[r] then	if A[r].part then A[r].part:cancel() end	A[r] = nil end
end		event.register("mobileDeactivated", MOBILEDEACTIVATED)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer	end		event.register("loaded", loaded)


local function initialized(e)	wc = tes3.worldController		ic = wc.inputController		MB = ic.mouseState.buttons	
if cf.aspd then tes3.findGMST("fCombatDelayCreature").value = -0.4		tes3.findGMST("fCombatDelayNPC").value = -0.4 end
end		event.register("initialized", initialized)

local function registerModConfig()		local template = mwse.mcm.createTemplate("PvP")	template:saveOnClose("PvP", cf)	template:register()		local p0 = template:createPage()	local var = mwse.mcm.createTableVariable
p0:createYesNoButton{label = "Enable PvP-mode (NPCs move better in combat)", variable = var{id = "pvp", table = cf}}
p0:createYesNoButton{label = "NPCs will try to dodge your projectiles", variable = var{id = "pvp1", table = cf}}
p0:createYesNoButton{label = "Enable parrying combat", variable = var{id = "par", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "Increase attack frequency of enemies", variable = var{id = "aspd", table = cf}, restartRequired = true}
p0:createSlider{label = "The minimum percentage of enemy attack power in melee", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "sw1", table = cf}}
p0:createSlider{label = "The minimum percentage of enemy attack power in ranged combat", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "sw2", table = cf}}
p0:createSlider{label = "Increase global hit chance (percentage)", min = 0, max = 200, step = 10, jump = 50, variable = var{id = "hitr", table = cf}}
p0:createYesNoButton{label = "Enable slow time on successful parry", variable = var{id = "tim", table = cf}}
p0:createYesNoButton{label = "Show parry messages", variable = var{id = "m3", table = cf}}
end		event.register("modConfigReady", registerModConfig)