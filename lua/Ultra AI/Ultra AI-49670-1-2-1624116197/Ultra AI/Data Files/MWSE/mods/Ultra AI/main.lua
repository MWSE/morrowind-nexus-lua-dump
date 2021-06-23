
local cf = mwse.loadConfig("Ultra AI", {atak = true, stels = true, vis = 200, m4 = false, m11 = false, gmst = 70, AIsec = 2, stdmg = 5})
local p, mp, pp		local R = {}	local T = timer		local B = {}
local L = {MAC = {["atronach_flame"] = {"Fire_ball","Fire_bolt"}, ["atronach_flame_summon"] = {"Fire_ball","Fire_bolt"},
["atronach_frost"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_summon"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_BM"] = {"Frost_ball","Frost_bolt"},
["atronach_storm"] = {"Shock_ball","Shock_bolt"}, ["atronach_storm_summon"] = {"Shock_ball","Shock_bolt"},
["dremora"] = {"Fire_arrow","Fire_ball"}, ["dremora_summon"] = {"Fire_arrow","Fire_ball"}, ["dremora_lord"] = {"Fire_ball","Fire_bolt"},
["golden saint"] = {"Fire_bolt","Frost_bolt","Shock_bolt"}, ["golden saint_summon"] = {"Fire_bolt","Frost_bolt","Shock_bolt"},
["4nm_mazken"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"}, ["4nm_mazken_s"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"},
["hunger"] = {"Chaos_arrow","Chaos_ball"}, ["hunger_summon"] = {"Chaos_arrow","Chaos_ball"},
["scamp"] = {"Fire_arrow"}, ["scamp_summon"] = {"Fire_arrow"}, ["daedroth"] = {"Poison_arrow","Poison_ball"}, ["daedroth_summon"] = {"Poison_arrow","Poison_ball"},
["winged twilight"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"}, ["winged twilight_summon"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"},
["4nm_dremora_mage"] = {"Fire_ball","Frost_ball","Shock_ball","Fire_bolt","Frost_bolt","Shock_bolt"}, ["4nm_dremora_mage_s"] = {"Fire_ball","Frost_ball","Shock_ball","Fire_bolt","Frost_bolt","Shock_bolt"},
["4nm_daedraspider"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"}, ["4nm_daedraspider_s"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"},
["4nm_xivilai"] = {"Fire_ball","Chaos_ball"}, ["4nm_xivilai_s"] = {"Fire_ball","Chaos_ball"},
["4nm_xivkyn"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"}, ["4nm_xivkyn_s"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"},

["ancestor_ghost"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_summon"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_greater"] = {"Chaos_arrow","Chaos_ball","Frost_arrow","Frost_ball"},
["Bonewalker_Greater"] = {"Chaos_arrow"}, ["Bonewalker_Greater_summ"] = {"Chaos_arrow"},
["bonelord"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"}, ["bonelord_summon"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"},
["4nm_skeleton_mage"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball"},
["4nm_skeleton_mage_s"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball"},
["lich"] = {"Frost_ball","Poison_ball","Chaos_ball","Frost_bolt","Poison_bolt","Chaos_bolt"},
["4nm_lich_elder"] = {"Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"}, ["4nm_lich_elder_s"] = {"Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"},

["ash_slave"] = {"Fire_arrow","Frost_arrow","Shock_arrow"}, ["ash_ghoul"] = {"Chaos_ball","Chaos_bolt"}, ["ascended_sleeper"] = {"Fire_bolt","Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"},
["kwama warrior"] = {"Poison_arrow","Poison_ball"}, ["kwama warrior blighted"] = {"Poison_arrow","Poison_ball"},
["netch_bull"] = {"Poison_arrow","Poison_ball"}, ["netch_betty"] = {"Shock_arrow","Shock_ball"},
["goblin_handler"] = {"Fire_arrow"}, ["goblin_officer"] = {"Fire_arrow","Fire_ball"},
["BM_spriggan"] = {"Frost_ball","Poison_ball"}, ["BM_ice_troll"] = {"Frost_arrow","Frost_ball"}},
BU = {
{n="Fire_arrow",{2,14,5,10,1,1}}, {n="Fire_ball",{2,14,10,20,5,1}}, {n="Fire_bolt",{2,14,20,30,10,1}},
{n="Frost_arrow",{2,16,5,10,1,1}}, {n="Frost_ball",{2,16,10,20,5,1}}, {n="Frost_bolt",{2,16,20,30,10,1}},
{n="Shock_arrow",{2,15,5,10,1,1}}, {n="Shock_ball",{2,15,10,20,5,1}}, {n="Shock_bolt",{2,15,20,30,10,1}},
{n="Poison_arrow",{2,27,1,2,1,5}},  {n="Poison_ball",{2,27,2,4,5,5}},   {n="Poison_bolt",{2,27,4,6,10,5}},
{n="Chaos_arrow",{2,23,5,10,1,1}}, {n="Chaos_ball",{2,23,10,20,5,1}}, {n="Chaos_bolt",{2,23,20,30,10,1}}}}


-- бехевиор: -1 = стоит столбом и ничего не делает хотя и в бою. 5 = убегает и не видит игрока, 6 = убегает; 3 = атака; 2 - идл (но бывает и при атаке); 0 = хеллоу; 8 = бродит
local function COMBATSTARTED(e) local m = e.actor	local ref = m.reference		if e.target == mp and not R[ref] and m.combatSession then 	local ob = m.object
R[ref] = {m = m, a = m.actionData, ob = ob, c = 0, at = (m.actorType == 1 or ob.biped) and 1 or (not ob.usesEquipment and 3), lim = math.max(70 + ob.level*5, 100), rc = L.MAC[ob.baseObject.id]}
timer.delayOneFrame(function() if R[ref] then R[ref].cm = true end end)
if cf.m4 then tes3.messageBox("%s joined the battle! Enemies = %s", ob.name, table.size(R)) end
if not T.timeLeft then	T = timer.start{duration = 1, iterations = -1, callback = function() local s, w, beh, HD, status
	for r, t in pairs(R) do s = t.m.combatSession	beh = t.a.aiBehaviorState	w = t.m.readiedWeapon	HD = nil
		if s and s.selectedAction == 7 or (beh == 6 or beh == 5) then			--(not s or s.selectedAction == 0)
			if t.m.health.normalized > 0.1 and t.m.flee < t.lim then	HD = math.abs(pp.z - r.position.z) > 128 * (w and w.object.reach or 0.7)
				if HD then
					if t.at == 1 then t.c = t.c + 1
						if not w or w.object.type < 9 then
							if t.c > cf.AIsec then
								status = "STONE!"	if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(2,3)} end
							--	if mp.levitate > 0 then mwscript.equip{reference = r, item = L.stone} r:updateEquipment() end	--t.m:equip{item = L.stone}		--mwscript.equip{reference = r, item = L.stone}
								mwscript.equip{reference = r, item = L.stone}	 r:updateEquipment()
							else status = "NO STONE" end
						else status = "RANGE!" end
						if s then s.selectedAction = 2 end
						t.a.aiBehaviorState = 3
					else status = "NO RUN MONSTR"	if s then s.selectedAction = 5 end
						t.a.aiBehaviorState = 3 end
				else status = "NO RUN!"		if s then s.selectedAction = t.at or 1 end		
					t.a.aiBehaviorState = 3
				end
				if t.rc and t.m.isPlayerDetected and tes3.testLineOfSight{reference1 = r, reference2 = p} then tes3.applyMagicSource{reference = r, source = B[table.choice(t.rc)]} end
			else status = "FLEE!" end
		elseif not t.m.inCombat then
			if t.m.fight > 30 then	HD = math.abs(pp.z - r.position.z) > 128 * (w and w.object.reach or 0.7)
				if HD then
					if t.at == 1 then
						if not w or w.object.type < 9 then status = "EXTRA-STONE!"
							if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(1,2)} end
							mwscript.equip{reference = r, item = L.stone} r:updateEquipment()
						else status = "EXTRA-RANGE!" end
						t.m:startCombat(mp)		t.a.aiBehaviorState = 3
					else status = "NO COMBAT MONSTR!" end
				else status = "EXTRA NO LEAVE!"		t.m:startCombat(mp)		t.a.aiBehaviorState = 3 end
			else status = "CALM! - LEAVE COMBAT"	R[r] = nil end
		elseif beh == -1 then	status = "EXTRA COMBAT!"	t.m:startCombat(mp)		t.a.aiBehaviorState = 3
		else status = ""	if not w or w.object.type < 9 then t.c = t.c > cf.AIsec and cf.AIsec or 0 end end
		if cf.m4 then tes3.messageBox("%s (%d)  %s  %d fl (%d) / %d fg   HD = %s  Beh = %s/%s  SA = %s   Pdet %s", status, t.c, t.ob.name, t.m.flee, t.lim, t.m.fight, HD, beh,
		t.a.aiBehaviorState, s and s.selectedAction, t.a.target == mp and t.m.isPlayerDetected) end
	end
	if table.size(R) == 0 then T:cancel()	if cf.m4 then tes3.messageBox("The battle is over!") end end
end} end
end end		event.register("combatStarted", COMBATSTARTED)


-- не решил = 0, Атака (1 мили, 2 рейндж, 3 кричер или рукопашка), AlchemyOrSummon = 6, бегство = 7, Спелл (касание 4, цель 5, на себя 8), UseEnchantedItem = 10		s:changeEquipment()
local function onDeterminedAction(e) local s = e.session
--tes3.messageBox("DED  %s  SA = %s  Beh = %s  fl = %d  fg = %d  Prior = %s", s.mobile.reference, s.selectedAction,  s.mobile.actionData.aiBehaviorState, s.mobile.flee, s.mobile.fight, s.selectionPriority)
if s.selectedAction == 7 then	local m = s.mobile 	local t = R[m.reference]
	if t and m.health.normalized > 0.1 and m.flee < t.lim then s.selectedAction = t.at or 1		t.a.aiBehaviorState = 3
		if cf.m4 then tes3.messageBox("UPD NO FLEE!  %s", t.ob.name) end
	end
end end		event.register("determinedAction", onDeterminedAction)


local function combatStop(e) local m = e.actor	local r = m.reference	if R[r] then local t = R[r]		local status	--событие не триггерится от контроля и успокоения
if m.fight > 30 then
	if t.at == 1 then
		if math.abs(pp.z - r.position.z) > 128 * (t.m.readiedWeapon and t.m.readiedWeapon.object.reach or 0.7) then
			if not m.readiedWeapon or m.readiedWeapon.object.type < 9 then
				if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(1,2)} end
				mwscript.equip{reference = r, item = L.stone} r:updateEquipment()
				status = "NO LEAVE + STONE"
			else status = "NO LEAVE + RANGE" end
			t.a.aiBehaviorState = 3
			if cf.m4 then tes3.messageBox("%s  %s  fg = %s   Beh = %s  SA = %s  Tar = %s", status, r, m.fight, t.a.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, t.a.target and t.a.target.object.name) end
			return false
		else status = "LEAVE NPC" end
		if cf.m4 then tes3.messageBox("%s  %s  fg = %s   Beh = %s  SA = %s  Tar = %s", status, r, m.fight, t.a.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, t.a.target and t.a.target.object.name) end
	else	status = "LEAVE MONSTR"
		if cf.m4 then tes3.messageBox("%s  %s  fg = %s   Beh = %s  SA = %s  Tar = %s", status, r, m.fight, t.a.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, t.a.target and t.a.target.object.name) end
	end
else status = "CALM"
	if cf.m4 then tes3.messageBox("%s  %s  fg = %s   Beh = %s  SA = %s  Tar = %s", status, r, m.fight, t.a.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, t.a.target and t.a.target.object.name) end
	R[r] = nil
end
end end		event.register("combatStop", combatStop)

local function DETECTSNEAK(e) if e.target == mp then	local m = e.detector	local r = m.reference		local com = R[r] and R[r].cm		if com or cf.stels then		local snek = mp.isSneaking
local KP = com and 0 or (mp:getSkillValue(19) + mp.agility.current/2 + mp.luck.current/4 + mp:getSkillValue(18)/4) * (snek and 0.5 or 0) * math.min(mp.fatigue.normalized,1)
local KD = com and 0 or (m:getSkillValue(18) + m.agility.current/4 + m.luck.current/4)
local Koef = com and 1 or math.max((100 + KD - KP)/100, 0.5)
local DistKF = math.max(1.5 - r.position:distance(pp)/2000, 0.5)
local VPow = com and cf.vis or math.max(cf.vis - math.abs(m:getViewToActor(mp)), 0)
local Vis = math.max(VPow * Koef * DistKF - (mp.invisibility > 0 and 200 - m:getSkillValue(14)/2 or 0) - mp.chameleon - m.blind, 0)
local Aud = math.max((5 + mp.encumbrance.current/5 + mp:getBootsWeight()) * (snek and 1 or 3) * Koef * DistKF - mp.chameleon/2 - m.sound, 0)
local chance = Vis + Aud		local detected = chance > math.random(100)		e.isDetected = detected		m.isPlayerDetected = detected		m.isPlayerHidden = not detected
if cf.m11 then tes3.messageBox("Det %s %d%%  Vis = %d%% (%d)  Aud = %d%%  DistKF = %.2f  Koef = %.2f (%d - %d)  %s", detected, chance, Vis, VPow, Aud, DistKF, Koef, KD, KP, r) end
end end	end		event.register("detectSneak", DETECTSNEAK)


local function MOBILEDEACTIVATED(e)	if R[e.reference] then R[e.reference] = nil end end		event.register("mobileDeactivated", MOBILEDEACTIVATED)

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		pp = p.position		R = {}
	tes3.findGMST("fAIRangeMeleeWeaponMult").value = cf.gmst
end		event.register("loaded", loaded)


local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Ultra AI")	tpl:saveOnClose("Ultra AI", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createYesNoButton{label = "More frequent enemy attacks", variable = var{id = "atak", table = cf}, restartRequired = true}
p0:createYesNoButton{label = "Enable advanced stealth module", variable = var{id = "stels", table = cf}}
p0:createSlider{label = "Stealth difficulty", min = 100, max = 400, step = 10, jump = 50, variable = var{id = "vis", table = cf}}
p0:createSlider{label = "How many seconds does it take for enemies to switch to throwing stones", min = 0, max = 10, step = 1, jump = 1, variable = var{id = "AIsec", table = cf}}
p0:createSlider{label = "Stone damage", min = 1, max = 10, step = 1, jump = 1, variable = var{id = "stdmg", table = cf}, restartRequired = true}
p0:createSlider{label = "Range weapon priority, save load required (5 in vanilla, 70 by default)", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "gmst", table = cf}}
p0:createYesNoButton{label = "Show messages", variable = var{id = "m4", table = cf}}
p0:createYesNoButton{label = "Show stealth messages", variable = var{id = "m11", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e) local o
L.stone = tes3.getObject("4nm_stone") or tes3.createObject{objectType = tes3.objectType.weapon, id = "4nm_stone", name = "Stone", type = 11, mesh = "w\\stone.nif", icon = "w\\stone.tga",
weight = 1, value = 0, maxCondition = 100, enchantCapacity = 0, reach = 1, speed = 1, chopMin = 0, chopMax = 5, slashMin = 0, slashMax = 5, thrustMin = 0, thrustMax = 5}
L.stone.chopMax = cf.stdmg

for _, t in ipairs(L.BU) do o = tes3alchemy.create{id = "4_"..t.n, name = "4_"..t.n, icon = "s\\b_tx_s_sun_dmg.dds"}	o.sourceless = true
for i, ef in ipairs(t) do o.effects[i].rangeType = ef[1]	o.effects[i].id = ef[2]		o.effects[i].min = ef[3]	o.effects[i].max = ef[4]	o.effects[i].radius = ef[5]		o.effects[i].duration = ef[6] end	B[t.n] = o end

tes3.findGMST("fAIFleeFleeMult").value = 0		tes3.findGMST("fAIFleeHealthMult").value = 88.888		tes3.findGMST("fFleeDistance").value = 5000
tes3.findGMST("iAutoSpellTimesCanCast").value = 5		tes3.findGMST("iAutoSpellConjurationMax").value = 3		tes3.findGMST("iAutoSpellDestructionMax").value = 15	tes3.findGMST("fMagicCreatureCastDelay").value = 0
if cf.atak then tes3.findGMST("fCombatDelayCreature").value = -0.4		tes3.findGMST("fCombatDelayNPC").value = -0.4	end
end		event.register("initialized", initialized)