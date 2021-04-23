local cfg = mwse.loadConfig("4NM_COMBAT_5!") or {msg = false, msg2 = false, crit = 30, dodgelim = 50, Spd = true, AImod = true, Proj = false, maniac = false, autoshield = true, sbar = true, save = true}
local p, mp, D, msg, msg2, com, last, pred, Mbar		local COMT = timer		local ShTim = timer		local A = {}
local WT = {[0] = 22, [1] = 5, [2] = 5, [3] = 4, [4] = 4, [5] = 4, [6] = 7, [7] = 6, [8] = 6, [9] = 23, [10] = 23, [11] = 23}	local OneH = {[0] = true, [1] = true, [3] = true, [7] = true, [11] = true}
local arm, CST	local AS = {[0] = 21, [1] = 2, [2] = 3}		local Ttype = {"strength", "endurance", "agility", "speed", "intelligence"}
local function Cpower(m, s1, s2) return 100 + m.willpower.current/5 + m:getSkillValue(s1)/5 + m:getSkillValue(s2)/10 + (m.spellReadied and m.magicka.current/(25 + m.magicka.current/40) or 0) - 50*(1 - math.min(m.fatigue.normalized,1)) end
local function Kcost(x,k,m,s1,s2) return x - x/k * math.min((m:getSkillValue(s1) + m:getSkillValue(s2)),200)/200 end

local function onCalcMoveSpeed(e) e.speed = e.speed * (0.5 + math.min(e.mobile.fatigue.normalized,1)/2) * (e.reference == p and mp.isMovingBack and (0.5 + math.min(mp.agility.current,100)/500) or 1) end
local function onAttack(e) if e.reference ~= p and e.mobile.actionData.attackDirection == 4 then e.mobile.actionData.attackSwing = math.random(70,100)/100 end end
local function onCalcArmorRating(e) if e.mobile then e.armorRating = e.armor.armorRating * (1 + e.mobile:getSkillValue(AS[e.armor.weightClass])/100)	e.block = true end end -- return false
local function onCalcArmorPieceHit(e) local st = tes3.getEquippedItem{actor = e.reference, objectType = tes3.objectType.armor, slot = e.slot or e.fallback}	arm = st and st.object:calculateArmorRating(e.mobile) or 0 end
local function onBlock(e)
	if ShTim.timeLeft then ShTim:reset() else ShTim = timer.start{duration = 10, callback = function() Mbar.visible = false end} end
	Mbar.widget.max = mp.readiedShield.object.maxCondition	Mbar.widget.current = mp.readiedShield.variables.condition	Mbar.visible = true
	if CST then CST:reset() else CST = timer.start{duration = 0.4 + (mp.agility.current + mp.block.current)/1000, callback = function() CST = nil end} end
end


local function onHit(e)		local a = e.attackerMobile	local t = e.targetMobile	local ad = a.actionData		local chance = 100 + a.agility.current/2 - a.blind - t.chameleon/2 - t.invisibility * 100
if t == mp then
	if (t.isMovingLeft or t.isMovingRight) and not t.isMovingForward then		local act = math.min(math.min(t.fatigue.normalized,1) * (t.agility.current*0.3 + t.luck.current*0.2) + t.sanctuary/2, 100)
		if 100*t.fatigue.normalized > cfg.dodgelim and t.encumbrance.normalized < 0.5 and (chance - act) < 100 then
			local stamcost = math.max(100*(1 + t.encumbrance.normalized) - (t.agility.current + t.endurance.current)/5, 50)		local extrachance = math.min(t.agility.current,100)/2
			e.hitChance = chance - act - extrachance		if e.hitChance < 0 then stamcost = math.max(stamcost*(100 + e.hitChance)/100, 20) end
			t.fatigue.current = t.fatigue.current - stamcost
			if msg then tes3.messageBox("Dodge try! Hitchance = %.1f (%.1f - %.1f active - %.1f extra) Stamina cost = %d", e.hitChance, chance, act, extrachance, stamcost) end
		else e.hitChance = chance - act		if msg then tes3.messageBox("Hitchance = %.1f (%.1f - %.1f active)", e.hitChance, chance, act) end end
	else e.hitChance = chance end	
else e.hitChance = chance - t.sanctuary/2 end
if a.actorType == 1 then	if a.readiedWeapon then ad.attackSwing = math.random(50,100)/100 else ad.attackSwing = math.random(100,200)/100 * 50/math.min(a:getSkillValue(26),50) end -- ? ??? ??????? 50% ??????, ? ?????????? 100-200%
elseif a.actorType == 0 then ad.attackSwing = math.random(50,100)/100 end -- tes3.messageBox("Swing = %.2f", ad.attackSwing)
end


local function onDamage(e) if e.source == "attack" then		local a = e.attacker	local t = e.mobile	local ar = e.attackerReference	local tr = e.reference
local StartD = e.damage		local Kperk = 0		local WS	local W = a.readiedWeapon	local wt = W and W.object.type or -1		local Kcond = 0
if t.actorType == 0 then arm = t.shield end
if a.actorType == 0 then WS = a.combat.current	if not W then Kperk = a.strength.current/2 + (1 - a.health.normalized) * WS/2 end else WS = W and a:getSkillValue(WT[wt]) or 0 end
local as = (a.isMovingForward and wt < 9 and 1) or (a.isMovingLeft or a.isMovingRight and 2) or (a.isMovingBack and wt < 9 and 3) or 0
local ts = (t.isMovingForward and 1) or (t.isMovingLeft or t.isMovingRight and 2) or (t.isMovingBack and 3) or 0
local hs = WS/5 + a.strength.current/10 + a.agility.current/10 - t.endurance.current/5 - t.agility.current/5 + (as == 1 and 20 or 0)
local Kskill = WS/5		local Kstam = (1 - math.min(a.fatigue.normalized,1))*50		local Kbonus = a.attackBonus/5 + (ar == p and 0 or ar.object.level)
local CritC = Kbonus + WS/10 + (a.agility.current + a.luck.current)/20 + (as == 1 and 10 or 0) + (ts == 1 and 10 or 0) + (ar == p and math.min(com,4)*5 or 20) + (a.isJumping and ((a:getSkillValue(20) + a.agility.current)/10) or 0) -
(t.endurance.current + t.agility.current + t.luck.current)/20 - arm/10 - t.sanctuary/10 - math.min(t.fatigue.normalized,1)*20

if W then
	if wt > 8 then
		if wt == 9 then Kperk = ar.position:distance(tr.position) * WS/20000 -- ???? 5% ?? ?????? 1000 ?????????
		elseif wt == 10 then Kperk = arm * WS * 0.003		hs = hs + WS/2
		elseif wt == 11 then
			if A[ar] == nil then A[ar] = {met = -1} end	if (A[ar].met or -1) < 10 then A[ar].met = (A[ar].met or -1) + 1 end
			if A[ar].mettim then A[ar].mettim:reset() else A[ar].mettim = timer.start{duration = (1 + WS/200), callback = function() A[ar].met = -1	A[ar].mettim = nil end} end
			Kperk = A[ar].met * WS/20
		end
	else
		if ar == p then	local dir = mp.actionData.attackDirection	if COMT.timeLeft then
			if dir == last then com = math.max(com - 2, 0) elseif dir == pred and com > 2 then com = com - 1 elseif dir ~= pred then com = math.min(com + 1, 3 + math.floor(WS/50)) end	COMT:reset()	pred = last		last = dir
		else	last = dir	COMT = timer.start{duration = 2, callback = function() com = 0	last = nil	pred = nil end} end end
		if wt > 6 then
			if A[ar] == nil then A[ar] = {axe = -1} end	if (A[ar].axe or -1) < 10 then A[ar].axe = (A[ar].axe or -1) + 1 end		
			if A[ar].axetim == nil then A[ar].axetim = timer.start{duration = (1.5 + WS/200), iterations = -1, callback = function()
				A[ar].axe = A[ar].axe - 1		if A[ar].axe < 0 then A[ar].axetim:cancel()	A[ar].axetim = nil end
			end} end
			Kperk = A[ar].axe * WS/20
		elseif wt == 6 then Kperk = (1 - math.min(t.fatigue.normalized,1)) * WS/2
		elseif wt == 5 then Kperk = a.magicka.normalized * WS * 0.3
		elseif wt > 2 then Kperk = arm * WS * 0.003		hs = hs + WS/2
		elseif wt > 0 then
			if A[ar] == nil then A[ar] = {long = 0} end
			if A[ar].longtim then A[ar].longtim:reset()
			else A[ar].longtim = timer.start{duration = (1 + WS/500), callback = function() A[ar].long = 0	A[ar].longtim = nil end} end
			if (A[ar].long or 0) < 2 then A[ar].long = (A[ar].long or 0) + 1 else Kperk = WS	A[ar].long = 0		hs = hs + WS/2	if msg then tes3.messageBox("3 strike!") end end
		elseif wt == 0 then Kperk = (1 - t.health.normalized) * WS * 0.3	CritC = CritC + WS/5 end
	end
	if wt ~= 11 then Kcond = (1 - math.min(W.variables.condition/W.object.maxCondition,1)) * math.min(a:getSkillValue(1),100)/2 end
end
if ar == p and CST then Kperk = Kperk + mp:getSkillValue(0)/2	hs = hs + 50	if msg then tes3.messageBox("Counterstrike!") end end
local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 50		if Kcrit > cfg.crit then tes3.playSound{reference = tr, sound = "critical damage"} end end

local defbonus = ts == 3 and math.min((t.agility.current + t.endurance.current + t.sanctuary)/10, 30) or 0			local defdebuff = as == 3 and math.max(50 - (WS + a.agility.current)/10, 0) or 0
local armdef	if not t.readiedShield then	if not t.readiedWeapon then if t.actorType ~= 0 then armdef = t:getSkillValue(26)/10 + t.agility.current/20 end
elseif OneH[t.readiedWeapon.object.type] then armdef = t:getSkillValue(26)/20 + t.agility.current/20 end end
local Kdef = math.min(defdebuff + defbonus + (armdef or 0), 50)

e.damage = e.damage * (100 - Kstam + Kskill + Kbonus + Kperk + Kcrit - Kdef + Kcond)/100		hs = hs + (ar == p and 200*e.damage/t.health.base + math.min(com,4)*10 or 5*e.damage) + Kcrit/2
if msg then tes3.messageBox("%.1f = %.1f > %.1f - %.1f%% stam + %.1f%% skill + %.1f%% ab + %.1f%% perk + %.1f%% crit (%.1f%%) + %.1f%% cond - %.1f%% def  Armor = %.1f  Hitstun = %d%% (%s)",
e.damage, a.actionData.physicalDamage, StartD, Kstam, Kskill, Kbonus, Kperk, Kcrit, CritC, Kcond, Kdef, arm, hs, ar==p and com or "") end

local KSM = tes3.getEffectMagnitude{reference = tr, effect = 508}	-- ???????????? ???
if KSM > 0 and t.magicka.current > 1 then	KSM = KSM * Cpower(t,11,14)/100		local Dred = e.damage < KSM and e.damage or KSM		local KScost = Kcost(Dred*1.5,3,t,11,14)
	if t.magicka.current < KScost then Dred = Dred * t.magicka.current / KScost		KScost = t.magicka.current end
	e.damage = e.damage - Dred		tes3.modStatistic{reference = tr, name = "magicka", current = - KScost}		tes3.playSound{reference = tr, sound = "Spell Failure Destruction"}
	if msg then tes3.messageBox("Shield! %.1f damage  %.1f reduction  %.1f mag  Cost = %.1f", e.damage, Dred, KSM, KScost) end
end

if a.health.normalized < 1 and a.magicka.current > 1 then local LLM = tes3.getEffectMagnitude{reference = ar, effect = 509}	if LLM > 0 then -- ?????
	LLM = LLM * Cpower(a,14,15)/100		local LLhp = math.min(LLM/100 * e.damage, a.health.base - a.health.current)		local LLcost = Kcost(LLhp,2,a,11,14)
	if a.magicka.current < LLcost then LLhp = LLhp * a.magicka.current / LLcost		LLcost = a.magicka.current end
	tes3.modStatistic{reference = ar, name = "health", current = LLhp}		tes3.modStatistic{reference = ar, name = "magicka", current = - LLcost}
	if msg then tes3.messageBox("Life leech for %.1f hp (%.1f damage)  %.1f mag  Cost = %.1f", LLhp, e.damage, LLM, LLcost) end
end end

if ts == 3 then t.fatigue.current = t.fatigue.current - e.damage*2	elseif t == mp then t.fatigue.current = t.fatigue.current - e.damage end
if e.damage/t.health.base > 0.1 then	local trauma = math.random(5) + Kcrit/10 + 50*e.damage/t.health.base - (t.endurance.current + t.luck.current + t.sanctuary)/20
	if trauma > 0 then tes3.modStatistic{reference = tr, name = Ttype[math.random(5)], current = - trauma}	if msg then tes3.messageBox("%.1f traumatic damage done!", trauma) end end
end

if hs < math.random(100) and t.actionData.animationAttackState ~= 1 then timer.delayOneFrame(function() if t == mp and wt < 9 then
	if t.actionData.animationAttackState == 1 and t.actionData.currentAnimationGroup ~= 34 and t.actionData.currentAnimationGroup ~= 35 then t.actionData.animationAttackState = 0 end
else timer.delayOneFrame(function() if t.actionData.animationAttackState == 1 and t.actionData.currentAnimationGroup ~= 34 and t.actionData.currentAnimationGroup ~= 35 then t.actionData.animationAttackState = 0 end end) end end) end
end end


local R = {}	local CT, CM, sinus, tik5, status, Sbar		-- ????????: -1 = ????? ??????? ? ?????? ?? ?????? ???? ? ? ???. 6 = ???????; 3 = ?????; 2 - ??? (?? ?????? ? ??? ?????); 0 = ??????; 8 = ??????
local function inv(x) tes3.findGMST("fSneakViewMult").value = x and 20 or 2		tes3.findGMST("fSneakNoViewMult").value = x and 20 or 1		CM = x and true or nil end
local function onCombatStarted(e) if e.target == tes3.mobilePlayer and R[e.actor.reference] == nil and e.actor.combatSession then R[e.actor.reference] = {m = e.actor, fl = e.actor.flee, s = e.actor.combatSession, a = e.actor.actionData}
if msg2 then tes3.messageBox("%s joined the battle! Enemies = %s", e.actor.object.name, table.size(R)) end
if CT == nil then inv(1)	CT = timer.start{duration = 1, iterations = -1, callback = function() tik5 = math.floor(CT.timing)%5 == 0
	if CM then if mp.invisibility > 0 then inv() if msg2 then tes3.messageBox("invis mode") end end elseif mp.invisibility == 0 then inv(1) if msg2 then tes3.messageBox("normal mode") end end
	if cfg.sbar then local ht = mp.actionData.hitTarget	if ht and not ht.isDead then Sbar.visible = true	Sbar.widget.normalized = ht.fatigue.normalized else Sbar.visible = false end end
	
	for r, t in pairs(R) do		--if not t.s then t.s = t.m.combatSession end
		if t.s.selectedAction == 7 or ((tik5 or t.s.selectedAction > 100 or t.s.selectedAction == 0) and (t.a.aiBehaviorState == 6 or t.a.aiBehaviorState == 5)) then
			if t.m.health.normalized > 0.2 and t.m.flee < 70 then	sinus = math.abs(p.position.z - r.position.z) / p.position:distance(r.position)
				if t.m.flee ~= 0 then t.m.flee = 0 end
				if (t.m.actorType == 1 or r.object.biped) and (sinus > 0.45 or mp.levitate > 0) and (t.m.readiedWeapon == nil or t.m.readiedWeapon.object.type < 9) and mwscript.getItemCount{reference = r, item = "4nm_stone"} == 0 then 
					tes3.addItem{reference = r, item = "4nm_stone", count = math.random(2,4)}		r:updateEquipment()
					if mp.levitate > 0 then mwscript.equip{reference = r, item = "4nm_stone"}	status = "FLY!" else status = "STONE!" end
				else status = "NO RUN!" end
				if msg2 then tes3.messageBox("%s  %s (%d, %.2f)  State = %s->3 / %s", status, r.object.name, t.m.fight, sinus, t.a.aiBehaviorState, t.s.selectedAction) end		t.a.aiBehaviorState = 3
			else if t.m.flee < t.fl then t.m.flee = t.fl end	if msg2 then tes3.messageBox("FLEE! %s (%d/%d) State = %s / %s", r.object.name, t.m.flee, t.m.fight, t.a.aiBehaviorState, t.s.selectedAction) end end
		elseif t.m.inCombat == false then
			if t.m.fight > 30 then
				if (t.m.actorType == 1 and tes3.isAffectedBy{reference = r, effect = 119}) or (t.m.actorType == 0 and tes3.isAffectedBy{reference = r, effect = 118}) then
					if msg2 then tes3.messageBox("CONTROL! %s (%d/%d)", r.object.name, t.m.flee, t.m.fight) end	R[r] = nil
				else if msg2 then tes3.messageBox("NO LEAVE! %s (%d/%d)  State = %s->3 / %s", r.object.name, t.m.flee, t.m.fight, t.a.aiBehaviorState, t.s.selectedAction) end	t.m:startCombat(tes3.mobilePlayer)		t.a.aiBehaviorState = 3 end
			else if msg2 then tes3.messageBox("LEAVE COMBAT! %s (%d/%d)", r.object.name, t.m.flee, t.m.fight) end	R[r] = nil end
		elseif t.a.aiBehaviorState == -1 then if msg2 then tes3.messageBox("EXTRA COMBAT! %s (%d/%d)  State = %s->3 / %s", r.object.name, t.m.flee, t.m.fight, t.a.aiBehaviorState, t.s.selectedAction) end
			t.m:startCombat(tes3.mobilePlayer)		t.a.aiBehaviorState = 3
		elseif msg2 then tes3.messageBox("%s (%d/%d)  State = %s / %s   Fat = %d/%d (%d)", r.object.name, t.m.flee, t.m.fight, t.a.aiBehaviorState, t.s.selectedAction,
		t.m.fatigue.current, t.m.fatigue.base, 100*t.m.encumbrance.normalized) end
	end
	if table.size(R) == 0 then CT:cancel()	CT = nil	inv()	Sbar.visible = false	if msg2 then tes3.messageBox("The battle is over!") end end
	--if rrr then rrr:disable()	rrr.modified = false end	rrr = tes3.createReference{object = "4nm_light", scale = 3, position = e.actor.actionData.walkDestination, cell = p.cell}
end} end
end end

local function onDeterminedAction(e) if R[e.session.mobile.reference] then -- e.session:changeEquipment()
	tes3.messageBox("%s  Dist = %s  Action = %s  Prior = %s", e.session.mobile.reference, e.session.distance, e.session.selectedAction, e.session.selectionPriority)
end end

local function onDeactivated(e)
	if R[e.reference] then R[e.reference] = nil	if msg2 then tes3.messageBox("%s deactivated  Enemies = %s", e.reference, table.size(R)) end end
	if A[e.reference] then	if A[e.reference].mettim then A[e.reference].mettim:cancel() end	if A[e.reference].axetim then A[e.reference].axetim:cancel() end
		if A[e.reference].longtim then A[e.reference].longtim:cancel() end		A[e.reference] = nil
	end
end

--local function onCombatStopped(e) if R[e.actor.reference] then R[e.actor.reference] = nil	if msg2 then tes3.messageBox("%s leave combat  Enemies = %s", e.actor.reference, table.size(R)) end end end

local function onActivate(e) if e.activator == p and e.target.object.objectType == tes3.objectType.npc and e.target.mobile.fatigue.current < 0 then
if cfg.maniac and e.target.mobile.fatigue.current < (mp.agility.current - 100 - 50*e.target.mobile.health.normalized) then
	for _, s in pairs(e.target.object.equipment) do e.target.mobile:unequip{item = s.object} end	if msg then tes3.messageBox("Playful hands!") end
else if e.target.mobile.readiedWeapon then e.target.mobile:unequip{item = e.target.mobile.readiedWeapon.object} end		if e.target.mobile.readiedAmmo then e.target.mobile:unequip{item = e.target.mobile.readiedAmmo.object} end end
end end


local function onEquip(e) if e.reference == p and e.item.objectType == tes3.objectType.weapon then
	if e.item.type == 9 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 12 then
		for _, s in pairs(p.object.inventory) do if s.object.type == 12 then mwscript.equip{reference = p, item = s.object} if msg then tes3.messageBox("arrows equipped") end break end end
	elseif e.item.type == 10 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 13 then
		for _, s in pairs(p.object.inventory) do if s.object.type == 13 then mwscript.equip{reference = p, item = s.object} if msg then tes3.messageBox("bolts equipped") end break end end
	elseif cfg.autoshield and OneH[e.item.type] and not mp.readiedShield then
		for _, s in pairs(p.object.inventory) do if s.object.objectType == tes3.objectType.armor and s.object.slot == 8 then mwscript.equip{reference = p, item = s.object} break end end
	end
end end


local BlackAmmo = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true, ["her dart"] = true}
local function onProjectileHitActor(e) if e.target and e.target ~= p and e.mobile.reference.object.enchantment and not BlackAmmo[e.mobile.reference.object.id] then
	tes3.addItem{reference = e.target, item = e.mobile.reference.object, playSound = false}		--mwscript.addItem{reference = e.target, item = e.mobile.reference.object}
end end

local PRR = {}
local function onObjectInvalidated(e) if PRR[e.object] then PRR[e.object] = nil end end

local function onProj(e) if e.mobile.reference.object.id ~= "4nm_stone" and not BlackAmmo[e.mobile.reference.object.id] then	--tes3.playSound{reference = ref, sound = "Light Armor Hit", volume = 0.5}
	local hit = tes3.rayTest{position = e.collisionPoint:interpolate(e.firingReference.position + tes3vector3.new(0,0,90), 10),
	direction = e.firingReference == p and tes3.isAffectedBy{reference = p, effect = 506} and tes3.getPlayerEyeVector() or e.velocity} 
	local ref = tes3.createReference{object = e.mobile.reference.object, cell = p.cell, orientation = e.mobile.reference.sceneNode.worldTransform.rotation:toEulerXYZ(),
	position = hit and hit.intersection:distance(e.collisionPoint) < 250 and hit.intersection or e.collisionPoint + e.velocity * 0.7 * tes3.worldController.deltaTime}		ref.modified = false	PRR[ref] = true
end end

local function onLoaded(e)	p = tes3.player		mp = tes3.mobilePlayer		D = tes3.player.data	msg = cfg.msg	msg2 = cfg.msg2		R = {}	A = {}	CT = nil	inv()	com = 0
	for ref, _ in pairs(PRR) do ref:disable()	ref.modified = false end	PRR = {}
	Sbar = tes3ui.findMenu(-526):findChild(-573).parent:createFillBar{current = 100, max = 100}		Sbar.visible = false	Sbar.widget.showText = false	Sbar.width = 65		Sbar.height = 7		Sbar.widget.fillColor = {0,255,0}
	tes3ui.findMenu(-526):findChild(-866).parent.flowDirection = "top_to_bottom"
	Mbar = tes3ui.findMenu(-526):findChild(-866).parent:createFillBar{current = 100, max = 100}		Mbar.visible = false		Mbar.widget.showText = false	Mbar.width = 65		Mbar.height = 7		Mbar.widget.fillColor = {0,255,255}
end
local function onSave(e) if cfg.save and tes3.mobilePlayer.inCombat then tes3.messageBox("You cannot save the game in battle") return false end end


local function registerModConfig()	local template = mwse.mcm.createTemplate("4NM_COMBAT_5!")		template:saveOnClose("4NM_COMBAT_5!", cfg)		template:register()		local page = template:createPage()
page:createYesNoButton{label = "Show messages", variable = mwse.mcm.createTableVariable{id = "msg", table = cfg}}
page:createYesNoButton{label = "Show AI messages", variable = mwse.mcm.createTableVariable{id = "msg2", table = cfg}}
page:createSlider{label = "Minimum crit power to play crit strike sound", min = 0, max = 100, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "crit", table = cfg}}
page:createSlider{label = "Limit of stamina to which you agree to do active dodges", min = 30, max = 95, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "dodgelim", table = cfg}}
page:createYesNoButton{label = "Realistic run speed. Requires game restart", variable = mwse.mcm.createTableVariable{id = "Spd", table = cfg}}
page:createYesNoButton{label = "Improved enemies AI. Requires game restart", variable = mwse.mcm.createTableVariable{id = "AImod", table = cfg}}
page:createYesNoButton{label = "Arrows get stuck on hit. Requires game restart and... powerful PC", variable = mwse.mcm.createTableVariable{id = "Proj", table = cfg}}
page:createYesNoButton{label = "Maniac mode! You will try to undress knocked out enemies", variable = mwse.mcm.createTableVariable{id = "maniac", table = cfg}}
page:createYesNoButton{label = "Automatic shield equipment", variable = mwse.mcm.createTableVariable{id = "autoshield", table = cfg}}
page:createYesNoButton{label = "Show opponent's stamina bar", variable = mwse.mcm.createTableVariable{id = "sbar", table = cfg}}
page:createYesNoButton{label = "Prohibition saves during the battle", variable = mwse.mcm.createTableVariable{id = "save", table = cfg}}
end		event.register("modConfigReady", registerModConfig)


local function initialized(e)
tes3.findGMST("fEncumberedMoveEffect").value = 0.8		tes3.findGMST("fBaseRunMultiplier").value = 3		tes3.findGMST("fSwimRunBase").value = 0.3					tes3.findGMST("fSwimRunAthleticsMult").value = 0.2
tes3.findGMST("fJumpAcrobaticsBase").value = 278		tes3.findGMST("fJumpEncumbranceBase").value = 0		tes3.findGMST("fJumpEncumbranceMultiplier").value = 0.5		tes3.findGMST("fFallDistanceMult").value = 0.1
tes3.findGMST("fFallAcroBase").value = 0.5
tes3.findGMST("fFatigueReturnBase").value = 0			tes3.findGMST("fFatigueReturnMult").value = 0.1
tes3.findGMST("fFatigueAttackBase").value = 2			tes3.findGMST("fFatigueAttackMult").value = 8		tes3.findGMST("fWeaponFatigueMult").value = 1
tes3.findGMST("fFatigueBlockBase").value = 2			tes3.findGMST("fFatigueBlockMult").value = 8		tes3.findGMST("fWeaponFatigueBlockMult").value = 3
tes3.findGMST("fFatigueRunBase").value = 10				tes3.findGMST("fFatigueRunMult").value = 20			tes3.findGMST("fFatigueJumpBase").value = 20				tes3.findGMST("fFatigueJumpMult").value = 30
tes3.findGMST("fFatigueSwimWalkBase").value = 10		tes3.findGMST("fFatigueSwimWalkMult").value = 20	tes3.findGMST("fFatigueSwimRunBase").value = 20				tes3.findGMST("fFatigueSwimRunMult").value = 30
tes3.findGMST("fFatigueSneakBase").value = 0			tes3.findGMST("fFatigueSneakMult").value = 10
tes3.findGMST("fMinHandToHandMult").value = 0.04		tes3.findGMST("fMaxHandToHandMult").value = 0.2		tes3.findGMST("fHandtoHandHealthPer").value = 0.2			tes3.findGMST("fHandToHandReach").value = 0.5
tes3.findGMST("fKnockDownMult").value = 0.8				tes3.findGMST("iKnockDownOddsBase").value = 0		tes3.findGMST("iKnockDownOddsMult").value = 80
tes3.findGMST("fDamageStrengthBase").value = 1			tes3.findGMST("fCombatArmorMinMult").value = 0.1	tes3.findGMST("fUnarmoredBase2").value = 0.03
tes3.findGMST("fProjectileMinSpeed").value = 1000		tes3.findGMST("fProjectileMaxSpeed").value = 5000	tes3.findGMST("fThrownWeaponMinSpeed").value = 1000			tes3.findGMST("fThrownWeaponMaxSpeed").value = 3000
tes3.findGMST("iBlockMaxChance").value = 90				tes3.findGMST("fSwingBlockMult").value = 2			tes3.findGMST("fCombatBlockLeftAngle").value = -0.666		tes3.findGMST("fCombatBlockRightAngle").value = 0.333
tes3.findGMST("fCombatDelayCreature").value = -0.4		tes3.findGMST("fCombatDelayNPC").value = -0.4		tes3.findGMST("fProjectileThrownStoreChance").value = 100
tes3.findGMST("fAIFleeHealthMult").value = 50			tes3.findGMST("fAIFleeFleeMult").value = 1.5		tes3.findGMST("fFleeDistance").value = 5000					tes3.findGMST("fAIRangeMeleeWeaponMult").value = 70
tes3.findGMST("fCombatCriticalStrikeMult").value = 2	tes3.findGMST("fSneakViewMult").value = 2			tes3.findGMST("fSneakNoViewMult").value = 1					tes3.findGMST("fSneakDistanceMultiplier").value = 0.001

event.register("calcHitChance", onHit)
event.register("calcArmorPieceHit", onCalcArmorPieceHit)
event.register("attack", onAttack)
event.register("damage", onDamage)
event.register("exerciseSkill", onBlock, {filter = 0})
if cfg.Spd then event.register("calcMoveSpeed", onCalcMoveSpeed) end
event.register("mobileDeactivated", onDeactivated)
event.register("death", onDeactivated)
--event.register("combatStopped", onCombatStopped)
event.register("calcArmorRating", onCalcArmorRating)
event.register("activate", onActivate)
event.register("equip", onEquip)
event.register("projectileHitActor", onProjectileHitActor)
if cfg.Proj then event.register("projectileHitObject", onProj)	event.register("projectileHitTerrain", onProj)	event.register("objectInvalidated", onObjectInvalidated) end
event.register("loaded", onLoaded, {priority = 10})
event.register("save", onSave)
if cfg.AImod then event.register("combatStarted", onCombatStarted) end
--event.register("determinedAction", onDeterminedAction)
end		event.register("initialized", initialized)