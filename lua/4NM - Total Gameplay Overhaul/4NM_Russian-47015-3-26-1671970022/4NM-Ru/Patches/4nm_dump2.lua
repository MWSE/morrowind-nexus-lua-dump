
local function SIMULATE(e)		--tes3.messageBox("State = %s", ad.animationAttackState)
	if G.LastMana and (G.LastInt ~= mp.intelligence.current or G.LastMM ~= mp.magickaMultiplier.current) and G.LastMana < mp.magicka.current then mp.magicka.current = G.LastMana		M.Mana.current = G.LastMana end
	G.LastMana = mp.magicka.current		G.LastInt = mp.intelligence.current		G.LastMM = mp.magickaMultiplier.current
end		event.register("simulate", SIMULATE)


local function ABSORBEDMAGIC(e)	if e.mobile == mp then	local pow	local s = e.source	local si = e.sourceInstance			local num = s:getActiveEffectCount()
if s.weight then pow = 0	for i, ef in ipairs(s.effects) do if ef.id ~= -1 then pow = pow + (ef.min + ef.max) * ef.cost * ef.duration/40 end end
else pow = e.absorb end
if not (P.mys21 and mp.spellReadied) then pow = pow/2 end		e.absorb = pow/num
if cf.m then tes3.messageBox("ABS %s  Mana + %.1f  (%d / %d eff)", s.name or s.id, e.absorb, pow, num) end
end end		event.register("absorbedMagic", ABSORBEDMAGIC)

local function SPELLRESIST(e)	local c, resist, Cbonus, CritC, CritD		local t = e.target	local m = t.mobile	local s = e.source	local ef = e.effect		local dur = ef.duration		local rt = ef.rangeType
local eid = ef.id	local sc = ef.object.school		local si = e.sourceInstance		local sn = si.serialNumber		local sot = s.objectType 		local wg = s.weight		local RP = 0	--local ei = e.effectInstance
if e.caster then if wg then if wg == 0 then	-- для алхимии с весом кастера нет
	if rt == 0 then		if e.resistAttribute == 28 then c = e.caster.mobile else c = SNC[sn] end
	else c = e.caster.mobile end
end else c = e.caster.mobile end end
local MKF = L.DurKF[eid] and (c ~= mp or P.int9) and dur > 1 and 1 + L.DurKF[eid]/100 * (dur - 1)^0.5 or 1
if c then 	local Emp = 0	local will = c.willpower.current
	if EMP[eid] and c.reference.data.EMP then Emp = tes3.getEffectMagnitude{reference = c.reference, effect = EMP[eid].e} if Emp > 0 then MKF = MKF + Emp/200 else c.reference.data.EMP = nil end end
	Cbonus = c:getSkillValue(SP[sc].s)/((c ~= mp or P[MEP[eid] and MEP[eid].p0 or SP[sc].p1]) and 5 or 10) + ((c ~= mp or P[MEP[eid] and MEP[eid].p or "mys0"]) and c:getSkillValue(MEP[eid] and MEP[eid].s or 14)/10 or 0)
	if sot == tes3.objectType.enchantment then Cbonus = Cbonus/3 + c:getSkillValue(9)/((c ~= mp or P.enc1) and 5 or 10) end		Cbonus = Cbonus + will/((c ~= mp or P.wil1) and 5 or 10)
	if ME[eid] == "shield" and m == mp and P.una7 then Cbonus = Cbonus + D.AR.u * m:getSkillValue(17)/100 end
	CritC = will/(1+will/400)/((c ~= mp or P.wil4) and 8 or 16) + ((c ~= mp or P.luc1) and c.luck.current/20 or 0)
	+ (c == mp and (P.int5 and mp.spellReadied and 5 or 0) or c.object.level + 10) + ((c ~= mp or P.des7) and Emp/10 or 0)
	- (e.resistAttribute == 28 and 10 or ((m.spellReadied and (m ~= mp or P.mys5) and m:getSkillValue(14)/10 or 0) + m.willpower.current/((m ~= mp or P.wil6) and 10 or 20) + ((m ~= mp or P.luc2) and m.luck.current/20 or 0)
	- ((c ~= mp or P.wil8) and c.attackBonus/10 or 0) - ((c ~= mp or P.des0) and c:getSkillValue(10)/20 or 0) - math.max(1-m.fatigue.normalized,0)*((c ~= mp or P.int1) and 20 or 10) ))
	CritD = CritC - math.random(100)	if CritD < 0 then CritD = 0 else CritD = CritD + 10 + ((c ~= mp or P.wil11) and 10 or 0) + (EMP[eid] and (c ~= mp or P[EMP[eid].p]) and c:getSkillValue(10)/10 or 0) end
	if c == mp then	local Koef = SN[sn]		if Koef then	if Koef > 1 then MKF = MKF + Koef - 1 else MKF = MKF * Koef end end end
	
else	Cbonus = 0	CritC = 0	CritD = 0 end -- Обычные зелья, обычные яды, алтари, ловушки и прочие кастующие активаторы
if e.resistAttribute == 28 then -- Магия с позитивными эффектами
	if sot == tes3.objectType.spell and s.castType == 0 then -- Не влияет  на пост.эффекты, powers(5), всегда успешные
		if not s.alwaysSucceeds then RP = 0 - Cbonus - CritD		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% spell power (+ %.1f bonus + %.1f crit (%.1f%%)) x%.2f mult", s.name, 100 - RP, Cbonus, CritD, CritC, MKF) end
		elseif L.AA[s.id] and c == mp and ME[eid] ~= 0 then
			local Kstam = math.min(math.lerp((P.end18 and 0.5 or 0.2), 1, mp.fatigue.normalized*1.1), 1)
			RP = 0 - math.min(L.AA[s.id].s and c:getSkillValue(L.AA[s.id].s) or t.object.level,100)*(P.agi21 and 1 or 0.5)			RP = 100 - (100 - RP) * Kstam
			if cf.m1 then tes3.messageBox("%s  %d%% technique power   %d%% stam", s.name, 100 - RP, Kstam*100) end
		elseif L.STAR[s.id] then RP = - t.object.level	if cf.m1 then tes3.messageBox("%s  %d%% Star power", s.name, 100 - RP) end end
	elseif wg then
		if wg == 0 then
			if s.icon == "" and m == mp and not L.ING[s.name] then RP = P.alc2 and 75 or 90	if cf.m1 then tes3.messageBox("%s  ingred power = %.1f for %d seconds", s.name, ef.max*(100-RP)/100, dur) end end
		else MKF = m == mp and 1 - math.max((D.potcd and D.potcd - 40 - G.potlim/(P.alc11 and 2 or 4) or 0)/G.potlim, 0) or 1
			RP = 0 - m.willpower.current/10 - m:getSkillValue(16)/((m ~= mp or P.alc1) and 5 or 10) - (m == mp and P.alc12 and (D.potcd or 0) < 35 and 20 or 0)
			if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% alchemy power   x%.2f mult", s.name, 100 - RP, MKF) end
		end
	elseif sot == tes3.objectType.enchantment then -- Сила зачарований castType 0=castOnce, 1=onStrike, 2=onUse, 3=constant
		if s.castType ~= 3 then	RP = 0 - Cbonus - CritD		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if eid == 76 and t == p and s.castType ~= 0 then RP = math.max(RP, 90) end
			if cf.m1 then tes3.messageBox("%s  %.1f%% enchant power (+ %.1f bonus + %.1f crit (%.1f%%)) x%.2f mult", s.id, 100 - RP, Cbonus, CritD, CritC, MKF) end
		elseif t == p then ConstEnLim()	if cf.enchlim then
			if W.DWM and si.item.objectType == tes3.objectType.weapon then e.resistedPercent = 100 return end
			if M.ENL.normalized > 1 then e.resistedPercent = 100	tes3.messageBox("Enchant limit exceeded! %d / %d", M.ENL.current, M.ENL.max)	tes3.playSound{sound = "Spell Failure Conjuration"} return
			elseif ef.min ~= ef.max and ME[eid] ~= 2 then RP = 50	tes3.messageBox("Anti-exploit! Enchant power reduced by half!") end
		end end
	end
	if RP < 100 then
	if ef.object.school == 1 then L.conjpower = 1 - RP/200	L.conjp = t == p or nil		L.conjagr = t ~= p and m.fight > 80 or nil
		if ME[eid] == 3 and (t ~= p or P.con14 or RP > 0) then
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end)
		elseif ME[eid] == 0 then
			if t == p then
				if P.con11 then
					if wg == 0 and s.name == "Summon" or (sot == tes3.objectType.enchantment and s.castType == 3) then e.resistedPercent = RP		L.conjpower = L.conjpow1	return
					else tes3.applyMagicSource{reference = p, name = "Summon", effects = {{id = eid, duration = dur * ((P.con16 or RP > 0) and 1 - RP/100 or 1)}}}
						L.conjpow1 = L.conjpower		e.resistedPercent = 100		return
					end
				elseif P.con16 or RP > 0 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end) end
			else timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end) end
		end
	end
	if eid < 500 then
		if ME[eid] == 4 and c == mp and P.res10 and RP < 0 then
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * math.max(RP/500, -0.2) end end)
		elseif ME[eid] == 5 and c == mp and P.res11 and RP < 0 then
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * math.max(RP/500, -0.2) end end)
		elseif eid == 75 then pow = math.random(ef.min, ef.max) * dur * (1 - RP/100) * ((c ~= mp or P.res6) and 1 or 0.5)
		--	timer.delayOneFrame(function() for _, aef in pairs(mp:getActiveMagicEffects{effect = eid, serial = sn}) do aef.effectInstance.timeActive = aef.duration - 5		aef.effectInstance.state = 6
		--	tes3.messageBox("%s (%s)   dur = %.1f / %.1f", aef.instance.source.name or aef.instance.source.id, e.effectIndex == aef.effectIndex, aef.effectInstance.timeActive, aef.duration) end end)
			if AF[t].vital and AF[t].vital > 0 then AF[t].vital = AF[t].vital - pow		pow = - AF[t].vital end
			if pow > 0 then AF[t].heal = (AF[t].heal or 0) + pow	if not T.Heal.timeLeft then
				T.Heal = timer.start{duration = 3, iterations = -1, callback = function()	local fin = true
					for r, a in pairs(AF) do if a.heal and a.heal > 0 then fin = nil	a.heal = a.heal - a.heal^0.5*3	if a.heal < 3 then a.heal = nil
						else for i, s in ipairs(L.HealStat) do if i ~= 8 and r.mobile[s].current < r.mobile[s].base then tes3.modStatistic{reference = r, name = s, current = a.heal^0.5/2, limitToBase = true}	
							if cf.m2 then tes3.messageBox("%s Healing = %d (+%d stat)", r, a.heal, a.heal^0.5/2) end	break end
							if i == 8 and r.mobile.fatigue.normalized <= 1 then r.mobile.fatigue.current = r.mobile.fatigue.current	+ a.heal^0.5 * ((r ~= p or P.res13) and 5 or 3)
								if cf.m2 then tes3.messageBox("%s Healing = %d (+%d stamina)", r, a.heal, a.heal^0.5 * ((r ~= p or P.res13) and 5 or 3)) end
							end
						end end
					else a.heal = nil end end	if fin then	T.Heal:cancel() end
				end}
			end end
		elseif L.CME[eid] and AF[t][L.CME[eid]] then
			AF[t][L.CME[eid]] = AF[t][L.CME[eid]] - (ef.object.hasNoMagnitude and 100 or math.random(ef.min, ef.max) * dur) * (1 - RP/100) * ((m ~= mp or P.alt14) and 1 + m:getSkillValue(11)/100 or 1)
		elseif eid == 10 and rt ~= 0 and t ~= p then resist = RP + math.max(m.resistMagicka,-100) + m.willpower.current + m:getSkillValue(14)/2	-- Левитация
			if cf.m then tes3.messageBox("%s  %.1f%% levitation resist", s.name or s.id, resist) end		if resist >= math.random(100) then RP = 100 end
		elseif eid == 39 and t == p and s.name ~= "Blur" then	-- Невидимость
			if P.ill10 and RP < 0 then tes3.applyMagicSource{reference = p, name = "Blur", effects = {{id = 39, duration = dur * (P.ill17 and 1 - RP/100 or 1)}, 
				{id = 40, min = -RP/4, max = -RP/2, duration = dur}}}
			elseif P.ill17 or RP > 0 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * RP/100 end end) end
		elseif eid == 118 or eid == 119 then RP = RP + math.max(m.resistMagicka,0) + (m.willpower.current + m:getSkillValue(14)/2)*(P.ill9 and 0.5 or 1) -- Приказы
			if cf.m then tes3.messageBox("%s  %.1f%% mind control resist", s.name or s.id, RP) end
			if R[t] then timer.start{duration = 0.1, callback = function() if tes3.isAffectedBy{reference = t, effect = eid} then R[t] = nil if cf.m4 then tes3.messageBox("CONTROL! %s", t) end end end} end
		elseif eid == 60 and t == p then local mmax = (1 + mp.willpower.base/200 + mp.intelligence.base/100 + mp.alteration.base/200 + mp.mysticism.base/50) * (P.mys11 and 2 or 1) -- Пометка
			local mtab = {}		for i = 1, 10 do if mmax >= i then mtab[i] = i.." - "..(DM["mark"..i] and DM["mark"..i].id or "empty") end end
			tes3.messageBox{message = "Which slot to remember the mark?", buttons = mtab, callback = function(e) DM["mark"..(e.button+1)] = {id = p.cell.id, x = pp.x, y = pp.y, z = pp.z} end}
		elseif eid == 0 and t == p then		-- Водное дыхание
			local WBR = mp.holdBreathTime
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * RP/100 end
			timer.delayOneFrame(function() mp.holdBreathTime = WBR end) end)
			if not T.WaterB.timeLeft then T.WaterB = timer.start{iterations = -1, duration = 1, callback = function()
				if mp.waterBreathing > 0 then mp.holdBreathTime = math.min(math.max(mp.holdBreathTime, 0) + mp.waterBreathing/2 - 0.3, tes3.findGMST("fHoldBreathTime").value)
				else T.WaterB:cancel()	if not mp.underwater then mp.holdBreathTime = tes3.findGMST("fHoldBreathTime").value end end		-- tes3ui.findHelpLayerMenu("MenuSwimFillBar")
			end} end
		elseif eid == 2 and t == p then	-- Хождение по воде
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * RP/100 end end)
		elseif ME[eid] == "teleport" then
			if L.TPComp() then timer.start{duration = 0.1, callback = function() for r, _ in pairs (G.TPList) do tes3.positionCell{reference = r, position = pp, cell = p.cell} end end} end
		elseif eid == 13 and P.mys23 then	-- Взлом замков
			if t.lockNode and t.lockNode.trap then pow = math.random(ef.min, ef.max) * (1 - RP/100) 
				tes3.messageBox("Power = %d   Trap = %d", pow, t.lockNode.trap.magickaCost * 4)
				if pow > t.lockNode.trap.magickaCost * 4 then t.lockNode.trap = nil 	tes3.playSound{reference = t, sound = "Disarm Trap"} end
			end
		end
	elseif eid == 501 and AF[t].T501 == nil then -- Перезарядка зачарованного (501)
		if t == p then AF[t].T501 = timer.start{duration = 1, iterations = -1, callback = L.RechargeTik} 	G.REI = {}
		else AF[t].T501 = timer.start{duration = 1, iterations = -1, callback = function() L.RechargeNPC(m, t) end} end
	elseif eid == 502 and AF[t].T502 == nil then -- Починка оружия (502)
		AF[t].T502 = timer.start{duration = 1, iterations = -1, callback = function() local mag = Mag(502,t)	if mag == 0 then AF[t].T502:cancel()	AF[t].T502 = nil else
			pow = mag * (1 + ((m ~= mp or P.arm6) and m:getSkillValue(1)/400 or 0))		local w = m.readiedWeapon
			if w and w.object.type ~= 11 and w.variables.condition < w.object.maxCondition then w.variables.condition = math.min(w.variables.condition + pow, w.object.maxCondition)
				if cf.m1 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, w.object.name, w.variables.condition, w.object.maxCondition) end
			end
		end end}
	elseif eid == 503 and AF[t].T503 == nil then -- Починка брони (503)
		AF[t].T503 = timer.start{duration = 1, iterations = -1, callback = function() local mag = Mag(503,t)	if mag == 0 then AF[t].T503:cancel()	AF[t].T503 = nil else
			pow = mag * (1 + ((m ~= mp or P.arm6) and m:getSkillValue(1)/400 or 0))	
			for _, st in pairs(t.object.equipment) do if st.object.objectType == tes3.objectType.armor and st.variables and st.variables.condition < st.object.maxCondition then
				st.variables.condition = math.min(st.variables.condition + pow, st.object.maxCondition)
				if cf.m1 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, st.object.name, st.variables.condition, st.object.maxCondition) end	break
			end end
		end end}
	elseif ME[eid] == "charge" then t.data.CW = true	-- Зарядить оружие. Эффекты 511, 512, 513, 514, 515
	elseif ME[eid] == "empower" then t.data.EMP = true
	elseif ME[eid] == "reflect" and not t.data.RFN then t.data.RFN = {} -- Отражения стихиями 
	elseif eid == 507 and not t.data.RFS then t.data.RFS = {} -- Отражение заклинаний
	elseif eid == 508 then t.data.KS = true	-- Кинетический щит
	elseif eid == 509 then t.data.LL = true	-- Лайф лич
	elseif ME[eid] == "aura" and t == p then D.AUR = true		if not T.AUR.timeLeft then T.AUR = timer.start{duration = P.alt11 and math.max(3 - mp:getSkillValue(11)/200, 2.5) or 3, iterations = -1, callback = L.AuraTik} end
		if AF[t][L.CME[eid]] then AF[t][L.CME[eid]] = AF[t][L.CME[eid]] - math.random(ef.min, ef.max) * dur * (1 - RP/100) * ((m ~= mp or P.alt14) and 1 + m:getSkillValue(11)/100 or 1) end
	elseif ME[eid] == "explode" and t == p then D.Exp = true
	elseif eid == 601 and t == p and cf.autoammo then	mc = BAM.f()	if m.readiedWeapon then BAM.am = BAM[m.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
		if m.magicka.current > mc and mwscript.getItemCount{reference = t, item = BAM.am} == 0 then tes3.addItem{reference = t, item = BAM.am, count = 1, playSound = false}
			mwscript.equip{reference = t, item = BAM.am}	Mod(mc)
		end
	elseif eid == 510 and t == p then 	-- not T.TS.timeLeft then event.register("simulate", SIMTS)	-- Замедление времени (510)
		timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	L.UpdTSK()		if ei and dur > 0 then ei.timeActive = dur * (1 - TSK) end end)
	
		--if not T.TS.timeLeft then T.TS = timer.start{duration = 0.1, iterations = -1, callback = L.UpdTSK} end
		
		--for _, aef in pairs(mp:getActiveMagicEffects{effect = 510}) do --aef.effectInstance.timeActive = aef.duration - 5		aef.effectInstance.state = 6
		--aef.effectInstance.timeActive = aef.effectInstance.timeActive + 100
		--tes3.messageBox("%s (%s)   dur = %.1f / %.1f", aef.instance.source.name or aef.instance.source.id, aef.effectIndex, aef.effectInstance.timeActive, aef.duration) end
	elseif eid == 504 and t == p then D.ligspawn = true		local col = L.Rcol(cf.col)
		LI.l.color[1] = col[1]		LI.l.color[2] = col[2]		LI.l.color[3] = col[3]		LI.l.radius = 100 * math.random(ef.min, ef.max) * (1 - RP/100)
		if T.LI.timeLeft then	event.unregister("simulate", LI.SIM)	T.LI:cancel()	LI.r:delete()	LI.r = nil end		LI.New(dur, pp)
		if cf.m then tes3.messageBox("Light active! Radius = %d  Time = %d   Total = %d", LI.l.radius, dur, table.size(LI.R)) end
	end
	end
elseif wg or rt ~= 0 then local Tarmor, Tbonus, IsPois		-- Любые негативные эффекты с дальностью касание и удаленная цель ИЛИ пвсевдоалхимия ИЛИ обычные яды ИЛИ ингредиенты
	if e.caster == t then
		if rt ~= 0 then MKF = MKF * math.max(1 - (m:getSkillValue(14) + m.willpower.current)/((m ~= mp or P.mys15) and 400 or 800), 0.25)		-- Отражение или эксплод спелл будут ослаблены
		elseif wg > 0 or s.icon == "" then if L.ING[s.name] then e.resistedPercent = 0 return end		IsPois = true		Cbonus = 0	CritC = 0	CritD = 0 end
	end
	if not IsPois and rt ~= 0 then
		if m ~= mp and L.Summon[c and c.object.baseObject.id] then MKF = MKF/2 end
		if t.data.RFS then if t.data.RFS.num == sn then MKF = MKF * (1 - t.data.RFS.pow)	if MKF == 0 then e.resistedPercent = 100 return end else local RFSM = Mag(507,t) * ((m ~= mp or P.mys14) and 1.2 or 1)
			if RFSM == 0 then t.data.RFS = nil else	local pow = 0
				for i, eff in ipairs(s.effects) do if eff.id ~= -1 and eff.rangeType ~= 0 then pow = pow + (eff.min + eff.max) * eff.object.baseMagickaCost * eff.duration/20 end end
				pow = pow * (100 + Cbonus + CritD)*MKF/100
				if m ~= mp or DM.refl then
					if RFSM > pow then mc = pow * ((m ~= mp or P.mys7g) and 2 or 2.5)			if m.magicka.current > mc then local rad = L.GetRad(m)	local E = B.RFS.effects
						for i, eff in ipairs(s.effects) do if eff.rangeType ~= 0 then	E[i].id = eff.id	E[i].radius = math.min(eff.radius, rad)		E[i].duration = eff.duration
						E[i].min = eff.min	E[i].max = eff.max	E[i].rangeType = eff.rangeType		E[i].attribute = eff.attribute		E[i].skill = eff.skill	else E[i].id = -1	E[i].rangeType = 0 end end
						tes3.applyMagicSource{reference = t, source = B.RFS}		Mod(mc,m)		t.data.RFS.pow = 1		t.data.RFS.num = sn		e.resistedPercent = 100	
						if cf.m then tes3.messageBox("Reflect = %.1f / %.1f  Cost = %.1f  Radius = %.1f", RFSM, pow, mc, rad) end	return
					end else if cf.m then tes3.messageBox("Fail! Reflect = %.1f  Power = %.1f", RFSM, pow) end end
				else	local RFSK = math.min(RFSM/pow, cf.mshmax/100)		mc = RFSK * pow * ((m ~= mp or P.mys7g) and 1.5 or 2)
					if m.magicka.current > mc then	Mod(mc,m)	MKF = MKF * (1 - RFSK)		t.data.RFS.pow = RFSK		t.data.RFS.num = sn
					if cf.m then tes3.messageBox("Manashield = %.1f / %.1f  Koef = %d%%  Cost = %.1f", RFSM, pow, RFSK*100, mc) end		if MKF == 0 then e.resistedPercent = 100 return end end
				end
			end
		end end
		if t.data.RFN then if t.data.RFN.num == sn then MKF = MKF * (1 - t.data.RFN.pow)	if MKF == 0 then e.resistedPercent = 100 return end else
			local RFM = {tes3.getEffectMagnitude{reference = t, effect = 561}, tes3.getEffectMagnitude{reference = t, effect = 562}, tes3.getEffectMagnitude{reference = t, effect = 563},
			tes3.getEffectMagnitude{reference = t, effect = 564}, (tes3.getEffectMagnitude{reference = t, effect = 565})}
			local Koef = (m ~= mp or P.mys14) and 1.2 or 1		for i, mag in ipairs(RFM) do if mag ~= 0 then RFM[i] = RFM[i] * Koef end end		local RFMS = RFM[1] + RFM[2] + RFM[3] + RFM[4] + RFM[5]
			if RFMS == 0 then t.data.RFN = nil else	local pow = 0
				for i, eff in ipairs(s.effects) do if eff.rangeType ~= 0 and eff.id ~= -1 then pow = pow + (eff.min + eff.max) * eff.duration * eff.object.baseMagickaCost/20 end end
				pow = pow * MKF		local pow2 = pow * (100 + Cbonus + CritD)/100		local RFK = math.min(RFMS/pow2, cf.rfmax/100)		mc = RFK * pow2 * ((m ~= mp or P.mys7g) and 2.5 or 3)
				if m.magicka.current > mc then	local rad = L.GetRad(m)	local MAG	local E = B.RF.effects
					for i, mag in ipairs(RFM) do if mag ~= 0 then MAG = pow * RFK * mag/RFMS * 10 / L.MEC[i]	E[i].id = MID[i]	E[i].min = MAG	E[i].max = MAG	E[i].radius = rad	E[i].rangeType = 2	E[i].duration = 1
					else E[i].id = -1	E[i].rangeType = 0 end end
					tes3.applyMagicSource{reference = t, source = B.RF}		Mod(mc,m)	MKF = MKF * (1 - RFK)	t.data.RFN.pow = RFK	t.data.RFN.num = sn
					if cf.m then tes3.messageBox("NewRefl = %.1f / %.1f (base %.1f)  Koef = %d%%  Cost = %.1f  Radius = %.1f", RFMS, pow2, pow, RFK*100, mc, rad) end		if MKF == 0 then e.resistedPercent = 100 return end
				end
			end
		end end
	end
	local NormR = math.max(m[L.RES[eid] or (IsPois and "resistPoison" or "resistMagicka")],-100)
	if ME[eid] == 1 then Tarmor = m.armorRating * ((m ~= mp or P.end21) and 0.2 or 0.1)			local rsh = m.readiedShield
		Tbonus = (math.min(m.endurance.current,100)/5 + math.min(m.willpower.current,100)/5) * ((m ~= mp or P[EMP[eid].p3]) and 1 or 0.5) + ((m ~= mp or P.des9) and math.min(m:getSkillValue(10),100)/10 or 0)
		if c == mp and ((P.mys9 and m.object.type == 1) or (P.res9 and m.object.type == 2)) then Cbonus = Cbonus + 10 end
		if rsh and (m ~= mp or mp.actionData.animationAttackState == 2) then Tbonus = Tbonus + m:getSkillValue(0)/((m ~= mp or P.bloc7) and 5 or 10)
			rsh.variables.condition = math.max(rsh.variables.condition - math.random(ef.min, ef.max) * math.max(dur,1) * MKF/2, 0)
			if m == mp then L.UpdShield(rsh) end		if rsh.variables.condition < 0.1 then m:unequip{item = rsh.object} end
		end
	end
	if eid == 14 then	local frostbonus	local burst = AF[t].fire and AF[t].fire^0.5*2 or 0
		if AF[t].frost and AF[t].frost > 0 then frostbonus = AF[t].frost^0.5*5		AF[t].frost = math.max(AF[t].frost - math.random(ef.min, ef.max) * dur, 0) else frostbonus = 0 end
		resist = NormR + Tarmor + Tbonus - Cbonus - CritD - burst + frostbonus
		if resist > 350 and m.health.normalized < 1 and (m ~= mp or P.alt9) then RP = math.min(resist - 250, 150) elseif resist > 0 then RP = math.min(resist/(1 + resist/150), 100) else RP = resist end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% fire resist (%.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f crit (%.1f%%) - %.1f burst + %.1f frost) x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Tarmor, Cbonus, CritD, CritC, burst, frostbonus, MKF) end
		if RP < 100 then AF[t].fire = (AF[t].fire or 0) + math.random(ef.min, ef.max) * dur * (1 - RP/100) *
			((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			if not T.Fire.timeLeft then T.Fire = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.fire and a.fire > 0 then fin = nil
					a.fire = a.fire - a.fire^0.5	if a.fire < 3 then a.fire = nil elseif cf.m2 then tes3.messageBox("%s Fire = %d (%d%% burst)", r, a.fire, a.fire^0.5*2) end
				else a.fire = nil end end	if fin then	T.Fire:cancel() end
			end} end
		end
	elseif eid == 16 then	local firebonus		if AF[t].fire and AF[t].fire > 0 then firebonus = AF[t].fire^0.5*5		AF[t].fire = math.max(AF[t].fire - math.random(ef.min, ef.max) * dur, 0) else firebonus = 0 end
		resist = NormR + Tarmor + Tbonus - Cbonus - CritD + firebonus
		if resist > 350 and m.health.normalized < 1 and (m ~= mp or P.alt9) then RP = math.min(resist - 250, 150) elseif resist > 0 then RP = math.min(resist/(1 + resist/150), 100) else RP = resist end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% frost resist (%.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f crit (%.1f%%) + %.1f fire) x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Tarmor, Cbonus, CritD, CritC, firebonus, MKF) end
		if RP < 100 then AF[t].frost = (AF[t].frost or 0) + math.random(ef.min, ef.max) * dur * (1 - RP/100) *
			((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			if not T.Frost.timeLeft then event.register("calcMoveSpeed", CMSFrost)	T.Frost = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.frost and a.frost > 0 then fin = nil		a.frost = a.frost - a.frost^0.5	
					if a.frost < 3 then a.frost = nil FR[r] = nil else FR[r] = math.max(1 - a.frost^0.5*0.04, 0.1)		if cf.m2 then tes3.messageBox("%s Frost = %d (%d%% frozen speed)", r, a.frost, FR[r]*100) end end
				else a.frost = nil FR[r] = nil end end	if fin then event.unregister("calcMoveSpeed", CMSFrost)	T.Frost:cancel() end
			end} end
		end
	elseif eid == 15 then
		resist = NormR + Tarmor + Tbonus - Cbonus - CritD
		if resist > 350 and m.health.normalized < 1 and (m ~= mp or P.alt9) then RP = math.min(resist - 250, 150) elseif resist > 0 then RP = math.min(resist/(1 + resist/150), 100) else RP = resist end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% lightning resist (%.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f crit (%.1f%%)) x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Tarmor, Cbonus, CritD, CritC, MKF) end
		if RP < 100 then AF[t].shock = (AF[t].shock or 0) + math.random(ef.min, ef.max) * dur * (1 - RP/100) *
			((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			if not T.Shock.timeLeft then T.Shock = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.shock and a.shock > 0 then fin = nil	a.shock = a.shock - a.shock^0.5	if a.shock < 3 then a.shock = nil
					else Mod(0.5*a.shock^0.5, r.mobile)		if cf.m2 then tes3.messageBox("%s Shock = %d (-%d mana  %d%% tremor)", r, a.shock, a.shock^0.5/2, a.shock^0.5*5) end
					if a.shock^0.5*5 >= math.random(100) then
						local ShSi = tes3.applyMagicSource{reference = r, name = "Electroshock", effects = {{id = 45, min = 1, max = 1, duration = 1}}}
						timer.start{duration = math.min(0.3 + a.shock^0.5/100, 0.9), callback = function() ShSi.state = 6 end}
					end end
				else a.shock = nil end end	if fin then	T.Shock:cancel() end
			end} end
		end
	elseif eid == 27 then Tbonus = (math.min(m.endurance.current,100)*0.3 + math.min(m.willpower.current,100)*0.1) * ((m ~= mp or P[EMP[eid].p3]) and 1 or 0.5) + ((m ~= mp or P.alc10) and math.min(m:getSkillValue(16),100)/10 or 0)
		resist = NormR + Tbonus - Cbonus - CritD
		if resist > 350 and m.health.normalized < 1 and (m ~= mp or P.alt9) then RP = math.min(resist - 250, 150) elseif resist > 0 then RP = math.min(resist/(1 + resist/150), 100) else RP = resist end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% poison resist (%.1f = %.1f norm + %.1f target - %.1f caster - %.1f crit (%.1f%%)) x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Cbonus, CritD, CritC, MKF) end	
		if RP < 100 then AF[t].poison = (AF[t].poison or 0) + math.random(ef.min, ef.max) * dur * (1 - RP/100) *
			((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			if not T.Poison.timeLeft then T.Poison = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.poison and a.poison > 0 then fin = nil	a.poison = a.poison - a.poison^0.5	if a.poison < 3 then a.poison = nil 
					else r.mobile.fatigue.current = r.mobile.fatigue.current - a.poison^0.5		if cf.m2 then tes3.messageBox("%s Poison = %d (-%d stamina)", r, a.poison, a.poison^0.5) end end
				else a.poison = nil end end	if fin then	T.Poison:cancel() end
			end} end
		end
	else	Tbonus = (math.min(m.endurance.current,100)*0.1 + math.min(m.willpower.current,100)*0.3) * ((m ~= mp or P.wil3) and 1 or 0.5) + ((m ~= mp or P.mys6) and math.min(m:getSkillValue(14),100)/10 or 0)
		if eid == 45 or eid == 46 then local Extra = m:getSkillValue(12) * ((m ~= mp or P.ill6) and 0.3 or 0.1) > math.random(100) and 100 or 0			-- Паралич и молчание считаем отдельно
			resist = NormR + m.resistParalysis + Tbonus - Cbonus - CritD + Extra
			RP = resist > 0 and resist/(1 + resist/150) or resist		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% paralysis resist (%.1f = %.1f paral + %.1f magic + %.1f target - %.1f caster - %.1f crit (%.1f%%) + %d extra) x%.2f mult",
			s.name or s.id, RP, resist, m.resistParalysis, NormR, Tbonus, Cbonus, CritD, CritC, Extra, MKF) end
			if RP >= 100 then RP = 100 elseif RP > 0 or (RP < 0 and (c ~= mp or P.ill18)) then
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end) end
		elseif eid == 55 or eid == 56 then local Extra = P.per9 and mp.personality.current/5 or 0
			RP = 0 - Cbonus - CritD	- Extra		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end		-- Ралли
			local koef = 1 - RP/100		local min = ef.min*koef		local max = ef.max*koef		local k1 = P.ill14 and 1 or 0.5		local k2 = P.ill15 and 0.02 or 0	local k3 = P.ill16 and 0.05 or 0
			tes3.applyMagicSource{reference = t, name = "Rally", effects = {{id = 79, min = min*k1, max = max*k1, attribute = math.random(0,5), duration = dur},
			{id = 77, min = min*k1/2, max = max*k1/2, duration = dur}, {id = 75, min = min*k2, max = max*k2, duration = dur}, {id = 76, min = min*k3, max = max*k3, duration = dur}}}
			if cf.m1 then tes3.messageBox("%s  %.1f%% Rally power (+ %.1f bonus + %.1f crit (%.1f%%) + %d extra) x%.2f mult", s.name or s.id, 100 - RP, Cbonus, CritD, CritC, Extra, MKF) end
		else resist = NormR + Tbonus - Cbonus - CritD	-- Всё остальное негативное кроме паралича и ралли
			if resist > 0 then RP = math.min(resist/(1 + resist/150), 100) else RP = resist end			if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% magic resist (%.1f = %.1f norm + %.1f target - %.1f caster - %.1f crit (%.1f%%)) x%.2f mult",
			(s.name or s.id), RP, resist, NormR, Tbonus, Cbonus, CritD, CritC, MKF) end
			if eid == 23 and RP < 100 then AF[t].vital = (AF[t].vital or 0) + math.random(ef.min, ef.max) * dur * (1 - RP/100) *
				((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
				if not T.Vital.timeLeft then T.Vital = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
					for r, a in pairs(AF) do if a.vital and a.vital > 0 then fin = nil	a.vital = a.vital - a.vital^0.5
						if a.vital < 3 then a.vital = nil else
						if a.vital^0.5*5 > math.random(100) then tes3.modStatistic{reference = r, name = L.Traum[math.random(5)], current = -0.5*a.vital^0.5}	if cf.m then tes3.messageBox("%s  %.1f trauma damage!", r, a.vital^0.5*0.5) end end
						if cf.m2 then tes3.messageBox("%s Trauma = %d (%d%% chance)", r, a.vital, a.vital^0.5*5) end end
					else a.vital = nil end end	if fin then	T.Vital:cancel() end
				end} end
			elseif ME[eid] == 6 and RP < 100 then
				if t == p and P.res12 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * (0.1 + math.max(RP/500, 0)) end end)
				elseif c == mp and P.des10 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * (math.min(RP/1000, 0) - 0.1) end end) end
			elseif ME[eid] == 7 and RP < 100 then
				if t == p and P.res12 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * (0.1 + math.max(RP/500, 0)) end end)
				elseif c == mp and P.des11 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * (math.min(RP/1000, 0) - 0.1) end end) end
			elseif eid == 51 or eid == 52 then	local koef = 1 - RP/100		local mag = math.random(ef.min, ef.max) * dur		local rad = mag * (P.ill12 and 2 or 1)		-- Френзи
				pow = mag * koef * (P.ill11 and 1.5 or 1)	local minp = 1000 + t.object.level*100
				if P.ill14 then tes3.applyMagicSource{reference = t, name = "Rally", effects = {{id = 117, min = ef.min*koef, max = ef.max*koef, duration = dur}}} end
				if pow > minp then	m.actionData.aiBehaviorState = 3
					if P.ill13 then		for _, mob in pairs(tes3.findActorsInProximity{reference = t, range = rad}) do if mob ~= m then m:startCombat(mob) end end
					else	local tar, dist		local md = rad
						for _, mob in pairs(tes3.findActorsInProximity{reference = t, range = rad}) do if mob ~= m then dist = t.position:distance(mob.position)	if dist < md then md = dist		tar = mob end end end
						if tar then m:startCombat(tar) end
					end
				end
				if cf.m then tes3.messageBox("%s Frenzy! power = %d/%d  rad = %d", t, pow, minp, rad) end
			elseif eid == 49 or eid == 50 then	-- Calm
				pow = math.random(ef.min, ef.max) * (1 - RP/100)	* (P.ill20 and 1.5 or 1)	local minp = math.max(t.object.aiConfig.fight/2 + t.object.level * (P.per10 and 5 or 10), 50)
				if pow > minp then	if R[t] then R[t] = nil		if cf.m4 then tes3.messageBox("CALM! %s", t) end end	else RP = 100 end
				if cf.m then tes3.messageBox("%s Calm! power = %d/%d  basefight = %d", t, pow, minp, t.object.aiConfig.fight) end
			end
		end
	end
else e.resistedPercent = 0	return end -- Любые негативные эффекты с дальностью на себя, включая постоянные и баффо-дебаффы и болезни, будут действовать на 100% силы.
e.resistedPercent = RP
local bid = t.baseObject.id
if L.CID[bid] then
	if bid == "golden saint" or bid == "golden saint_summon" then
		if ME[eid] == 1 and not t.data.retcd then	for _, eff in ipairs(B.aureal.effects) do eff.id = -1 end
			for i, eff in ipairs(s.effects) do if ME[eff.id] == 1 then B.aureal.effects[i].id = eff.id		B.aureal.effects[i].min = eff.min/3		B.aureal.effects[i].max = eff.max/3
				B.aureal.effects[i].radius = 10		B.aureal.effects[i].duration = eff.duration		B.aureal.effects[i].rangeType = 2
			end end
			tes3.applyMagicSource{reference = t, source = B.aureal}	t.data.retcd = true		timer.start{duration = 0.1, callback = function() t.data.retcd = nil end}
		end
	elseif L.CID[bid] == "wolf" and s.id == "BM_summonwolf" then e.resistedPercent = -2000 elseif L.CID[bid] == "bear" and s.id == "BM_summonbear" then e.resistedPercent = -2000 end
end

--timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 
--tes3.messageBox("%s  id = %s  time = %.3f/%d   Respr = %.2f   mag = %d  Cummag = %d", s.name or s.id, eid, ei.timeActive, dur, ei.resistedPercent, ei.magnitude, ei.cumulativeMagnitude) end)
--if m == mp and SSN[sn] then tes3.getMagicSourceInstanceBySerial{serialNumber = sn}.state = 6	tes3.messageBox("Resist! SNum = %s", sn) SSN[sn] = nil end
-- e.effectInstance ещё не полностью построена во время эвента. Далее она меняется на полноценный effectInstance которые НЕ равен предыдущему и может быть получен из активных эффектов
end		event.register("spellResist", SPELLRESIST)


local function MAGICEFFECTREMOVED(e)	--local m, r, c, t, si, s, ei, ind = e.mobile, e.reference, e.caster, e.target, e.sourceInstance, e.source, e.effectInstance, e.effectIndex
local id = e.effect.id
if id == 510 then
	timer.delayOneFrame(L.UpdTSK)
end
--tes3.messageBox("%s - %s (%s)  id = %s (%s)  Mag = %.2f", r, s.id, si.serialNumber, id, ind+1, ei.magnitude * (100 - ei.resistedPercent)/100)
end		event.register("magicEffectRemoved", MAGICEFFECTREMOVED)


local AOE = {}	local RUN = {}	local TOT = {}	-- АОЕ (521-525)	РУНЫ (526-530)		ТОТЕМЫ (551-555)
L.RunExp = function(n) local E = B.RUN.effects		local t = RUN[n]		--tes3.messageBox("Rune %d  exploded  id = %s", n, t.s.effects[1].id)
	for i, ef in ipairs(t.ef) do if ef.id > -1 then E[i].id = ef.id		E[i].min = ef.min	E[i].max = ef.max	E[i].duration = ef.duration		E[i].radius = ef.radius		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.RUN}] = {pos = t.r.position + tes3vector3.new(0,0,50), exp = true}		t.r:delete()	RUN[n] = nil
end
L.TotExp = function(n) local E = B.TOT.effects		local t = TOT[n]
	if t.dur > 9 then	for i, ef in ipairs(t.ef) do if ef.id > -1 then E[i].id = ef.id		E[i].min = ef.min	E[i].max = ef.max	E[i].radius = ef.radius		E[i].duration = 1	E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.TOT}] = {pos = t.r.position:copy(), exp = true} end		t.r:delete()	TOT[n] = nil
end

local function AOEcol(e) local cp = e.collision.point	if math.abs(cp.x) < 9000000 and e.sourceInstance.caster == p then local n	local s = e.sourceInstance.source		local ef = s.effects[e.effectIndex + 1]
local alt = mp:getSkillValue(11)		local koef = L.durbonus(ef.duration - 1, 5) * (SN[e.sourceInstance.serialNumber] or 1)		tes3.getObject(L.AoEmod[ef.id%5]).radius = ef.radius * 50
local r = tes3.createReference{object = L.AoEmod[ef.id%5], position = cp + tes3vector3.new(0,0,10), cell = p.cell, scale = math.min(ef.radius * (P.alt12 and 0.075 + alt/4000 or 0.075), 9.99)}	r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.alt5b and 20 or 40))		for i = 1, max do if not AOE[i] then n = i break end end
if not n then n = 1	local md = AOE[1].tim		for i, t in pairs(AOE) do if t.tim < md then md = t.tim		n = i end end end
if AOE[n] then AOE[n].r:delete()	AOE[n] = nil end
AOE[n] = {r = r, tim = ef.duration, id = MID[ef.id%5], min = ef.min * koef, max = ef.max * koef}
if cf.m10 then  tes3.messageBox("AoE %d/%d  Power = %d%%  Scale = %.2f  Time: %d", n, max, koef*100, AOE[n].r.scale, AOE[n].tim) end
if not T.AoE.timeLeft then local dur = P.alt11 and math.max(2 - alt/200, 1.5) or 2	T.AoE = timer.start{duration = dur, iterations = -1, callback = function() local fin = true		local E = B.AOE.effects[1]
	for i, t in pairs(AOE) do	t.tim = t.tim - dur		if t.tim > 0 then	fin = false		E.id = t.id		E.min = t.min	E.max = t.max	E.duration = 2
		for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = 300 * t.r.scale}) do if m ~= mp then
			SNC[(tes3.applyMagicSource{reference = m.reference, source = B.AOE}).serialNumber] = mp		L.CrimeAt(m)
		end end
	else t.r:delete()	AOE[i] = nil end end		if fin then T.AoE:cancel()	if cf.m10 then tes3.messageBox("All AoE ends") end end
end} end
end end

local function RUNcol(e) if G.RunSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 then	local n		local s = e.sourceInstance.source
local ef = s.effects[e.effectIndex + 1]		G.RunSN = e.sourceInstance.serialNumber		local koef = SN[G.RunSN] or 1	local alt = mp:getSkillValue(11)		local vel = e.sourceInstance.projectile.velocity		
local hit = tes3.rayTest{position = cp - vel:normalized()*100, direction = vel}
local r = tes3.createReference{object = "4nm_rune", position = cp + tes3vector3.new(0,0,5), orientation = hit and L.GetOri(V.up, hit.normal), cell = p.cell, scale = math.min(ef.radius * (P.alt12 and 0.15 + alt/2000 or 0.15), 9.99)}
local light = niPointLight.new()	light:setAttenuationForRadius(ef.radius/2)		light.diffuse = tes3vector3.new(L.LID[ef.id%5][1], L.LID[ef.id%5][2], L.LID[ef.id%5][3])	--tes3vector3.new(ef.object.lightingRed, ef.object.lightingGreen, ef.object.lightingBlue)
r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.alt5c and 10 or 20))		for i = 1, max do if not RUN[i] then n = i break end end
if not n then n = 1	local md = RUN[1].tim		for i, t in pairs(RUN) do if t.tim < md then md = t.tim		n = i end end	L.RunExp(n) end
local E = {{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1}}
for i, ef in ipairs(s.effects) do if ME[ef.id] == "rune" then E[i].id = MID[ef.id%5]	E[i].min = ef.min * koef	E[i].max = ef.max * koef	E[i].duration = ef.duration		E[i].radius = ef.radius end end
RUN[n] = {r = r, ef = E, tim = (100 + alt + mp:getSkillValue(14))*(P.mys20 and 0.4 or 0.2)}
if cf.m10 then  tes3.messageBox("Rune %d/%d  Power = %d%%  Scale = %.2f  Time: %d", n, max, koef*100, RUN[n].r.scale, RUN[n].tim) end
if not T.Run.timeLeft then T.Run = timer.start{duration = 1, iterations = -1, callback = function() local fin = true
	for i, t in pairs(RUN) do	t.tim = t.tim - 1	if t.tim > 0 then	fin = false
		for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = 80 * t.r.scale}) do if m ~= mp then L.RunExp(i)	break end end
	else L.RunExp(i) end end	if fin then T.Run:cancel()	if cf.m10 then tes3.messageBox("All runes ends") end end
end} end
end end end

local function TOTcol(e) if G.TotSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 then	local n		local s = e.sourceInstance.source
local ef = s.effects[e.effectIndex + 1]		local tdur = ef.duration		G.TotSN = e.sourceInstance.serialNumber		local koef = SN[G.TotSN] or 1	local alt = mp:getSkillValue(11)
local r = tes3.createReference{object = "4nm_totem", position = cp + tes3vector3.new(0,0,60*(1 + ef.radius/50)), cell = p.cell, scale = 1 + ef.radius/50}
local light = niPointLight.new()	light:setAttenuationForRadius((1 + ef.radius/50)*3)		light.diffuse = tes3vector3.new(L.LID[ef.id%5][1], L.LID[ef.id%5][2], L.LID[ef.id%5][3])
r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.alt5d and 20 or 40))		for i = 1, max do if not TOT[i] then n = i break end end
if not n then n = 1	local md = TOT[1].tim		for i, t in pairs(TOT) do if t.tim < md then md = t.tim		n = i end end	L.TotExp(n) end
local E = {{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1}}		mc = 0
for i, ef in ipairs(s.effects) do if ME[ef.id] == "totem" and tdur <= ef.duration then E[i].id = MID[ef.id%5]	E[i].min = ef.min * koef	E[i].max = ef.max * koef	E[i].radius = ef.radius
mc = mc + (E[i].min + E[i].max)	* L.MEC[ef.id%5] * (P.mys7f and 0.04 or 0.05) * (1+E[i].radius^2/(10*E[i].radius+200)) end end
TOT[n] = {r = r, ef = E, tim = tdur, dur = tdur, mc = mc}
if cf.m10 then  tes3.messageBox("Totem %d/%d  Power = %d%%  Cost = %.1f  Scale = %.2f  Time: %d", n, max, koef*100, TOT[n].mc, TOT[n].r.scale, TOT[n].tim) end
if not T.Tot.timeLeft then local dur = P.alt11 and math.max(2 - alt/200, 1.5) or 2		T.Tot = timer.start{duration = dur, iterations = -1, callback = function()	local BE = B.TOT.effects
	local fin = true	local maxdist = (100 + mp.intelligence.current + alt + mp:getSkillValue(14)) * (P.alt12 and 20 or 10)		local tar, pos, fpos, mindist, dist
	for i, t in pairs(TOT) do	t.tim = t.tim - dur		if t.tim > 0 then	fin = false
		if not D.Totdis and AC[t.r.cell] and mp.magicka.current > t.mc then fpos = nil	mindist = maxdist
			for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = maxdist}) do if m ~= mp and (cf.agr or m.actionData.target == mp) and tes3.getCurrentAIPackageId(m) ~= 3 then 
				pos = m.position + tes3vector3.new(0,0,m.height/2)		dist = t.r.position:distance(pos)
				if dist < mindist and tes3.testLineOfSight{position1 = t.r.position, position2 = pos} then mindist = dist	tar = m		fpos = pos end
			end end
			if fpos then
				for i, ef in ipairs(t.ef) do if ef.id > -1 then BE[i].id = ef.id	BE[i].min = ef.min		BE[i].max = ef.max		BE[i].radius = ef.radius	BE[i].duration = 1	BE[i].rangeType = 2
				else BE[i].id = -1	BE[i].rangeType = 0 end end
				MP[tes3.applyMagicSource{reference = p, source = B.TOT}] = {pos = t.r.position:copy(), vel = (fpos - t.r.position):normalized()}
				Mod(t.mc)		if cf.m10 then tes3.messageBox("Totem %s   Target = %s   Manacost = %.1f", i, tar.object.name, t.mc) end
			end
		end
	else L.TotExp(i) end end	if fin then T.Tot:cancel()	if cf.m10 then tes3.messageBox("All totems ends") end end
end} end
end end end

local function WAVcol(e) if G.WavSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 and e.sourceInstance.caster == p then
	G.WavSN = e.sourceInstance.serialNumber		local pr = e.sourceInstance.projectile		local t = CPR[pr.reference]	--local n	local s = e.sourceInstance.source		local ef = s.effects[e.effectIndex + 1]
	for i, ef in ipairs(t.ef) do if ME[ef.id] == "wave" then G.WAV[i].id = MID[ef.id%5]		G.WAV[i].min = ef.min*t.k*(1-(t.num-1)/t.max)		G.WAV[i].max = ef.max*t.k*(1-(t.num-1)/t.max)
	G.WAV[i].radius = ef.radius + t.num/(P.alt12 and 1 or 2)		G.WAV[i].duration = ef.duration		G.WAV[i].rangeType = 2	else G.WAV[i].id = -1	G.WAV[i].rangeType = 0 end end			
	MP[tes3.applyMagicSource{reference = p, source = B.WAV}] = {pos = cp - pr.velocity:normalized()*100, exp = true}
end end end


--L.Dash = function(e) p.sceneNode.velocity = V.d		V.dfr = V.dfr + 1	if V.dfr == 7 then event.unregister("simulate", L.Dash)	V.dfr = nil end end
L.Dash = function(e) if e.reference == p then	if V.djf then	mp.isJumping = true end			mp.impulseVelocity = V.d*(1/wc.deltaTime)*TSK	V.dfr = V.dfr - TSK
if V.dfr <= 0 then event.unregister("calcMoveSpeed", L.Dash)	V.dfr = nil
	if V.djf then V.djf = nil	mp.isJumping = false end
	if V.daf then mp.animationController.weaponSpeed = V.daf	V.daf = nil end
	if V.dkik then V.dkik = nil		L.KIK() end
end
end end

L.BLAST = function(e)	local r = e.reference	if KSR[r] then e.mobile.impulseVelocity = KSR[r].v*(1/wc.deltaTime) * math.clamp(KSR[r].f/30,0.2,1)*TSK	KSR[r].f = KSR[r].f - TSK	e.speed = 0 --KSR[r].v.z = KSR[r].v.z - 0.04
if KSR[r].f <= 0 then KSR[r] = nil 	if table.size(KSR) == 0 then event.unregister("calcMoveSpeed", L.BLAST)		V.bcd = nil end end end end

L.KIK = function() if mp.hasFreeAction and mp.paralyze < 1 then	local climb, foot, r, m		local dist = 1000	local maxd = 50 + math.min(mp.agility.current/2, 50)
local ClAb = mp.velocity:length()~=0 and not V.dfr		local cldist = maxd + (P.acr9 and 20 or 0)		local kikdist = maxd + (P.hand11 and 20 or 0)

local vdir = tes3.getPlayerEyeVector()		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vdir, maxDistance = 130, ignore={p}}
if hit then dist = hit.distance 	r = hit.reference	m = N[r] and N[r].m		maxd = m and kikdist or (ClAb and cldist) or 0 end

if dist > maxd then foot = true
	hit = tes3.rayTest{position = pp + tes3vector3.new(0,0,5), direction = p3.rotation:transpose().y, maxDistance = 130, ignore={p}}	--tes3.messageBox("ref = %s", hit and hit.reference)
	if hit then dist = hit.distance 	r = hit.reference	m = N[r] and N[r].m		maxd = m and kikdist or cldist end
	if dist > maxd then hit = mp.isMovingLeft and 1 or (mp.isMovingRight and -1)		if hit then vdir = p3.rotation:transpose().x * hit
		hit = tes3.rayTest{position = pp + tes3vector3.new(0,0,5), direction = vdir, ignore={p}}
		if hit then dist = hit.distance 	r = hit.reference	m = N[r] and N[r].m		maxd = m and kikdist or cldist end
	end end
end

if dist > maxd then maxd = kikdist	local md = kikdist + 10
	for _, mob in pairs(tes3.findActorsInProximity{reference = p, range = 150}) do
	if mob ~= mp and mob.playerDistance < md and math.abs(mp:getViewToActor(mob)) < (P.hand21 and 100 or 45) and (cf.agr or mob.actionData.target == mp) then md = mob.playerDistance		m = mob end end
	if m then dist = md		r = m.reference		vdir = (r.position - pp):normalized() end
end
	

if dist <= maxd then
if ClAb then	local s = mp:getSkillValue(20)		local stc = math.max(20 + mp.encumbrance.normalized*(P.atl6 and (30 - mp:getSkillValue(8)/10) or 30) - (P.acr11 and s/10 or 0), 10)
	if mp.fatigue.current > stc then local ang = 0
		if mp.isMovingForward then if foot then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end else V.d = V.up end
		elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
		elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 else V.d = V.up end
		if V.d ~= V.up then Matr:toRotationZ(math.rad(ang))		V.d = Matr * tes3.getPlayerEyeVector()
			if mp.isMovingBack then V.d = V.d*-1 elseif ang == 90 or ang == 270 then V.d.x = V.d.x/(1 - V.d.z^2)^0.5		V.d.y = V.d.y/(1 - V.d.z^2)^0.5 end		V.d.z = 1
		end
		local imp = math.min(100 + mp.strength.current/2 + s/2, 200) * (P.acr12 and 1 or 0.75) * (0.5 + math.min(mp.fatigue.normalized,1)/2)		if P.acr10 then mp.velocity = V.nul end		mp.isSwimming = false
		V.d = V.d * (imp/8)		V.dfr = 8	event.register("calcMoveSpeed", L.Dash)		mp.fatigue.current = mp.fatigue.current - stc		mp:exerciseSkill(20,0.2)
		climb = true	tes3.playSound{sound = math.random(2) == 1 and "LeftS" or "LeftM"}
		if cf.m then tes3.messageBox("Climb-jump! impuls = %d  dist = %d   cost = %d", imp, dist, stc) end
	end
end
if not T.Kik.timeLeft and m then	local s = mp:getSkillValue(26)		local bot = mp:getBootsWeight()
	local sc = math.max(30 + (bot + mp.encumbrance.normalized*20)*(P.atl6 and (1 - mp:getSkillValue(8)/200) or 1) - (P.end20 and 10 or 0) - (P.hand14 and s/10 or 0), 10) - (climb and 10 or 0)
	if mp.fatigue.current > sc then	local arm = m.armorRating		local fat = 1 - math.min(mp.fatigue.normalized,1)	 	if not climb then vdir.z = math.min(vdir.z + 0.3, 1) end
		local cd = math.max((P.spd12 and 1.5 or 2) - mp.speed.current/100 + math.max(D.AR.as + mp.encumbrance.normalized * (P.atl12 and 0.1 or 0.2) - math.max(-mp.encumbrance.currentRaw,0)/2000, 0)*2
		+ fat * (P.atl11 and 0.2 or 0.5), (P.hand15 and 0.5 or 1))
		T.Kik = timer.start{duration = cd, callback = function() end}
		local Kskill = s * ((P.hand1 and 0.2 or 0.1) + (P.str2 and 0.1 or 0.05))		local Kbonus = mp.attackBonus/5		local Kstr = mp.strength.current/(P.str1 and 1 or 2)
		local Kdash = (T.Dash.timeLeft or 0) > 2 and V.dd/(P.str9 and 50 or 100) or 0		local ko = L.AG[m.actionData.currentAnimationGroup]
		local Kstam = (50 + (P.end1 and 0 or 10) + (P.hand2 and 0 or 20)) * fat
		local CritC = Kbonus + s/(P.hand6 and 10 or 20) + mp.agility.current/(P.agi1 and 10 or 20) + (P.luc1 and mp.luck.current/20 or 0) + (mp.isMovingForward and P.spd3 and 10 or 0) + (m.isMovingForward and 10 or 0)
		+ (math.min(com, G.maxcomb) * (P.agi6 and 5 or 3)) + (mp.isJumping and P.acr4 and mp:getSkillValue(20)/10 or 0)
		- (m.endurance.current + m.agility.current + m.luck.current)/20 - arm/10 - m.sanctuary/10 + math.max(1-m.fatigue.normalized,0)*(P.agi11 and 20 or 10) - 10
		local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + (P.agi8 and 10 or 0) + (P.hand5 and 20 or 0) end
		local Koef = 100 + Kstr + Kskill + Kdash + Kbonus + Kcrit - Kstam
		local DMag = math.min(tes3.getEffectMagnitude{reference = p, effect = 600}, cf.moment)	local mc = 0	local Kkin = 0
		if DMag > 0 then mc = DMag * (P.alt17 and 0.5 or 1)		if mp.magicka.current > mc then Kkin = DMag * (Cpow(mp,0,4,true) + (P.alt16 and 50 or 0))/200 	Mod(mc) end end
		local dmg = (((P.hand19 and 4 or 2) + (P.hand13 and bot*(s/500) or 0)) * Koef/100 + Kkin) * (ko and 1.5 + (P.str14 and 0.5 or 0) or 1)	--local fdmg = dmg*dmg/(arm + dmg)
		local sdmg = (P.hand16 and 10 or 5) * Koef/100		if m.fatigue.current > 0 then m.fatigue.current = m.fatigue.current - sdmg end
		local fdmg = m:applyDamage{damage = dmg, applyArmor = true, resistAttribute = 12, playerAttack = true}	L.CrimeAt(m)

		if T.Comb.timeLeft then T.Comb:reset() end		mp.fatigue.current = mp.fatigue.current - sc
		L.skw = math.max((m.object.level * 4 + 20 - p.object.level/2) / (m.object.level + 20) * (fdmg+sdmg)/30, 0)		mp:exerciseSkill(26, 1)
		local mass = math.max(m.height, 60)^2 * ((m.actorType == 1 or m.object.biped) and 0.5 or 0.8) * (100 + arm/2)/5000
		local imp = math.min((100 - Kstam + Kstr + Kdash*2.5 + Kkin*20 - m.endurance.current) * 1000/mass, 10000)		local max = imp
		if imp > 100 then	if not V.bcd then event.register("calcMoveSpeed", L.BLAST)	V.bcd = 0 end	local min = 3000 + math.min(vdir.z, 0)*2000
			if imp > min then	local hit2 = tes3.rayTest{position = r.position + tes3vector3.new(0, 0, m.height/2) - vdir*30, direction = vdir, ignore={tes3.game.worldPickRoot}}
			if hit2 and hit2.reference then imp = math.clamp(hit2.distance*4, min, imp) end end
			tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}		KSR[r] = {v = vdir * (imp/30), f = 30}
		end
		if cf.m then tes3.messageBox([[Kick! dmg = %d (%d / %d arm) + %d stam  K = %d%% (+%d%% str +%d%% skill +%d%% atb -%d%% stam +%d%% crit (%d%%) +%d%% dash +%d kin) 
		impuls = %d (%d)  mass = %d  dist = %d  cd = %.1f  cost = %d + %d  Z = %.2f  %s]],
		fdmg, dmg, arm, sdmg, Koef, Kstr, Kskill, Kbonus, Kstam, Kcrit, CritC, Kdash, Kkin, imp, max, mass, dist, cd, sc, mc, vdir.z, ko and "KO!" or "") end
	end
end
end
end end

L.KBlast = function(pos, rad, dam) local dist, r, mass, pow, max, min, KO, dmg, vdir, rp		--local maxpow = p.cell.isInterior and not p.cell.behavesAsExterior and 8000 or 15000
for _, m in pairs(tes3.findActorsInProximity{position = pos, range = rad}) do if m ~= mp then r = m.reference	rp = (r.position + tes3vector3.new(0, 0, m.height*0.8))		dist = pos:distance(rp)
	mass = math.max(m.height, 60)^2 * ((m.actorType == 1 or m.object.biped) and 0.5 or 0.8) * (100 + m.armorRating/2)/5000		
	pow = math.min((rad - dist) * 400 / mass, 15000)		max = pow			KO = pow/40 - m.agility.current
	if pow > 100 then	vdir = (rp - pos):normalized()		tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}		min = 3000 + math.min(vdir.z, 0)*2000
		if pow > min then local hit = tes3.rayTest{position = rp - vdir*30, direction = vdir, ignore={tes3.game.worldPickRoot}}
		if hit and hit.reference then pow = math.clamp(hit.distance*4, min, pow) end end
		KSR[r] = {v = vdir * (pow/30), f = (KSR[r] and KSR[r].f/2 or 0) + 30}	if not V.bcd then event.register("calcMoveSpeed", L.BLAST)	V.bcd = 0 end
		if KO > math.random(100) then tes3.applyMagicSource{reference = r, name = "KO", effects = {{id = 20, min = 3000, max = 3000, duration = 1}}} end
	end
	if dam then dmg = m:applyDamage{damage = dam*(rad - dist)/rad, applyArmor = true, playerAttack = true}	L.CrimeAt(m) end
	if cf.m then tes3.messageBox("Blast! %s  Impuls = %d (%d = %d - %d) Mass = %d  Dmg = %d  KO chance = %d%%", r.object.name, pow, max, rad, dist, mass, dmg or 0, KO) end	--m.actionData.animationAttackState = 15
end end
end

local function KSCollision(e) local dist, dam, pow, r, mass, arm, KO
local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	local koef = Cpow(mp,0,2)/100 * (SN[e.sourceInstance.serialNumber] or 1)
local rad = (ef.radius + L.GetRad(mp)) * math.random(ef.min, ef.max) * koef
local dam = math.random(ef.min, ef.max) * koef
L.KBlast(e.collision.point, rad, dam)
end

L.runTeleport = function(pos)	local TPdist = pp:distance(pos)		local TPmdist = (100 + mp.intelligence.current + mp:getSkillValue(11) + mp:getSkillValue(14)) * 20		if TPdist > 200 then
	if TPdist > TPmdist then  pos = pp:interpolate(pos, TPmdist)		TPdist = TPmdist end	mc = (20 + TPdist/50) * (P.mys7a and 1 or 1.5)
	if mc < mp.magicka.current then 
		Mod(mc)		tes3.playSound{sound = "Spell Failure Destruction"}		p.position = pos	--mp.isSwimming = true	--tes3.positionCell{reference = p, position = pos, cell = p.cell}		
		tes3.applyMagicSource{reference = p, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}
		if cf.m then tes3.messageBox("Distance = %d  Manacost = %.1f", TPdist, mc) end
	end
end end
local function TeleportCollision(e) if e.sourceInstance.caster == p then L.runTeleport(e.collision.point - e.sourceInstance.projectile.velocity:normalized()*70) end end


local function SPELLMAGICKAUSE(e) 	if e.caster == p then local sp = e.spell	if not sp.alwaysSucceeds then	local sc = sp:getLeastProficientSchool(mp)
	G.MCKoef = (G.LastQS == sp and not P.int11 and 1.2 or 1) - (P.int15 and math.max((0.5 - mp.magicka.normalized)*0.1, 0) or 0)
	- mp:getSkillValue(SP[sc].s)/(P[SP[sc].p4] and 1000 or 2000) - (P.mys10 and 0.05 or 0) + (D.AR.mc > 0 and math.max(D.AR.mc - math.max(-mp.encumbrance.currentRaw,0)/2000, 0) or D.AR.mc)
	e.cost = e.cost * math.max(G.MCKoef, 0.5)
	--if G.LastQS == sp then G.LastQsn = e.instance.serialNumber end
	--tes3.messageBox("%s  Cost = %d (%d base)  School = %s", sp.name, e.cost, sp.magickaCost, sc)
end if mp.magicka.current < e.cost then G.LastQS = nil end
elseif e.spell.castType == 5 then e.caster.mobile.actionData.animationAttackState = 11
	--tes3.playAnimation{reference = e.caster, group = 0x0, loopCount = 0}		e.caster.mobile.actionData.animationAttackState = 0
end end		event.register("spellMagickaUse", SPELLMAGICKAUSE)

local function SPELLCAST(e)	local sp = e.source		local c = e.caster		if sp.castType == 0 or sp.castType == 5 then	if c == p then	local extra = 0		local cost = sp.magickaCost		local sc = e.weakestSchool
if G.LastQS == sp then ad.animationAttackState = 0	--mp.animationController.weaponSpeed = 1000000
	--if mp.weaponDrawn then L.WComb(ad.attackDirection, not mp.readiedWeapon and 0 or mp.readiedWeapon.object.isOneHanded) end
	--if ad.animationAttackState == 2 then ad.animationAttackState = 0 	MB[1] = 0 end
	if not P.int2 then extra = cost end		for i, ef in ipairs(sp.effects) do if ef.id ~= -1 then tes3.removeSound{sound = ef.object.castSoundEffect, reference = p} end end
else
	if P.spd6 then if mp.speed.current > 99 then 
		if ad.animationAttackState == 11 then if ic:keybindTest(tes3.keybind.readyMagic) then timer.start{duration = 0.1, callback = function() ad.animationAttackState = 0 end} else ad.animationAttackState = 0 end end
	else timer.start{duration = math.clamp((100 - mp.speed.current)/100, 0.01, 0.99), callback = function()
		if ad.animationAttackState == 11 then if ic:keybindTest(tes3.keybind.readyMagic) then timer.start{duration = 0.1, callback = function() ad.animationAttackState = 0 end} else ad.animationAttackState = 0 end end
	end} end end
end
if sc < 6 then local s = mp:getSkillValue(SP[sc].s)
	local stam = math.min(cost * (G.MCKoef or 1) * math.min((P.end16 and 0.25 or 0) + (P.una9 and D.AR.u * 0.01 or 0), 0.5), mp.fatigue.base - mp.fatigue.current)
	if stam > 0 then mp.fatigue.current = mp.fatigue.current + stam end
	e.castChance = e.castChance + (P[SP[sc].p2] and s/5 or 0) + (P.int6 and mp.intelligence.current/10 or 0) + (P.luc13 and mp.luck.current/10 or 0) + (P.int8 and mp.spellReadied and (mp.intelligence.current + s)/10 or 0)
	+ (D.AR.cc > 0 and D.AR.cc or math.min(D.AR.cc + math.max(-mp.encumbrance.currentRaw,0)/1000, 0)) - mp.encumbrance.normalized * (P.end17 and 10 or 20) - (P.wil10 and 0 or M.MCB.normalized*20) - extra
	if cf.m10 then tes3.messageBox("Spellcast! School = %s  chance = %.1f   stam + %.1f", sc, e.castChance, stam) end
end		
elseif (c.mobile.actorType == 1 or c.object.biped) then c.mobile.actionData.animationAttackState = 0
end end end		event.register("spellCast", SPELLCAST)


--[[local function SPELLCASTED(e) if e.caster == p and e.expGainSchool < 6 then
	local sc = e.expGainSchool		tes3.messageBox("CAST! School = %s   cost = %s", sc, e.source.magickaCost)
end end		event.register("spellCasted", SPELLCASTED)	--]]
local function SPELLCASTEDFAILURE(e) if e.caster == p and e.expGainSchool < 6 then M.MCB.current = 0	G.LastQS = nil
	if P.int7 then tes3.modStatistic{reference = p, name = "magicka", current = e.source.magickaCost * math.min((mp.intelligence.current + mp:getSkillValue(SP[e.expGainSchool].s))/500,0.5)} end
end end		event.register("spellCastedFailure", SPELLCASTEDFAILURE)


local function ENCHANTCHARGEUSE(e)	if e.isCast and e.caster == p then	local en = e.source		local cost = en.chargeCost		L.skmag = cost * 5 / (cost + 80)
	if en.castType == 1 then e.charge = D.NoEnStrike and 50000 or cost * math.max(1 - mp:getSkillValue(9)*((P.enc8 and 0.002 or 0.001) + (P.enc19 and 0.003 or 0.001)), 0.5)
		--if W.ob and W.v.charge < e.charge then timer.delayOneFrame(function() tes3.removeSound{sound = en.effects[1].object.spellFailureSoundEffect, reference = p} end) end
	elseif en.castType == 2 then e.charge = cost * (math.max(1 - mp:getSkillValue(9)*(P.enc8 and 0.002 or 0.001), 0.8) + M.MCB.normalized*(P.enc20 and 0.4 or 0.2)*(P.enc21 and 0.5 or 1)) end
	if cf.m10 then tes3.messageBox("En cast! %s  Cost = %d (%d base)", en.id, e.charge, cost) end
end end		event.register("enchantChargeUse", ENCHANTCHARGEUSE)


L.RaySim = function() if L.KEY(G.ck) and mp.magicka.current > G.rayc then	G.raysim = G.raysim + wc.deltaTime
	if G.raysim > G.raydt then G.raysim = G.raysim - G.raydt	tes3.applyMagicSource{reference = p, source = B.RAY}		Mod(MB[cf.mbray] == 128 ~= cf.ray and G.rayc or G.sprc) end
else event.unregister("simulate", L.RaySim)	G.raysim = nil end end


local function MAGICCASTED(e) if e.caster == p then	local s = e.source	local si = e.sourceInstance		local sn = si.serialNumber		if not s.effects then tes3.messageBox("id = %s   name = %s   sn = %s", s.id, s.name, sn) end
local id1 = s.effects[1].id		local cost	local n = s.name	local MC = M.MCB.normalized
local KF = 1		local ct = s.castType
local Focus = P.wil5 and mp.spellReadied and mp.magicka.current/(100 + mp.magicka.current/10)/100 or 0
if s.effects[1].rangeType == 2 and not MP[si] then
	if P.alt18 and MB[cf.mbhev] == 128 and n ~= "4b_RAY" then V.BAL[sn] = 1 + MC		KF = KF + 0.05
	elseif DM.cp == 3 and (P.mys18 and T.MCT.timeLeft or tes3.isAffectedBy{reference = p, effect = 506}) and mp.magicka.current > 10 then
		if n == "4b_RAY" then	if cf.raycon then MP[si] = {pos = L.Hitp(0), exp = true}		Mod(P.mys7 and 2 or 4) end
		else MP[si] = {pos = L.Hitp(0), exp = true}		Mod(P.mys7 and 4 or 8) end
	end
end

if s.objectType == tes3.objectType.spell and ct == 0 then cost = s.magickaCost		local mc = 0	KF = KF + Focus
	local Kstam = math.min(math.lerp((P.wil2 and 0.4 or 0.3) + (P[SP[s:getLeastProficientSchool(mp)].p3] and 0.2 or 0), 1, mp.fatigue.normalized*1.1), 1)
	local char = MC*(P.wil7 and 0.2 or 0.1)		if char > 0 then mc = cost * char * (P.int14 and 0.5 or 1)		if mp.magicka.current > mc then Mod(mc) else char = 0 end end
	if G.LastQS == s then KF = (KF + (P.int13 and char or 0)) * math.clamp(M.QB.normalized*(P.wil13 and 2 or 1.25), 0.2, 1)	G.LastQS = nil		--if ad.animationAttackState == 2 then ad.animationAttackState = 0 end
	elseif char > 0 then KF = KF + char end
	M.MCB.current = 0		KF = KF * Kstam			L.skmag = cost * 5 / (cost + 80)
	if cf.m10 then tes3.messageBox("%s  Spell power = %d%%   %d%% stam   Charge = %d%% (%.1f cost)", n, KF*100, Kstam*100, char*100, mc) end
elseif s.objectType == tes3.objectType.enchantment and ct < 3 then cost = s.chargeCost		KF = KF + Focus
	local Kstam = math.min(math.lerp((P.wil2 and 0.4 or 0.3) + (P.enc5 and 0.2 or 0), 1, mp.fatigue.normalized*1.1), 1)
	if (ct == 1 and si.item.type < 11) or ct == 2 then	local PCcost = cost - M.PC.max/(P.enc11 and 100 or 200)		G.REI = {}
		if MC > 0 then KF = KF + MC*(P.enc20 and 0.2 or 0.1)		M.MCB.current = 0 end
		if PCcost > 0 then	if M.PC.normalized < (P.enc10 and 0.5 or 0.8) then KF = KF * math.max(P.enc2 and 0.1 or 0.03, M.PC.normalized*(P.enc10 and 2 or 1.25), 1-PCcost/(M.PC.max/100)) end
			M.PC.current = math.max(M.PC.current - PCcost, 0)	M.Bar4.visible = true	D.PCcur = M.PC.current		if not T.PCT.timeLeft then T.PCT:reset() end
		end
		KF = KF * Kstam
		if cf.m10 then tes3.messageBox("%s  Enc power = %d%%  %d%% stam  Potencial charge cost = %.1f (%.1f base)  Limit = %d/%d", s.id, KF*100, Kstam*100, PCcost, cost, M.PC.current, M.PC.max) end
	elseif ct == 0 then KF = (KF + (P.enc17 and M.PC.normalized/10 or 0)) * Kstam
		if cf.m10 then tes3.messageBox("%s  Scroll power = %d%%  %d%% stam", s.id, KF*100, Kstam*100) end
	end
elseif n == "4b_RAY" then	KF = KF + Focus		if T.MCT.timeLeft then KF = KF + MC*(P.wil7 and 0.2 or 0.1)		M.MCB.current = math.max(M.MCB.current - (P.mys19 and 0.5 or 1), 0) end
end
if KF ~= 1 then SN[sn] = KF end

if ME[id1] == "shotgun" then	local E = B.SG.effects		local num = (P.alt6 and 4 or 3) + math.min(math.floor(mp:getSkillValue(11)/200 + mp.intelligence.current/200), 1)
	if P.alt18 and MB[cf.mbhev] == 128 then KF = KF * 1.05		G.SGMod = 5
	elseif (DM.cp == 3 or DM.cp == 4) and (P.mys18 and T.MCT.timeLeft or tes3.isAffectedBy{reference = p, effect = 506}) and mp.magicka.current > 16 then
		if DM.cp == 3 then Mod(P.mys7 and 5 or 10)	G.SGMod = 3
		elseif DM.cp == 4 then if DM.cpm then Mod(P.mys7 and 8 or 16) else Mod(P.mys7 and 6 or 12) end		G.SGMod = 4 end
	else G.SGMod = nil end

	for i, ef in ipairs(s.effects) do if ME[ef.id] == "shotgun" then E[i].id = MID[ef.id%5]	E[i].min = ef.min*KF	E[i].max = ef.max*KF		E[i].radius = ef.radius		E[i].duration = ef.duration		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	G.ShotGunDiv = 1 - math.min(mp.agility.current + mp:getSkillValue(23),200)/(P.mark11 and 300 or 400)
	local v1 = p3.rotation:transpose().y * 16		local v2 = p3.rotation:transpose().x * 16		local pos1 = pp + tes3vector3.new(0,0,mp.height/2)
	local d4, d5		if num == 5 then d4, d5 = true, true elseif num == 4 then d4 = table.choice{true,false}		d5 = not d4 end
	MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1, vel = L.GetSGVec(-20,20)} or {pos = L.Hitpr(pos1, L.GetSGVec(-20,20),0), exp = true}
	MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 + v1 + v2, vel = L.GetSGVec(20,60)} or {pos = L.Hitpr(pos1 + v1 + v2, L.GetSGVec(20,60),0), exp = true}
	MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 + v1 - v2, vel = L.GetSGVec(-60,-20)} or {pos = L.Hitpr(pos1 + v1 - v2, L.GetSGVec(-60,-20),0), exp = true}
	if d4 then MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 - v1 + v2, vel = L.GetSGVec(60,120)} or {pos = L.Hitpr(pos1 - v1 + v2, L.GetSGVec(60,120),0), exp = true} end
	if d5 then MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 - v1 - v2, vel = L.GetSGVec(-120,-60)} or {pos = L.Hitpr(pos1 - v1 - v2, L.GetSGVec(-120,-60),0), exp = true} end
	if cf.m10 then tes3.messageBox("Shotgun cast! %s   Koef = %.2f  Balls = %d  Div = %d%%   Mode = %s", n or s.id, KF, num, G.ShotGunDiv*100, G.SGMod or 0) end
elseif ME[id1] == "ray" and not s.weight then	G.rayc = cost * (P.mys7b and 0.1 or 0.12) 	G.sprc = cost * (P.mys7b and 0.075 or 0.09)
	local k = math.min(KF, 1)		local E = B.RAY.effects		local num = (P.alt7 and 20 or 15) + math.min(math.floor(mp:getSkillValue(11)/20 + mp.intelligence.current/20), 10)
	for i, ef in ipairs(s.effects) do if ME[ef.id] == "ray" then E[i].id = MID[ef.id%5]		E[i].min = ef.min*k		E[i].max = ef.max*k		E[i].radius = ef.radius		E[i].duration = ef.duration		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	if not G.raysim then event.register("simulate", L.RaySim)		G.raydt = 1/num		G.raysim = G.raydt end
	if cf.m10 then tes3.messageBox("Ray cast! %s   Koef = %.2f   Cost = %.2f / %.2f  Balls = %d", n or s.id, k, G.rayc, G.sprc, num) end
elseif ME[id1] == "discharge" then	local E = B.DC.effects		local rad = L.GetRad(mp)/2		-- Разряд. Эффекты 541, 542, 543, 544, 545
	for i, ef in ipairs(s.effects) do if ME[ef.id] == "discharge" then E[i].id = MID[ef.id%5]	E[i].min = ef.min*KF	E[i].max = ef.max*KF	E[i].radius = rad+ef.radius		E[i].duration =	ef.duration		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.DC}] = {pos = pp + tes3vector3.new(0,0,10), exp = true}
--elseif ME[id1] == "wave" then
end
end end		event.register("magicCasted", MAGICCASTED)


local function MCStart(e) if e.button == 0 then M.MCB.current = 0 	T.MCT:cancel()	G.arm1.appCulled = true	G.arm2.appCulled = true	event.unregister("mouseButtonUp", MCStart) end
if cf.mcs then tes3.removeSound{sound = "destruction bolt", reference = p} end end

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
		if MB[cf.mbarc] == 128 and mp.fatigue.current > 10 then mp.fatigue.current = mp.fatigue.current - dt * (P.atl4 and 10 or 20)	dt = -dt end	G.artim = math.clamp((G.artim or 0) + dt,0,4)
		if G.artim > 0 then	local MS = ic.mouseState
			local x = (5 + mp.readiedWeapon.object.weight/4) * (1 - (math.min(mp.strength.current + mp.agility.current + mp:getSkillValue(23),300)/(P.mark12 and 400 or 600))) * G.artim/4
			MS.x = MS.x + math.random(-2*x,2*x)		MS.y = MS.y + math.random(-x,x)
		end
	else G.artim = nil end
else event.unregister("simulate", L.ArcSim)	G.artim = nil	if G.arcf then G.arcf = nil		mp.animationController.weaponSpeed = G.arcspd end end end

L.MetSim = function(e) if mp.weaponDrawn and MB[1] == 128 and G.met < G.metmax then	local AS = ad.animationAttackState
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

L.MetSim1 = function(e) if mp.weaponDrawn and MB[1] == 128 then	local AS = ad.animationAttackState
if G.met > 0 then
	if G.met == 1 then
	else
		if AS == 2 then
			if ad.nockedProjectile and G.met < 5 then	ad.attackSwing = 0.8		ad.animationAttackState = 4		G.met = G.met + 1		--if G.met == 0 then mp.animationController.weaponSpeed = 1000000	end
				mp.animationController.weaponSpeed = 0.0001
			else	event.unregister("simulate", L.MetSim)		G.met = nil		mp.animationController.weaponSpeed = G.arcspd 	--MB[1] = 0	
			end
		elseif AS == 4 then		mp.animationController.weaponSpeed = G.met == 1 and 1000000 or G.arcspd
		elseif AS == 5 then		
			if ad.nockedProjectile then ad.animationAttackState = 0 else mp.animationController.weaponSpeed = 1000000
			end
		end
	end
	if G.met then tes3.messageBox("%s   AS = %s --> %s   %s    Swing = %d", G.met, AS, ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, ad.attackSwing*100) end
end
else event.unregister("simulate", L.MetSim)		G.met = nil		mp.animationController.weaponSpeed = G.arcspd end end

L.ARBSIM = function(e) if not tes3ui.menuMode() and mp.weaponDrawn and MB[3] == 128 then
--	if G.arbf then if ad.animationAttackState == 2 then G.arbf = nil else return end end
--	if ad.animationAttackState == 2 then MB[1] = 0		ad.animationAttackState = 0		G.arbf = true end
	--mp.animationController.weaponSpeed = 0.5
	if ad.animationAttackState == 5 then 	--mp.animationController.weaponSpeed = 0.0001
		ad.animationAttackState = 0		tes3.messageBox("AS = 5 ---> %s   %s   %s", ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, mp.readiedAmmoCount)
		--MB[1] = 0		tes3.messageBox("AS = 5 ---> %s", ad.animationAttackState)
	elseif ad.animationAttackState == 2	then 	--MB[1] = 0		tes3.messageBox("AS = %s   MOUSE = 0", ad.animationAttackState)
		
		--if not ad.nockedProjectile then ad.nockedProjectile = G.PR end
		
		--mp.animationController.weaponSpeed = 0.0001
		ad.animationAttackState = 4		tes3.messageBox("AS = 2 ---> %s   %s   %s", ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, mp.readiedAmmoCount)
--	elseif ad.animationAttackState == 4	then		ad.animationAttackState = 2		tes3.messageBox("AS = 4 ---> %s", ad.animationAttackState)
--	elseif ad.animationAttackState == 0	then		ad.animationAttackState = 2		tes3.messageBox("AS = 0 ---> %s", ad.animationAttackState)
--	else tes3.messageBox("AS = %s  ", ad.animationAttackState)
	end
end end		--event.register("simulate", L.ARBSIM)


L.AS = {[0]=2, [2]=2, [3]=0, [4]=0, [5]=1, [6]=1, [7]=1}	L.ASAR = {[4]=1, [5]=1, [6]=1, [7]=1}
L.Swap = function(w, wd) if (mp.isMovingLeft or mp.isMovingRight) and not (mp.isMovingForward or mp.isMovingBack) then
	if w == W.WR and wd == W.DR then
		if inv:contains(W.WL, W.DL) and W.DL.condition > 0 then
			ad.animationAttackState = 0		ad.attackDirection = 0			if W.Wsim then event.unregister("simulate", L.WSim)	W.Wsim = nil end
			W.snd = 1	mp:equip{item = W.WL, itemData = W.DL}
		else L.DWMOD(false) W.WL = nil W.DL = nil end
	end
else
	if w == W.WL and wd == W.DL then
		if inv:contains(W.WR, W.DR) and W.DR.condition > 0 then
			if mp.isRunning or mp.isWalking then MB[1] = 0 end	ad.animationAttackState = 0		if W.Wsim then event.unregister("simulate", L.WSim)	W.Wsim = nil end
			W.snd = 1	mp:equip{item = W.WR, itemData = W.DR}
		else L.DWMOD(false) W.WR = nil W.DR = nil end
	end
end end
L.DWSim = function(e) if W.DWM and mp.weaponDrawn and MB[1] == 128 then
	if L.AS[ad.animationAttackState] == 2 or (L.AS[ad.animationAttackState] == 1 and ad.attackSwing >= W.DWlim) then
		local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object		L.Swap(w, wd)	event.unregister("simulate", L.DWSim)		W.DWsim = nil
	end
else event.unregister("simulate", L.DWSim)	W.DWsim = nil end end

L.WComb = function(d, one) local m1 = (mp.isMovingForward or mp.isMovingBack)	local m2 = (mp.isMovingLeft or mp.isMovingRight)		local mov = m1 and (m2 and 3 or 1) or (m2 and 2 or 0)
	--MB[1] = 0		mp.animationController.weaponSpeed = 10		MB[1] = 0		ad.animationAttackState = 2		ad.physicalAttackType = 2
	if d == 1 then	-- Режущая
		if mov == 3 then if one then MB[1] = 0 end	ad.animationAttackState = 0									-- наискосок рубящая (отмена только с двуручем и возможно с кулаком)
		elseif mov == 0 then if one then MB[1] = 0 end	ad.animationAttackState = 0		ad.attackDirection = 2		-- стоять рубящая (отмена только с двуручем)
		elseif mov == 1 then MB[1] = 0		ad.animationAttackState = 0 end										-- вперед колющая, странная отмена только с кулаком
	elseif d == 3 then	-- Колющая
		if mov == 2 then ad.animationAttackState = 0	ad.attackDirection = 0					-- вбок режущая с отменой
		elseif mov == 3 then if one == 0 then MB[1] = 0 end		ad.animationAttackState = 0		-- наискосок рубящая с отменой (отмена только с оружием)
		elseif mov == 0 then if one == 0 then MB[1] = 0 end		ad.animationAttackState = 0		ad.attackDirection = one == 0 and 0 or 2 end	-- стоять рубящая с отменой (отмена только с оружием)
	elseif d == 2 then	-- Рубящая
		if mov == 2 then if not one then MB[1] = 0 end	ad.animationAttackState = 0		ad.attackDirection = 0		-- вбок режущая (отмена только с одноручем или кулаком)
		elseif mov == 1 then if one ~= 0 then MB[1] = 0	end		ad.animationAttackState = 0						-- вперед колющая (отмена только с кулаком)
		elseif mov == 0 then if one == 0 then ad.animationAttackState = 0		ad.attackDirection = 3 end end		-- стоять колющая только для кулака
	end
end
L.WSim = function(e) if mp.weaponDrawn and MB[1] == 128 then	--tes3.messageBox("AS = %s   Dir = %s / %s", ad.animationAttackState, ad.attackDirection, ad.physicalAttackType)
	if L.AS[ad.animationAttackState] == 1 then
		L.WComb(ad.attackDirection, not mp.readiedWeapon and 0 or mp.readiedWeapon.object.isOneHanded) 	event.unregister("simulate", L.WSim)	W.Wsim = nil
	end
else event.unregister("simulate", L.WSim)	W.Wsim = nil end end


local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() then local But = e.button + 1		if But == 1 then
	--tes3.messageBox("AnSpd = %.2f   WSpeed = %.2f", mp.animationController.weaponSpeed, mp.readiedWeapon and mp.readiedWeapon.object.speed or 1)
	if mp.spellReadied and not T.MCT.timeLeft then G.arm1.appCulled = false		G.arm2.appCulled = false		local r, AE, EI, sumcost
		local MCK = 2 + (mp.willpower.current + mp.agility.current)/(P.wil15 and 100 or 200) - mp.encumbrance.normalized*(P.end15 and 0.5 or 1)
		+ (D.AR.cs >= 0 and D.AR.cs or math.min(D.AR.cs + math.max(-mp.encumbrance.currentRaw,0)/2, 0))
		
		local stc = 2 - (mp.willpower.current + mp.endurance.current)/(P.end11 and 100 or 200)
		if cf.mcs then tes3.playSound{sound = "destruction bolt", reference = p, loop = true} end
		if MB[cf.mbsum] == 128 and P.con15 then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore={p}}		r = hit and hit.reference		local m = r and r.mobile
			if m and not m.isDead then for _, aef in pairs(mp:getActiveMagicEffects{}) do EI = aef.effectInstance	if EI.createdData and EI.createdData.object == r then
				AE = aef	sumcost = tes3.getMagicEffect(aef.effectId).baseMagickaCost * MCK/50	break
			end end end
		end
		T.MCT = timer.start{duration = 0.1, iterations = -1, callback = function() if stc > 0 and mp.fatigue.current > 3 then mp.fatigue.current = mp.fatigue.current - stc end
			M.MCB.current = math.min(M.MCB.current + MCK, 100)		if P.enc7 and T.PCT.timeLeft then M.PC.current = math.min(M.PC.current + M.PC.max * MCK/5000, M.PC.max) end
			if AE and EI.state == 5 and mp.magicka.current > sumcost then	--36 для завершённых эффектов
				EI.timeActive = EI.timeActive - MCK*0.4		Mod(sumcost)		tes3.messageBox("%s + %.1f = %d   Cost = %.1f", r.object.name, MCK*0.4, AE.duration - EI.timeActive, sumcost)
			end
		end}	event.register("mouseButtonUp", MCStart)
	elseif mp.weaponDrawn then	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object	local wt = W.wt		--or (w and w.type or -1)
		
	--	if w.id == "glass throwing star" then
	--		if (mp.isMovingLeft or mp.isMovingRight) and not (mp.isMovingForward or mp.isMovingBack) then	ad.animationAttackState = 0		ad.attackDirection = 0		mp:equip{item = "glass dagger"}		return end
	--	elseif w.id == "glass dagger" and not ((mp.isMovingLeft or mp.isMovingRight) and not (mp.isMovingForward or mp.isMovingBack)) then	ad.animationAttackState = 0		mp:equip{item = "glass throwing star"}	return end
		
		if W.DWM then		--tes3.messageBox("Dual as = %s    swing = %.2f", ad.animationAttackState, ad.attackSwing)
			if w then	local WTR = WT[W[W.WR.id] or W.WR.type]		local WTL = WT[W[W.WL.id] or W.WL.type]
				W.DWlim = 1.5 - mp.speed.current*(P.spd13 and 0.006 or 0.003) - mp.agility.current*(P.agi22 and 0.006 or 0.003) - mp:getSkillValue(WTR.s)*(WTR.p8 and 0.004 or 0.002) - mp:getSkillValue(WTL.s)*(WTL.p8 and 0.004 or 0.002)
				if ad.animationAttackState == 0 or (L.AS[ad.animationAttackState] == 1 and ad.attackSwing >= W.DWlim) then L.Swap(w, wd)
				elseif not W.DWsim then event.register("simulate", L.DWSim)		W.DWsim = 1 end
			else L.DWMOD(false) end
		end
		
		if wt < 9 and ad.animationAttackState > 0 and ad.attackSwing >= 2 - mp.speed.current*(P.spd13 and 0.006 or 0.003) - mp.agility.current*(P.agi22 and 0.006 or 0.003) - mp:getSkillValue(WT[wt].s)*(WT[wt].p8 and 0.008 or 0.004) then
			if L.AS[ad.animationAttackState] == 1 then	L.WComb(ad.attackDirection, not w and 0 or w.isOneHanded)
			elseif not W.Wsim then event.register("simulate", L.WSim)	W.Wsim = 1 end
		elseif wt == 9 then
			if not G.artim then G.artim = 0		event.register("simulate", L.ArcSim) end
		end
	end
else
if But == cf.mbshot then
	if G.artim and P.mark9a then	G.arcf = 0		G.arcspd = math.max(mp.animationController.weaponSpeed, 0.4)
	elseif ad.animationAttackState == 2 then	local w = mp.readiedWeapon		w = w and w.object		local wt = w and w.type or -1
		if wt == 11 and P.mark9c and not G.met then	local ws = w.speed	G.metmax = ws > 1.4 and 5 or (ws > 1.1 and 4) or (ws > 0.9 and 3) or 2
			if T.Met.timeLeft then G.metsw = math.max(0.75 - T.Met.timeLeft/4, 0.25)	T.Met:reset() else G.metsw = 0.75		T.Met = timer.start{duration = 2, callback = function() end} end
			event.register("simulate", L.MetSim)		G.met = 1	ad.attackSwing = G.metsw	ad.animationAttackState = 4		mp.animationController.weaponSpeed = 1000000	G.arcspd = mp.animationController.weaponSpeed
		end
	end
end
if But == cf.mbkik then L.KIK() end		--if ad.animationAttackState == 2 then ad.animationAttackState = 4	 mp.animationController.weaponSpeed = 1000000 end
end end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)


-- animationAttackState всегда 0   Свинг ещё не определен.
local function ATTACKSTART(e) local a = e.mobile	local spd = e.attackSpeed		--local ar = e.reference		local dir = e.attackType		local ad = a.actionData		local wd = w and w.variables
local w = a.readiedWeapon	w = w and w.object 		local wt = w and (a == mp and W[w.id] or w.type) or -1	--local fiz = ad.physicalDamage	local wh = wd and wt ~= 11 and 100*wd.condition/w.maxCondition or 100
--if m.actorType == 1 or (m.object.biped or m.object.usesEquipment) then
--local m1 = (mp.isMovingForward or mp.isMovingBack)	local m2 = (mp.isMovingLeft or mp.isMovingRight)		local mov = m1 and (m2 and 3 or 1) or (m2 and 2 or 0)
--e.attackType = m1 and (m2 and 2 or 3) or (m2 and 1 or 2)
e.attackSpeed = spd * (0.9 + (a == mp and
(a.speed.current/(P.spd1 and 1000 or 2000) + a:getSkillValue(WT[wt].s)/(P[WT[wt].p4] and 1000 or 2000) - math.max(D.AR.as + mp.encumbrance.normalized * (P.atl12 and 0.1 or 0.2) - math.max(-mp.encumbrance.currentRaw,0)/2000, 0)
- (1 - math.min(mp.fatigue.normalized,1)) * (P.atl11 and 0.1 or 0.2))
or (a.speed.current/1000 + a:getSkillValue(WT[wt].s)/1000)))

if a == mp and W.DWM then
	T.DWB = timer.start{type = timer.game, duration = ((P.bloc16 and 0.2 or 0.15) + mp:getSkillValue(0)/2000) * G.sis, callback = function() end}
end
--if a ~= mp then e.attackSpeed = 0 end

--tes3.messageBox("AtStart! (%s)  dir = %s  spd = %.3f -> %.3f", wt, e.attackType, spd, e.attackSpeed)
end		event.register("attackStart", ATTACKSTART)

local function MOUSEBUTTONUP(e) if not tes3ui.menuMode() and e.button == 0 and ad.animationAttackState == 2 then	local dir = ad.attackDirection	if dir < 4 and not V.dfr then	local pass = MB[cf.mbcharg] == 128
	if cf.autocharg or pass then	local w = mp.readiedWeapon		w = w and w.object		local DMag = math.min(Mag(600), cf.charglim)	if DMag > 0 then
		local vec = tes3.getPlayerEyeVector()	if math.abs(vec.z) < 0.15 then vec.z = 0	vec = vec:normalized() end
		local wr = w and w.reach or G.HandReach.value
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vec, ignore = {p}}		local ref, hitd
		if hit then ref = N[hit.reference] and hit.reference end
		if ref then hitd = ref.position:distance(pp) else ref, hitd = L.Sector{d = 9000, lim = 500} end
		hitd = hitd and hitd - 30 or (hit and hit.distance) or 20000
		if (pass or ref) and hitd > wr*140 then
			local mc = (DMag + (P.acr8 and mp.isFalling and 0 or math.min(DMag,10))) * (P.alt10 and 1 or 1.5)
			local DD = DMag * (Cpow(mp,0,4,true) + (P.spd8 and 50 or 0))/2		local Dkoef = hitd/DD		if Dkoef < 1 then DD = DD * Dkoef		mc = mc * Dkoef	end
			if T.Dash.timeLeft then mc = mc * (1 + T.Dash.timeLeft/(P.atl8 and 10 or 3)) end	local stam = mc * ((P.end10 and 0.5 or 1) - (P.una10 and D.AR.u*0.02 or 0))
			if mc < mp.magicka.current then	local vk = math.max(-0.4 - vec.z, 0)/3
				V.d = vec*(DD/8 * (1 - vk))	V.dfr = 8	event.register("calcMoveSpeed", L.Dash)		tes3.playSound{sound="Spell Failure Destruction"}
				mp.animationController.weaponSpeed = dir == 3 and 0.4 or (dir == 1 and 0.5) or 0.6			V.daf = w and w.speed or 1		if not mp.isJumping then V.djf = true	mp.isJumping = true end
				G.CombatDistance.value = (DD + 50)/wr		G.CombatAngleXY.value = math.clamp(50/DD, 0.05, 0.3)
				TFR(2, function() G.CombatDistance.value = 128		G.CombatAngleXY.value = G.CombatAng end)
				Mod(mc)		mp.fatigue.current = math.max(mp.fatigue.current - stam, 0)
				if cf.m then tes3.messageBox("Charge! Dist = %d  Cost = %.1f  Time = %.1f   SlamK = %d%%", DD, mc, T.Dash.timeLeft or 0, vk*100) end
				V.dd = DD 	if T.Dash.timeLeft then T.Dash:cancel()	end		T.Dash = timer.start{duration = 3, callback = function() end}
				if P.blu12 and hit and hitd > 500 and Dkoef < 1 and w and w.type == 4 and dir == 2 and ad.attackSwing > 0.95 and vec.z < -1 + mp:getSkillValue(20)/(P.acr3 and 150 or 200) and mp.isFalling then
					local dmg = w.chopMax * (1 + mp.strength.current/200) * math.max(mp.readiedWeapon.variables.condition/w.maxCondition, P.arm2 and 0.3 or 0.1) * hitd/3000	local hitp = hit.intersection:copy()	local m
					timer.start{duration = 0.2/w.speed, callback = function() tes3.playSound{sound = table.choice({"endboom1", "endboom2", "endboom3"})}	local fdmg	local num = 0	--"fabBossLeft", "fabBossRight"
						for _, m in pairs(tes3.findActorsInProximity{position = hitp, range = 250}) do if m ~= mp then	num = num + 1
							fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true, resistAttribute = not (w.enchantment or w.ignoresNormalWeaponResistance) and 12 or nil}		L.CrimeAt(m)
							if cf.m then tes3.messageBox("Hammer Slam! Height = %d   %s (%d)  Dmg = %d/%d   Dist = %d", hitd, m.object.name, num, fdmg, dmg, hitp:distance(m.position)) end
						end end
					end}
				end
			end
		end
	end end
	if dir == 1 and not V.daf then G.CombatAngleXY.value = G.CombatAng * (P.agi15 and 2.5 or 2)		TFR(2, function() G.CombatAngleXY.value = G.CombatAng end) end
end end end		event.register("mouseButtonUp", MOUSEBUTTONUP)

--	Велосити заменяет естественную скорость, а импульс складывается с ней		r.sceneNode.velocity - разовое изменение скорости для этого фрейма
--Режимы: 0 = простой на цель, 1 = умный на цель, 2 = самонаведение, 4 = мины, 5 = баллистический, 6 = броски оружия, 10 = стрелы игрока, 11 - стрелы контроль, 7 - магические шары врагов, 8 - спрей, 9 - волна
local function SimulateCP(e)	G.dt = wc.deltaTime		G.cpfr = G.cpfr + 1		G.pep = tes3.getPlayerEyePosition()		G.pev = tes3.getPlayerEyeVector()
	if MB[cf.mbret] == 128 then G.hit = G.pep + G.pev * 150 else G.hit = tes3.rayTest{position = G.pep, direction = G.pev, ignore = {p}}	if G.hit then G.hit = G.hit.intersection else G.hit = G.pep + G.pev * 4800 end end
	for r, t in pairs(CPR) do if t.tim then	--t.tim = t.tim - G.dt
		if t.tim < t.m.animTime then CPR[r] = nil
		elseif t.mod == 1 then t.m.velocity = (G.hit - r.position):normalized() * (t.m.initialSpeed * 0.75)
		elseif t.mod == 11 then if not t.mus or t.m.animTime > 0.5 then t.m.velocity = G.pev*2000	if G.cpfr == 30 then r.orientation = p.orientation	G.cpfr = 0 end end
		elseif t.mod == 0 then t.m.velocity = G.pev * t.m.initialSpeed
		elseif t.mod == 2 then t.m.velocity = (t.tar.position + t.hv - r.position):normalized() * (t.m.initialSpeed/2)
		elseif t.mod == 4 then t.m.position = t.pos		t.m.velocity = t.v*50 end		--tes3vector3.new(50,50,50)
	--	tes3.messageBox("Anim = %.2f  Sw = %.2f  Dam = %.2f  InSpd = %.2f   V = %d", t.m.animTime, t.m.attackSwing, t.m.damage, t.m.initialSpeed, t.m.velocity:length())
	else
		if t.mod == 10 then	t.m.velocity = t.m.velocity + tes3vector3.new(0,0,-2000 * G.dt)	--local ori = r.sceneNode.worldTransform.rotation:toEulerXYZ()			
		elseif t.mod == 7 then if t.liv < t.m.animTime then CPR[r] = nil else t.v = G.pep - r.position	if t.v:length() < G.spdodge then CPR[r] = nil else t.m.velocity = t.v:normalized() * t.m.initialSpeed end end
		elseif t.mod == 5 then t.v = t.ev * (t.m.initialSpeed/2*t.pow) + tes3vector3.new(0,0,-2000 * t.m.animTime)		t.m.velocity = t.con and t.v + G.pev*1000 or t.v
		elseif t.mod == 6 then t.v = t.v + tes3vector3.new(0,0,-G.dt*0.75/t.pow)		t.m.velocity = (t.con and (t.v + G.pev * t.con):normalized() or t.v) * 1000*t.pow		t.r.position = r.position:copy()
		elseif t.mod == 9 then
			if t.m.animTime > 0.3*t.num then
				for i, ef in ipairs(t.ef) do if ME[ef.id] == "wave" then G.WAV[i].id = MID[ef.id%5]		G.WAV[i].min = ef.min*t.k*(1-(t.num-1)/t.max)		G.WAV[i].max = ef.max*t.k*(1-(t.num-1)/t.max)
				G.WAV[i].radius = ef.radius + t.num/(P.alt12 and 1 or 2)		G.WAV[i].duration = ef.duration		G.WAV[i].rangeType = 2	else G.WAV[i].id = -1	G.WAV[i].rangeType = 0 end end			
				MP[tes3.applyMagicSource{reference = p, source = B.WAV}] = {pos = r.position:copy(), exp = true}
				if t.num >= t.max then t.m.expire = 1	CPR[r] = nil else t.num = t.num + 1 end
			end
		elseif t.mod == 8 then	if t.liv < t.m.animTime then t.m.expire = 1		CPR[r] = nil end end
	--	tes3.messageBox("Anim = %.2f   Sw = %.2f  Dam = %.2f  InSpd = %.2f   V = %d", t.m.animTime, t.m.attackSwing, t.m.damage, t.m.initialSpeed, t.m.velocity:length())
	end end		if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	G.cpfr = nil end
end

local function SimulateCPS(e)	G.dt = wc.deltaTime		G.cpg = G.cpg + 4*G.dt
	for r, t in pairs(CPRS) do CPS[t.n] = CPS[t.n] - G.dt
		if CPS[t.n] < 0 then CPS[t.n] = 0	CPRS[r] = nil	else r.position = {pp.x + math.cos(G.cpg + t.n*math.pi/5) * t.rad, pp.y + math.sin(G.cpg + t.n*math.pi/5) * t.rad, pp.z + 100} end
	end		if table.size(CPRS) == 0 then event.unregister("simulate", SimulateCPS)		G.cpscd = nil	G.cpg = 0 end
end

local function MOBILEACTIVATED(e) local m = e.mobile	local r = e.reference	if m then local firm = m.firingMobile	if firm then	local si = m.spellInstance
if firm == mp then	local ss = si and si.source		local n = ss and ss.name	local cont, ray
	--tes3.messageBox("Sw = %.2f  Dam = %.2f  InSpd = %.2f   V = %d   mesh = %s", m.attackSwing, m.damage, m.initialSpeed, m.velocity:length(), r.object.mesh)
	if si then local t = MP[si]		local sn = si.serialNumber		--r.scale = 0.5
		if t then CPR[r] = {}
			timer.delayOneFrame(function() if CPR[r] then r.position = t.pos	if t.exp then m:explode() elseif t.vel then m.velocity = t.vel * m.initialSpeed end		MP[si] = nil end end)
			if n == "4b_SG" then	if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.2, callback = function() end}  	L.SectorDod() end		if G.SGMod then
				if G.SGMod == 5 and t.vel then
					CPR[r] = {mod = 5, m = m, ev = t.vel, pow = 2}		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				elseif G.SGMod == 4 then	local live = (mp.fatigue.normalized*4 + (mp.willpower.current + mp:getSkillValue(14) + mp:getSkillValue(11))/50) * (P.mys80 and 2 or 1)
					CPR[r] = {mod = 4, tim = live*1.5, m = m, pos = DM.cpm and L.Hitpr(t.pos, t.vel, 150) + tes3vector3.new(0,0,20) or t.pos, v = t.vel:normalized()}
					if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				end
			end end
		return end
		
		cont = tes3.isAffectedBy{reference = p, effect = 506}	ray = n == "4b_RAY"
		if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.2, callback = function() end}  	L.SectorDod() end
		local sid = ss.effects[1].id	--tes3.messageBox("Sid = %s    dam = %s", sid, W.metd)
		if sid == 610 then	r.sceneNode.appCulled = true
			if n == "4nm_tet" then W.TETP = r		W.TETsi = si		W.TETmod = 2
			else timer.delayOneFrame(function() r.position = tes3.getPlayerEyePosition() + tes3vector3.new(0,0,20) end)
				CPR[r] = {mod = 6, m = m, v = tes3.getPlayerEyeVector(), r = W.met, pow = W.acs, dmg = W.metd}	W.met.orientation = p.orientation
				V.MET[sn] = {r = W.met, dmg = W.metd}
				if cont and mp.magicka.current > 10 then Mod(10 * (P.mys7 and 0.5 or 1))		CPR[r].con = math.max(1 - W.met.object.weight/50, 0.1)
					V.METR[W.met] = {retmc = (5 + W.met.object.weight/2) * (P.mys7 and 0.5 or 1), si = si, sn = sn}
					if not W.metflag then event.register("simulate", L.SimMET)	W.metflag = true end
				end
				if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
			end
		elseif ME[sid] == "wave" then
			CPR[r] = {mod = 9, m = m, num = 1, ef = ss.effects, k = SN[sn] or 1, max = (P.alt23 and 15 or 5) + math.min(math.floor(mp:getSkillValue(11)/40 + mp.willpower.current/40), 5)}
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		end
		
		if V.BAL[sn] then CPR[r] = {mod = 5, m = m, ev = tes3.getPlayerEyeVector(), pow = V.BAL[sn]}
			if cont and mp.magicka.current > 10 then Mod(6 * (P.mys7 and 0.5 or 1))		CPR[r].con = true end
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		elseif ray and MB[cf.mbray] == 128 == cf.ray then CPR[r] = {mod = 8, m = m, liv = (50 + mp.willpower.current/2 + mp:getSkillValue(11))/(P.alt20 and 600 or 1000)}
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		end
	else	cont = tes3.isAffectedBy{reference = p, effect = 506}
		if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.2, callback = function() end}  	L.SectorDod() end
		CPR[r] = {mod = 10, m = m, liv = 0}		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
		if r.object.type == 13 and P.mark9b and (cf.autoarb or MB[cf.mbshot] == 128) and not T.Arb.timeLeft and mp.fatigue.current > 30 then	local ws = m.firingWeapon.speed
			mp.fatigue.current = mp.fatigue.current - math.max(30 - ws*10, 10)
			mp.animationController.weaponSpeed = mp.animationController.weaponSpeed * (2 + mp.agility.current/50)
			T.Arb = timer.start{duration = 3/ws, callback = function() end}
		end
		if BAM[r.object.id] then BAM.am = r.object.id	if P.con17 or tes3.isAffectedBy{reference = p, effect = 601} then mc = BAM.f()	
			BAM.E[1].id = MID[math.random(3)]	BAM.E[1].min = math.random(5) + mp:getSkillValue(10)/20		BAM.E[1].max = BAM.E[1].min*2		BAM.E[1].radius = math.random(5) + L.GetRad(mp)
			if cf.autoammo and mp.magicka.current > mc then	mp.readiedAmmoCount = 2		tes3.addItem{reference = p, item = BAM.am, count = 1, playSound = false}	Mod(mc) end
		end end
		G.ArcDiv = ((G.arcf or G.met) and 2 or 1) - math.min(mp.agility.current + mp:getSkillValue(23),200)/(P.mark11 and 200 or 300)
		if G.ArcDiv > 0 then m.velocity = L.GetArcVec(30,20) * m.initialSpeed end		--tes3.messageBox("div =  %s ", G.ArcDiv)
	end
	if (cf.raycon or not ray) and (cont or (P.mys18 and T.MCT.timeLeft)) and mp.magicka.current > 10 then mc = 4
		local live = (mp.fatigue.normalized*4 + (mp.willpower.current + mp:getSkillValue(14) + mp:getSkillValue(11))/50) * (P.mys80 and 2 or 1)
		if si then
			--if DM.cp == 3 then mc = 8		timer.delayOneFrame(function() r.position = L.Hitp(0)	 m:explode() end)
			if DM.cp == 2 then	if not G.cpscd then event.register("simulate", SimulateCPS)	G.cpscd = true end	local num = 1	md = CPS[1]		for i, tim in ipairs(CPS) do if tim < md then num = i	md = tim end end 
				CPS[num] = live*1.5		for ref, t in pairs(CPRS) do if t.n == num then CPRS[ref] = nil	break end end		CPRS[r] = {n = num, rad = 200 + ss.effects[1].radius * 6}
				if cf.m then tes3.messageBox("Ball %s  Time = %d  Rad = %d  Balls = %s   Live = %d %d %d %d %d %d %d %d %d %d", num, CPS[num], CPRS[r].rad, table.size(CPRS), CPS[1], CPS[2], CPS[3], CPS[4], CPS[5], CPS[6], CPS[7], CPS[8], CPS[9], CPS[10]) end
			else -- Сперва проверяем мины, затем автонаведение, затем умный режим на цель, затем простой режим
				if DM.cp == 4 then mc = DM.cpm and 10 or 6	
					CPR[r] = {mod = 4, tim = live*1.5, m = m, pos = DM.cpm and L.Hitp(150) + tes3vector3.new(0,0,20) or tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*50, v = tes3.getPlayerEyeVector()}
				else	local tar
					if DM.cp == 1 then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {p}}
						tar = hit and hit.reference and hit.reference.mobile and not hit.reference.mobile.isDead and hit.reference
						if not tar then tar = L.Sector{d = 9000, lim = 3000} end
					end
					if tar then mc = 10	CPR[r] = {mod = 2, tim = live, m = m, tar = tar, hv = tes3vector3.new(0,0,tar.mobile.height/2)}
					elseif DM.cpt and not ray then mc = 6	CPR[r] = {mod = 1, tim = live, m = m}
					else CPR[r] = {mod = 0, tim = live, m = m} end
				end		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
			end
		else if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	mc = 6	CPR[r] = {mod = 11, m = m, tim = live, mus = G.ArcDiv >= 1} end
		Mod((ray and mc/2 or mc) * (P.mys7 and 0.5 or 1))
	end		--if si then SSN[si.serialNumber] = true	tes3.messageBox("Cast! %s", si.serialNumber) end -- устраняем эксплойт с разгоном статов
elseif si and cf.spellhit and firm.actionData.target == mp then 
	CPR[r] = {mod = 7, m = m, liv = firm.object.level/20}
	if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
end
if not si then	r.position = r.position - m.velocity:normalized()*100
	local WD	local w = m.firingWeapon	local wt = w.type		local WS = firm.actorType == 0 and firm.combat.current or firm:getSkillValue(WT[wt].s)
	if wt == 11 then WD = w.chopMax * m.attackSwing / w.speed else
		local Cond = firm.readiedWeapon.variables.condition/w.maxCondition
		WD = (w.chopMax + r.object.chopMax) * m.attackSwing * (Cond > 1 and Cond or math.lerp((firm ~= mp or P.arm2) and 0.3 or 0.2, 1, Cond))
	end
	if w.weight == 0 then WD = WD * (1 + firm:getSkillValue(13)*((firm ~= mp or P.con8) and 0.003 or 0.002)) end
	local Kstr = 100 + firm.strength.current * ((firm ~= mp or P.str1) and 0.5 or 0.4)
	local Kskill = WS * (((firm ~= mp or P[WT[wt].p1]) and 0.2 or 0.1) + ((firm ~= mp or P[WT[wt].h1 and "agi5" or "str2"]) and 0.1 or 0.05))
	local Kbonus = firm.attackBonus/5 + (firm == mp and 0 or firm.object.level)
	local Kstam = math.min(math.lerp(((firm ~= mp or P.end1) and 0.4 or 0.3) + ((firm ~= mp or P[WT[wt].p2]) and 0.2 or 0), 1, firm.fatigue.normalized*1.1), 1)
	m.damage = WD * (Kstr + Kskill + Kbonus)/100 * Kstam	
	if cf.m3 then tes3.messageBox("Proj dmg! %.1f = %.1f * (%d%% str + %d%% skill + %d%% bon) * %d%% stam   sw = %.2f", m.damage, WD, Kstr, Kskill, Kbonus, Kstam*100, m.attackSwing) end
end

	--tes3.messageBox("%s  w = %s  sn = %s  fl = %s  disp = %s  exp = %s  movfl = %s", firm and firm.object.name, m.firingWeapon and m.firingWeapon.id, si and si.serialNumber, m.flags, m.disposition, m.expire, m.movementFlags)
else	local actort = m.actorType 		local ob = r.object 	local id = r.baseObject.id	 	if actort and not m.isDead then N[r] = {m = m, dod = actort == 1 or ob.usesEquipment or L.CDOD[id]} end
if actort == 0 and not L.CrBlackList[id] and not m.isDead and not r.data.spawn then	r.data.spawn = math.random(10)	local d = r.data.spawn		local typ = ob.type
	local conj = L.Summon[id] and L.conjpower or 1		local conj2 = 0		local min, max
	if L.Summon[id] then min = 80	max = 120
		if L.conjagr then m.fight = 100		m:startCombat(mp)	m.actionData.aiBehaviorState = 3
		elseif L.conjp then m.fight = math.max((math.random(50,70) + ob.level * (P.con5 and 1 or 2) - (conj - 1)*100), 50)
			if (typ == 1 and P.con6b) or (typ == 2 and P.con6a) then conj = conj + mp:getSkillValue(13)/1000 end		if P.con7 then conj2 = 0.1 end
		end
	else min = cf.min	max = cf.max end
	local koef = math.random(min,max)/100		tes3.setStatistic{reference = r, name = "health", value = m.health.base * koef * (conj + conj2)}
	koef = koef/((min+max)/200)		if koef > 1 then koef = 1 + (koef - 1) * 0.75 else koef = 1 + (koef - 1) * 0.5 end		r.scale = r.scale * koef
	tes3.setStatistic{reference = r, name = "magicka", value = m.magicka.base * math.random(min,max)/100 * (conj + conj2)}
	tes3.setStatistic{reference = r, name = "fatigue", value = m.fatigue.base * math.random(min,max)/100 * (conj + conj2)}
	for i, stat in ipairs(L.CStats) do tes3.setStatistic{reference = r, name = stat, value = m[stat].base * math.random(min,max)/100 * conj} end
	m.shield = (L.CAR[id] or m.endurance.current/10 + ob.level/2) * math.random(min,max)/100 * conj
	m.resistCommonDisease = 200		m.resistBlightDisease = 200
if cf.full then	rf = r
	if L.CDIS[id] then r.baseObject.spells:add(L.CDIS[id]) end
if typ == 1 then -- Даэдра
	if id == "atronach_flame" or id == "atronach_flame_summon" then m.resistFire = m.resistFire + 200			rems("cruel firebloom", "wizard's fire", "god's fire")
		if d > 7 then adds("cruel firebloom") end	if d > 8 then adds("wizard's fire") end		if d == 10 then adds("god's fire") end
	elseif id == "atronach_frost" or id == "atronach_frost_summon" then m.resistFrost = m.resistFrost + 200		rems("brittlewind", "wizard rend", "god's frost")
		if d > 7 then adds("brittlewind") end	if d > 8 then adds("wizard rend") end	if d == 10 then adds("god's frost") end
	elseif id == "atronach_storm" or id == "atronach_storm_summon" then m.resistShock = m.resistShock + 200		rems("wild shockbloom", "dire shockball", "god's spark")
		if d > 7 then adds("wild shockbloom") end	if d > 8 then adds("dire shockball") end	if d == 10 then adds("god's spark") end
	elseif id == "atronach_flame_lord" then m.resistFire = m.resistFire + 200
	elseif id == "atronach_frost_lord" then m.resistFrost = m.resistFrost + 200
	elseif id == "atronach_storm_lord" then m.resistShock = m.resistShock + 200
	elseif id == "dremora" or id == "dremora_summon" then	rems("summon scamp", "summon clanfear", "fire storm", "firebloom")
		if d > 8 then tes3.addItem{reference = r, item = "4nm_bow_excellent"}	tes3.addItem{reference = r, item = "4nm_arrow_magic+excellent", count = math.random(20,30)}
		elseif d == 8 then tes3.addItem{reference = r, item = "4nm_crossbow_excellent"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)}
		elseif d > 2 then adds(table.choice{"firebloom", "fire storm"}) end
		if d > 5 then adds(table.choice{"summon scamp", "summon clanfear"}) end
	elseif id == "dremora_lord" then	rems("summon daedroth", "summon dremora", "summon flame atronach", "summon frost atronach", "summon storm atronach")
		if d > 2 then adds(table.choice{"summon daedroth", "summon dremora", "summon daedroth", "summon dremora", "summon flame atronach", "summon frost atronach", "summon storm atronach"}) end		
	elseif id == "dremora_mage" or id == "dremora_mage_s" then rems("summon flame atronach", "summon frost atronach", "summon storm atronach", "4nm_star_atronach1a", "4nm_star_atronach2a", "4nm_star_atronach3a",
		"fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom", "flamebolt", "frost bolt", "lightning bolt", "fire storm", "frost storm", "lightning storm")
		adds(table.choice{"fireball", "frostball", "shockball", "4nm_star_atronach1a"}, table.choice{"Fireball_large", "Frostball_large", "shockball_large", "4nm_star_atronach2a"})
		if d > 2 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"})
			if d > 4 then adds(table.choice{"flamebolt", "frost bolt", "lightning bolt", "4nm_star_atronach3a"}, table.choice{"fire storm", "frost storm", "lightning storm"})
				if d > 6 then adds(table.choice{"summon flame atronach", "summon frost atronach", "summon storm atronach"}) end
			end
		end
	elseif id == "scamp" or id == "scamp_summon" then	rems("flame", "fireball", "Fireball_large")
		if d > 5 then adds(table.choice{"flame", "fireball", "Fireball_large"}) end
	elseif id == "daedroth" or id == "daedroth_summon" then	rems("viperbolt", "poisonbloom")
		if d > 6 then adds("viperbolt", "poisonbloom")	elseif d < 3 then adds("viperbolt")	elseif d == 3 or d == 4 then adds("poisonbloom") end
	elseif id == "daedraspider" or id == "daedraspider_s" then	rems("bm_summonbonewolf", "summon daedroth", "summon hunger", "summon clanfear")
		if d > 8 then adds("bm_summonbonewolf")		elseif d < 3 then adds("summon daedroth")	elseif d == 3 or d == 4 then adds("summon hunger")	elseif d == 5 or d == 6 then adds("summon clanfear") end
	elseif id == "winged twilight" or id == "winged twilight_summon" then	rems("frost storm", "lightning storm", "frostbloom", "shockbloom")
		if d == 1 then adds("frost storm") elseif d == 2 then adds("lightning storm") elseif d == 3 then adds("frostbloom") elseif d == 4 then adds("shockbloom") elseif d == 5 then adds("frost storm", "shockbloom")
		elseif d == 6 then adds("lightning storm", "frostbloom") elseif d == 7 then adds("frost storm", "lightning storm", "frostbloom", "shockbloom") end
	elseif id == "xivkyn" or id == "xivkyn_s" then	rems("wizard's fire", "sp_nchurdamzsummon")
		if d > 6 then adds("wizard's fire", "sp_nchurdamzsummon")	elseif d < 3 then adds("wizard's fire")	elseif d == 3 or d == 4 then adds("sp_nchurdamzsummon") end	
	elseif id == "mazken" or id == "mazken_s" then	rems("summon winged twilight", "summon hunger", "summon dremora")
		if d > 8 then tes3.addItem{reference = r, item = "4nm_bow_excellent"}	tes3.addItem{reference = r, item = "4nm_arrow_magic+excellent", count = math.random(20,30)}
		elseif d < 3 then adds("summon winged twilight")	elseif d == 3 or d == 4 then adds("summon hunger")	elseif d == 5 or d == 6 then adds("summon dremora") end
	elseif id == "golden saint" or id == "golden saint_summon" then		rems("summon flame atronach", "summon frost atronach", "summon storm atronach")
		if d > 8 then adds("summon flame atronach")		elseif d < 3 then adds("summon frost atronach")	elseif d == 3 or d == 4 then adds("summon storm atronach") end
	end
elseif typ == 2 then -- Нежить
	if id == "skeleton" or id == "skeleton_summon" then
		if d > 8 then tes3.addItem{reference = r, item = "long bow"}	tes3.addItem{reference = r, item = "iron arrow", count = math.random(20,30)}
		elseif d < 4 then m:equip{item = "iron_shield", addItem = true}
		elseif d == 8 then tes3.addItem{reference = r, item = "wooden crossbow"}	tes3.addItem{reference = r, item = "iron bolt", count = math.random(20,30)} end
	elseif id == "skeleton_mage" or id == "skeleton_mage_s" then
		rems("bone guard", "summon greater bonewalker", "fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom")
		adds(table.choice{"fireball", "frostball", "shockball"})
		if d > 2 then adds(table.choice{"Fireball_large", "Frostball_large", "shockball_large"})	
			if d > 3 then adds(table.choice{"bone guard", "summon greater bonewalker"})
				if d > 7 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"})		tes3.addItem{reference = r, item = "4nm_weapon_mage"} end
			end
		end
	elseif id == "bonelord" or id == "bonelord_summon" then	rems("bone guard", "summon least bonewalker")
		if d > 2 then adds(table.choice{"bone guard", "summon least bonewalker"}) end
	elseif id == "skeleton warrior" then
		if d == 1 then tes3.addItem{reference = r, item = "steel crossbow"}	tes3.addItem{reference = r, item = "steel bolt", count = math.random(20,30)} end
	elseif id == "skeleton archer" or id == "skeleton_archer_s" then if d > 8 then tes3.addItem{reference = r, item = "l_n_wpn_missle_thrown", count = math.random(5,20)}
		elseif d < 3 then tes3.addItem{reference = r, item = "4nm_thrown_magic", count = math.random(5,20)} end
	elseif id == "skeleton champion" then rems("frostbloom", "frost storm")
		if d < 3 then adds(table.choice{"frostbloom", "frost storm"}) elseif d == 3 then adds("frostbloom", "frost storm") end
	elseif id == "ash_revenant" then rems("scourge blade", "heartbite", "daedric bite")
		if d > 7 then m:equip{item = "steel_shield", addItem = true}
		elseif d > 4 then adds(table.choice{"scourge blade", "heartbite", "daedric bite"})
		elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"l_n_wpn_missle_bow", "6th longbow"}}	tes3.addItem{reference = r, item = table.choice{"l_m_wpn_missle_arrow", "6th arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)} end	
	elseif id == "draugr_priest" then rems("daedric bite", "frost bolt", "wizard rend", "bm_draugr_curse")
		if d > 2 then adds(table.choice{"daedric bite", "frost bolt", "wizard rend"})	if d > 8 then tes3.addItem{reference = r, item = "BM ice wand"}		adds("bm_draugr_curse") end end
	elseif id == "draugr_soldier" then
		if d > 5 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = "nordic_sky bow"}	tes3.addItem{reference = r, item = "nordic_sky arrow", count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "steel_sky crossbow"}	tes3.addItem{reference = r, item = "steel_sky bolt", count = math.random(20,30)} end	
	elseif id == "draugr_warrior" then
		if d > 5 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"nordic_sky bow", "BM ice longbow"}}	tes3.addItem{reference = r, item = table.choice{"nordic_sky arrow", "BM ice arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "steel_sky crossbow"}	tes3.addItem{reference = r, item = "steel_sky bolt", count = math.random(20,30)} end	
	end
elseif typ == 0 then -- Обычные кричеры	
	if L.CID[id] == "dwem" then m.resistParalysis = m.resistParalysis + 200
		if id == "centurion_weapon" then
			if d > 5 then m:equip{item = "dwemer_shield", addItem = true}
			elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"dwarven arbalest", "dwarven crossbow"}}	tes3.addItem{reference = r, item = "dwarven bolt", count = math.random(20,30)} end
		end
	elseif id == "goblin_grunt" then
		if d > 5 then m:equip{item = "goblin_shield", addItem = true}
		elseif d == 1 then tes3.addItem{reference = r, item = "goblin throwingaxe", count = math.random(5,10)}
		elseif d == 2 then tes3.addItem{reference = r, item = "goblin arrow", count = math.random(20,30)} end
	elseif id == "goblin_shaman" then rems("fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom")
		adds(table.choice{"fireball", "frostball", "shockball"})
		if d > 3 then adds(table.choice{"Fireball_large", "Frostball_large", "shockball_large"})		if d > 6 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"}) end end
	elseif id == "BM_riekling_shaman" then rems("fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom")
		adds(table.choice{"fireball", "frostball", "shockball"})
		if d > 3 then adds(table.choice{"Fireball_large", "Frostball_large", "shockball_large"})		if d > 6 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"}) end end
	end
elseif typ == 3 then -- Гуманоиды
	if id == "ash_slave" then rems("spark", "flame", "shard", "shockball", "fireball", "frostball")
		if d > 6 then adds(table.choice{"shockball", "fireball", "frostball"})
		elseif d > 2 then adds(table.choice{"spark", "flame", "shard"})
		else m:equip{item = "iron_shield", addItem = true} end
	elseif id == "ash_zombie" then
		if d > 8 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_bow"}	tes3.addItem{reference = r, item = "l_n_wpn_missle_arrow", count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "l_n_wpn_missle_bolt", count = math.random(20,30)}
		elseif d == 4 then tes3.addItem{reference = r, item = "6th throwingknife", count = math.random(5,10)} end
	elseif id == "ash_zombie_warrior" then	
		if d > 7 then m:equip{item = "steel_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"l_n_wpn_missle_bow", "6th longbow"}}	tes3.addItem{reference = r, item = table.choice{"l_m_wpn_missle_arrow", "6th arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)} end
	elseif id == "ash_ghoul_warrior" then	rems("summon hunger", "summon daedroth", "summon clanfear", "summon greater bonewalker", "summon dremora")
		if d > 5 then adds(table.choice{"summon hunger", "summon daedroth", "summon clanfear", "summon greater bonewalker", "summon dremora"}) end
	elseif id == "ash_ghoul" then rems("summon hunger", "summon daedroth", "summon bonelord", "summon greater bonewalker", "summon least bonewalker")
		if d > 5 then adds(table.choice{"summon hunger", "summon daedroth", "summon bonelord", "summon greater bonewalker", "summon least bonewalker"}) end
	elseif id == "ash_ghoul_high" then rems("summon flame atronach", "summon frost atronach", "summon storm atronach", "summon bonelord", "summon least bonewalker")
		if d > 5 then adds(table.choice{"summon flame atronach", "summon frost atronach", "summon storm atronach", "summon bonelord", "summon least bonewalker"}) end
	--elseif id == "ascended_sleeper" then
	end
end end
if cf.m9 then tes3.messageBox("%s (%s)  HP %d/%d   Mana %d/%d   Stam %d/%d   Str %d/%d   Spd %d/%d   End %d/%d   Agi %d/%d   AR %d   Fig %d",
r.object.name, d, m.health.current, r.baseObject.health, m.magicka.current, r.baseObject.magicka, m.fatigue.current, r.baseObject.fatigue,
m.strength.current, r.baseObject.attributes[1], m.speed.current, r.baseObject.attributes[5], m.endurance.current, r.baseObject.attributes[6], m.agility.current, r.baseObject.attributes[4], m.shield, m.fight) end
end end end end		event.register("mobileActivated", MOBILEACTIVATED)

-- Прожектайл Экспире НЕ триггерится если снаряд убит командой стейт = 6		tes3.messageBox("ex  %s    si = %s", pr, si and si.serialNumber or "nil")
L.NoEXP = {["4b_EXP"] = true, ["4b_WAV"] = true}
local function PROJECTILEEXPIRE(e) if e.firingReference == p then local pm = e.mobile	local pr = pm.reference		local si = pm.spellInstance		if si then local eff = si.source.effects	local sn = si.serialNumber
	
	if D.Exp and not D.Expdis and not L.NoEXP[si.source.name] then
		L.ExpSpell()
		MP[tes3.applyMagicSource{reference = p, source = B.EXP}] = {pos = pr.position:copy(), exp = true}
	end
	
	if W.TETP and W.TETP == pr then W.TETP = nil	W.TETmod = 3 end
	if V.MET[sn] then local wr = V.MET[sn].r	local drop
		if V.METR[wr] then
			if not V.METR[wr].f then if cf.metret and mp.magicka.current > V.METR[wr].retmc then Mod(V.METR[wr].retmc)	V.METR[wr].f = 1 else V.METR[wr] = nil	drop = true end end
		else drop = true end
		if drop then local hit = tes3.rayTest{position = wr.position - pm.velocity:normalized()*100, direction = V.down}
		if hit then wr.position =
		hit.intersection + tes3vector3.new(0,0,5) end end
	elseif P.des8 and ME[eff[1].id] == 1 and si.source.name ~= "4b_WAV" then	local rad = 0		local radbon = L.GetRad(mp)
		for i, ef in ipairs(eff) do if ME[ef.id] == 1 and ef.radius > 9 then rad = rad + math.random(ef.min, ef.max) * math.max(ef.radius - 15 + radbon, 0) end end
		if rad > 0 then rad = rad * Cpow(mp,0,2)/100 * (SN[sn] or 1)		L.KBlast(pr.position, rad) end
	end
else
	if D.poison then D.poison = D.poison - math.max(100 - mp.agility.current/(P.agi12 and 2 or 4),50)	M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end end
	if W.f == 2 and pm.firingWeapon == W.ob then MP[tes3.applyMagicSource{reference = p, source = W.ob.enchantment, fromStack = mp.readiedWeapon}] = {pos = pr.position:copy(), exp = true} end
	if D.CW and not D.CWdis and cf.smartcw then	L.CWF(p, 2, 1.5, pr.position:copy()) end
end end end		event.register("projectileExpire", PROJECTILEEXPIRE)


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
["w\\tr\\dwarven_arrow.dds"] = "dwarven arrow",
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
["w\\bonemold_star.tga"] = "bonemold star",
["w\\daedric_star.dds"] = "daedric star",
["w\\dwarven_star.tga"] = "dwarven star",
["w\\iron_star.tga"] = "iron star",
["w\\tx_w_dwarvenspheredart.dds"] = "centurion_projectile_dart",
["w\\tx_w_dart_steel.tga"] = "steel dart",
["w\\tx_dart_daedric.tga"] = "daedric dart",
["w\\tx_dart_ebony.tga"] = "ebony dart",
["w\\tx_dart_silver.tga"] = "silver dart",
["w\\orcish_dart.dds"] = "orcish dart",
["w\\adamant_dart.tga"] = "adamantium dart",
["w\\glass_dart.dds"] = "glass dart",
["w\\iron_dart.tga"] = "iron dart",
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
["w\\iron_throwingaxe.dds"] = "iron throwingaxe",
["w\\nord_throwingaxe.dds"] = "nordic throwingaxe",
["w\\silver_throwingaxe.dds"] = "silver throwingaxe",
["w\\glass_throwingaxe.dds"] = "glass throwingaxe",
["w\\chitin_throwingaxe.dds"] = "chitin throwingaxe",
["w\\daedric_throwingaxe.dds"] = "daedric throwingaxe",
["w\\goblin_throwingaxe.dds"] = "goblin throwingaxe",
["w\\riekling_javelin.dds"] = "BM riekling javelin"}

local function PROJECTILEHITACTOR(e) if e.target ~= p and e.mobile.reference.object.enchantment and not L.BlackAmmo[e.mobile.reference.object.id] and e.firingReference and not L.Summon[e.firingReference.baseObject.id] then
	if P.luc8 or math.random(100) < 75 then local amob = L.AMIC[e.mobile.reference.object.icon:lower()]
	if amob then tes3.addItem{reference = e.target, item = amob, playSound = false} end end
	--[[
	local hit = tes3.rayTest{position = e.collisionPoint - e.velocity:normalized()*10, direction = e.velocity}		local pos = hit and hit.intersection
	if pos then
		local nod = e.target.sceneNode		nod = nod:getObjectByName("Bip01") or nod
		local trans = e.mobile.reference.sceneNode.worldTransform
		local clone = e.mobile.reference.object.sceneNode:clone()
		local invM = nod.worldTransform.rotation:invert()	local invS = 1 / nod.worldTransform.scale
		clone.rotation = invM * trans.rotation			clone.translation = invM * (pos - nod.worldTransform.translation) * invS * 0.5			clone.scale = invS
		nod:attachChild(clone)	nod:update()	clone:updateProperties()	clone:updateEffects()
	end	--]]
end end		event.register("projectileHitActor", PROJECTILEHITACTOR)

local function onProj(e) local r = e.mobile.reference	local ob = r.object 	if not L.BlackAmmo[ob.id] and e.firingReference and not L.Summon[e.firingReference.baseObject.id] then
local cp = e.collisionPoint		local amob = ob.enchantment and L.AMIC[ob.icon:lower()] or ob		if amob and math.abs(cp.x) < 9000000 then
	local hit = tes3.rayTest{position = cp - e.velocity:normalized()*10, direction = e.velocity}		local pos		--cp + e.velocity * 0.7 * wc.deltaTime
	if hit and hit.intersection:distance(cp) < 150 then pos = hit.intersection else local hitd = tes3.rayTest{position = cp, direction = V.down}	pos = hitd and hitd.intersection end		
	if pos then local ref = tes3.createReference{object = amob, cell = p.cell, orientation = r.sceneNode.worldTransform.rotation:toEulerXYZ(), position = pos}	ref.modified = false	PRR[ref] = true end
	--tes3.createReference{object = "4nm_boundarrow", cell = p.cell, orientation = r.sceneNode.worldTransform.rotation:toEulerXYZ(), position = cp}
end end end		if cf.Proj then event.register("projectileHitObject", onProj)	event.register("projectileHitTerrain", onProj) end


local function MOBILEDEACTIVATED(e) local r = e.reference
	N[r] = nil		AF[r] = nil		FR[r] = nil
--	if AF[r].tremor then AF[r].tremor:cancel()	if r.mobile and r.mobile.paralyze > 0 then r.mobile.paralyze = 0 end end
	if R[r] then R[r] = nil	if cf.m4 then tes3.messageBox("%s deactivated  Enemies = %s", r, table.size(R)) end end
	if A[r] then	if A[r].mettim then A[r].mettim:cancel() end	if A[r].axetim then A[r].axetim:cancel() end	if A[r].longtim then A[r].longtim:cancel() end		if A[r].part then A[r].part:cancel() end	A[r] = nil end
end		event.register("mobileDeactivated", MOBILEDEACTIVATED)


local function OBJECTINVALIDATED(e) local ob = e.object
	if CPR[ob] then CPR[ob] = nil elseif CPRS[ob] then CPS[CPRS[ob].n] = 0	CPRS[ob] = nil end
	if ob == W.TETR then if cf.m then tes3.messageBox("Telekinesis: Invalidated") end	W.TETR = nil end
--	if V.METR[ob] then V.METR[ob] = nil		if cf.m then tes3.messageBox("Throw: Invalidated") end end
	if DER[ob] then DER[ob] = nil end
	if PRR[ob] then PRR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)

-- ЦеллЧЕйнджед НЕ триггерит инвалидейтед обычных референций, но триггерит Прожектайл Экспире.
local function CELLCHANGED(e) AC = {}		for _, cell in pairs(tes3.getActiveCells()) do AC[cell] = true end
	if W.TETmod and e.previousCell and (e.cell.isInterior or e.previousCell.isInterior) then p:activate(W.TETR) end
	if W.metflag and e.previousCell and (e.cell.isInterior or e.previousCell.isInterior) then for r, t in pairs(V.METR) do if t.f then p:activate(r) end end	V.METR = {}	end
	if cf.trmod then local tim = T.T1.timing - G.Exptim		for i = 1, 4 do	D.ExpFat[i] = math.max(D.ExpFat[i] - tim, 0) end		G.Exptim = T.T1.timing end
end		event.register("cellChanged", CELLCHANGED)

local function mouseWheel(e)
	tes3.messageBox("Scroll = %s", e.delta)
end		--event.register("mouseWheel", mouseWheel)

--local function Fire(n)  tes3.createReference{object = "iron dagger", position = tes3.player.position, cell = tes3.player.cell} if n > 1 then timer.delayOneFrame(function() Fire(n-1) end) end end
local QK = {[cf.q0.keyCode] = "0", [cf.q1.keyCode] = "1", [cf.q2.keyCode] = "2", [cf.q3.keyCode] = "3", [cf.q4.keyCode] = "4", [cf.q5.keyCode] = "5", [cf.q6.keyCode] = "6", [cf.q7.keyCode] = "7", [cf.q8.keyCode] = "8", [cf.q9.keyCode] = "9"}
local function KEYDOWN(e) if not tes3ui.menuMode() then local k = e.keyCode		--tes3.messageBox("key = %s   jump = %s", k, ic.inputMaps[12].code)
if k == cf.magkey.keyCode then local CS = mp.currentSpell		-- Быстрый каст
	if ad.animationAttackState == 1 then
		if L.AG[ad.currentAnimationGroup] then
			if P.agi25 and ad.currentAnimationGroup == 34 then		local stc = 100 * (1 + mp.encumbrance.normalized)
				if mp.fatigue.current > stc then mp.fatigue.current = mp.fatigue.current - stc		ad.animationAttackState = 0		if cf.m then tes3.messageBox("Stand up! Stamcost = %d", stc) end end
			end
		elseif P.agi17 and not (A[p] and A[p].part) then		local stc = 30 * (1 + mp.encumbrance.normalized)
			if mp.fatigue.current > stc then mp.fatigue.current = mp.fatigue.current - stc		ad.animationAttackState = 0		if cf.m then tes3.messageBox("Break free! Stamcost = %d", stc) end end
		end
	elseif (mp.hasFreeAction and mp.paralyze < 1 or P.agi17) and ad.animationAttackState ~= 10 then
		if M.QB.normalized >= (P.spd11 and 0.5 or 1) and not D.QSP["0"] and QS ~= CS and CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 and (P.int3 or CS.alwaysSucceeds) then QS = CS
			M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon
		end
		if QS then	local excost = (QS.alwaysSucceeds and 4 or 2) + (P.agi24 and 0 or 2)	local stc = QS.magickaCost * (P.end8 and 0.5 or 1)
			if M.QB.current >= excost and mp.fatigue.current > stc then		mp.fatigue.current = mp.fatigue.current - stc
				if ad.animationAttackState == 2 then MB[1] = 0 end
				G.LastQS = QS		tes3.cast{reference = p, spell = QS, instant = true, alwaysSucceeds = false}
				M.QB.current = math.max(M.QB.current - excost, 0)
				if not T.QST.timeLeft then T.QST = timer.start{duration = math.max(1 - mp.speed.current/(P.spd9 and 200 or 400), 0.25), iterations = -1, callback = function()
				M.QB.current = M.QB.current + 1		if M.QB.current == 20 then T.QST:cancel() end end} end
			end
		end
	end
	
elseif QK[k] and M.QB.normalized >= (P.spd11 and 0.5 or 1) then local CS = mp.currentSpell		-- Выбор быстрого каста
	if QK[k] ~= "0" then
		if e.isShiftDown and CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 and (CS.alwaysSucceeds or P.int3) then
			D.QSP[QK[k]] = CS.id		tes3.messageBox("%s remembered for %s extra-cast slot", D.QSP[QK[k]], QK[k])
		end
		if D.QSP[QK[k]] then D.QSP["0"] = QK[k]		QS = tes3.getObject(D.QSP[D.QSP["0"]])		M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon
			if cf.m10 then tes3.messageBox("%s prepared for extra-cast slot %s  %s", QS.name, D.QSP["0"], QS.alwaysSucceeds and "Is a technique" or "") end
		end
	else
		if e.isShiftDown and CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 then
			if D.FS[CS.id] then D.FS[CS.id] = nil	tes3.messageBox("%s removed from Favorite Spells", CS.name) else D.FS[CS.id] = CS.alwaysSucceeds and 1 or 0		tes3.messageBox("%s added to Favorite Spells", CS.name) end
		elseif e.isAltDown then D.FS = {}	tes3.messageBox("Favorite spell list cleared") else D.QSP["0"] = nil end
	end
elseif k == cf.tpkey.keyCode and (P.agi17 or mp.hasFreeAction) and mp.paralyze < 1 then		local dkik = MB[3] == 128	local DMag = math.min(Mag(600), dkik and 1000 or cf.dash)	-- дэши
	if DMag > 0 and MB[cf.mbdod] ~= 128 then	local ang	local DD = DMag * (Cpow(mp,0,4,true) + (P.spd8 and 50 or 0))/2
		mc = (DMag + (P.acr8 and mp.isFalling and 0 or math.min(DMag,10))) * (P.alt10 and 1 or 1.5)
		if mp.isMovingForward then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end
		elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
		elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 end
		V.d = tes3.getPlayerEyeVector()		if ang then Matr:toRotationZ(math.rad(ang))	V.d = Matr * V.d end
		if ang == 90 or ang == 270 then V.d.z = 0	V.d = V.d:normalized()	else if mp.isMovingBack then V.d = V.d*-1 end	if math.abs(V.d.z) < 0.15 then V.d.z = 0	V.d = V.d:normalized() end end
		if dkik then local kref		kref, dkik = L.Sector{d = DD, lim = 500, v = V.d} end
		if dkik then dkik = dkik/DD		if dkik < 1 then DD = DD * dkik		mc = mc * dkik end
		else	local dhit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = V.d, ignore={p}}		if dhit then dhit = dhit.distance/DD	if dhit < 1 then DD = DD * dhit		mc = mc * dhit end end end
		if T.Dash.timeLeft then mc = mc * (1 + T.Dash.timeLeft/(P.atl8 and 10 or 3)) end	local stam = mc * ((P.end10 and 0.5 or 1) - (P.una10 and D.AR.u*0.02 or 0))
		if not V.dfr and mc < mp.magicka.current then		local vk = math.max(-0.4 - V.d.z, 0)/3
			V.d = V.d*(DD/8 * (1 - vk))		V.dfr = 8	event.register("calcMoveSpeed", L.Dash)		tes3.playSound{sound="Spell Failure Destruction"}
			if not mp.isJumping then V.djf = true	mp.isJumping = true end			if dkik and cf.autokik then V.dkik = true end
			Mod(mc)		mp.fatigue.current = math.max(mp.fatigue.current - stam, 0)		if cf.m then tes3.messageBox("Dash dist = %d  Cost = %.1f  Time = %.1f  SlamK = %d%%", DD, mc, T.Dash.timeLeft or 0, vk*100) end
			V.dd = DD 	if T.Dash.timeLeft then T.Dash:cancel()	end		T.Dash = timer.start{duration = 3, callback = function() end}
		end
	else	local stam = (P.agi4 and 40 or 50) * (1 + mp.encumbrance.normalized*(P.agi14 and 0.5 or 1) + (D.AR.dc < 0 and D.AR.dc or math.max(D.AR.dc - math.max(-mp.encumbrance.currentRaw,0)/1000,0)))
		if T.Dod.timeLeft then stam = stam * (1 + T.Dod.timeLeft/(P.atl10 and 6 or 3)) end
		if not V.dfr and (P.acr13 or not mp.isFalling) and stam < mp.fatigue.current then	local ang
			if mp.isMovingForward then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end
			elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
			elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 end
			V.d = tes3.getPlayerEyeVector()		if ang then Matr:toRotationZ(math.rad(ang))	V.d = Matr * V.d end
			V.d.z = 0	V.d = V.d:normalized()		V.d = V.d * ((P.spd16 and 150 or 100)/5) * (mp.isMovingBack and -1 or 1)
			V.dfr = 5	event.register("calcMoveSpeed", L.Dash)		mp.fatigue.current = mp.fatigue.current - stam			tes3.playSound{sound = math.random(2) == 1 and "LeftS" or "LeftM"}
			if not mp.isJumping then V.djf = true	mp.isJumping = true end
			if cf.m then tes3.messageBox("Active dodge!  Cost = %d  Time = %.1f", stam, T.Dod.timeLeft or 0) end
			if P.sec6 and (T.Dod.timeLeft or 0) < 2 then tes3.applyMagicSource{reference = p, name = "Dodge", effects = {{id = 510, min = 20, max = 20, duration = 1}}} end
			if T.Dod.timeLeft then T.Dod:cancel() end	T.Dod = timer.start{duration = 3, callback = function() end}
		end
	end
elseif k == cf.kikkey.keyCode then L.KIK()		--tes3.messageBox("Status = %s", T.T1.timing)
elseif k == cf.telkey.keyCode then -- Телекинез + Метание оружия - возврат

	--	G.CombatDistance.value = 2000
	--	TFR(2, function() G.CombatDistance.value = 128 end)

	--tes3.applyMagicSource{reference = p, source = B["Storm_touch"]}
	for r, t in pairs(V.METR) do if not t.f and mp.magicka.current > t.retmc then Mod(t.retmc)		t.f = 1		t.si.state = 6 end end
	if not W.TETmod then	local ref = tes3.getPlayerTarget()	if ref and ref.object.weight then TELnew(ref) end
	elseif W.TETmod == 1 then
		if MB[3] == 128 then p:activate(W.TETR)
		elseif mp.magicka.current > W.TETcost then mc = W.TETcost * (P.mys7 and 0.5 or 1)		Mod(mc)		tes3.playSound{sound = "Weapon Swish"}	--Weapon Swish		Spell Failure Destruction
			tes3.applyMagicSource{reference = p, name = "4nm_tet", effects = {{id = 610, rangeType = 2}}}	if cf.m then tes3.messageBox("Telekinetic throw! Dmg = %.1f  Cost = %.1f (%.1f base)", W.TETdmg, mc, W.TETcost) end
		end
	elseif W.TETmod == 2 then W.TETmod = 3	W.TETsi.state = 6	W.TETsi = nil
	elseif W.TETmod == 3 and P.mys16 and mp.magicka.current > 2*W.TETcost then	mc = W.TETcost * (P.mys7 and 0.5 or 1) * math.min(1 + pp:distance(W.TETR.position)/5000, 2)
		Mod(mc)	W.TETmod = 1	tes3.playSound{sound = "enchant fail"}	if cf.m then tes3.messageBox("Extra teleport!  Manacost = %.1f (%.1f base)", mc, W.TETcost) end
	end
elseif k == cf.cwkey.keyCode then -- Заряженное оружие
	if e.isControlDown then D.CWm = not D.CWm	tes3.messageBox("Charged weapon: %s", D.CWm and "ranged" or "touch")
	elseif e.isShiftDown then D.CWdis = not D.CWdis	tes3.messageBox("Charged weapon: %s", D.CWdis and "disabled" or "enabled")
	elseif e.isAltDown then D.NoEnStrike = not D.NoEnStrike		W.bar.fillColor = D.NoEnStrike and {1,0,0} or {0,1,1}
		tes3.messageBox("Weapon enchant trigger when attacking: %s", D.NoEnStrike and "disabled" or "enabled")
	elseif D.CW and W.TETR and P.mys17 then L.CWF(p, 2, 1, W.TETR.position:copy()) end
elseif k == cf.cpkey.keyCode then -- Контроль снарядов
	if MB[1] == 128 then CPRS = {}	for r, t in pairs(CPR) do if t.tim then 	 if t.mod == 4 then t.m.velocity = t.v * t.m.initialSpeed end		CPR[r] = nil end end -- Роспуск снарядов
	elseif MB[3] == 128 then for r, t in pairs(CPR) do if t.tim and t.mod < 11 then t.m:explode() end end		for r, t in pairs(CPRS) do r.mobile:explode() end
	elseif e.isAltDown then if DM.cpt then DM.cpt = false tes3.messageBox("Simple mode") elseif P.alt8a then DM.cpt = true tes3.messageBox("Smart mode") end
	elseif e.isControlDown then if DM.cpm then DM.cpm = false tes3.messageBox("Mines: simple mode") elseif P.mys8a then DM.cpm = true tes3.messageBox("Mines: teleport mode") end
	elseif ic:isKeyDown(ic.inputMaps[1].code) then if P.mys8a then DM.cp = 3 tes3.messageBox("Teleport projectiles") end
	elseif ic:isKeyDown(ic.inputMaps[2].code) then if P.mys8b then DM.cp = 1 tes3.messageBox("Homing projectiles") end
	elseif ic:isKeyDown(ic.inputMaps[3].code) then if P.alt8b then DM.cp = 2 tes3.messageBox("Spin projectiles") end
	elseif ic:isKeyDown(ic.inputMaps[4].code) then if P.alt8c then DM.cp = 4 tes3.messageBox("Magic mines") end else DM.cp = 0 tes3.messageBox("Target projectiles") end
elseif k == cf.reflkey.keyCode then	-- Отражение	Auras  Prok
	if e.isControlDown then D.Aurdis = not D.Aurdis		tes3.messageBox("Damage aura mode: %s", D.Aurdis and "disabled" or "enabled")
	elseif e.isShiftDown then D.Expdis = not D.Expdis		tes3.messageBox("Explode spell mode: %s", D.Expdis and "disabled" or "enabled")
	else DM.refl = not DM.refl	tes3.messageBox("Reflect spell mode: %s", DM.refl and "reflect" or "manashield") end
elseif k == cf.totkey.keyCode then -- Тотемы и руны
	if e.isShiftDown then for i, t in pairs(RUN) do L.RunExp(i) end
	elseif e.isControlDown then for i, t in pairs(TOT) do L.TotExp(i) end
	else D.Totdis = not D.Totdis	tes3.messageBox("Totem shooting: %s", D.Totdis and "disabled" or "enabled") end
elseif k == cf.detkey.keyCode then local mag = P.mys12 and 30 or 20  -- Обнаружение
	local node, nod		local dist = {tes3.getEffectMagnitude{reference = p, effect = 64}*mag, tes3.getEffectMagnitude{reference = p, effect = 65}*mag, tes3.getEffectMagnitude{reference = p, effect = 66}*mag}	DEDEL()
	for c, _ in pairs(AC) do for r in c:iterateReferences() do local ot
		if r.object.objectType == tes3.objectType.container and not r.object.organic then ot = "cont" elseif r.object.objectType == tes3.objectType.door then ot = "door" elseif r.mobile and not r.mobile.isDead then
		if r.object.objectType == tes3.objectType.npc or r.object.type == 3 then ot = "npc" elseif r.object.type == 1 then ot = "dae" elseif r.object.type == 2 then ot = "und" elseif r.object.blood == 2 then ot = "robo" else ot = "ani" end
		elseif r.object.enchantment or r.object.isSoulGem then ot = "en" elseif r.object.isKey then ot = "key" end
		if ot and r.sceneNode then node = r.sceneNode:getObjectByName("detect") if node then r.sceneNode:detachChild(node) 	r.sceneNode:update()	r.sceneNode:updateNodeEffects() end
			if pp:distance(r.position) < dist[L.DEO[ot].s] then nod = L.DEO[ot].m:clone()	if r.mobile then nod.translation.z = nod.translation.z + r.mobile.height/2 end
		r.sceneNode:attachChild(nod, true)	r.sceneNode:update()	r.sceneNode:updateNodeEffects()		DER[r] = ot end end
	end end		if table.size(DER) > 0 then tes3.playSound{reference = p, sound = "illusion hit"}	if T.DET.timeLeft then T.DET:reset() else T.DET = timer.start{duration = 10, callback = DEDEL} end end
elseif k == cf.markkey.keyCode then	local mtab = {}		for i = 1, 10 do mtab[i] = i.." - "..(DM["mark"..i] and DM["mark"..i].id or "empty") end -- Пометки
	mtab[11] = "Teleport companions: " .. (D.NoTPComp and "no" or "yes")
	tes3.messageBox{message = "Select a mark for recall", buttons = mtab, callback = function(e) if e.button == 10 then D.NoTPComp = not D.NoTPComp else	local v = "mark"..(e.button+1)		if DM[v] then
		mp.markLocation.cell = tes3.getCell{id = DM[v].id}		mp.markLocation.position = tes3vector3.new(DM[v].x, DM[v].y, DM[v].z)
	end end end}
elseif k == cf.bwkey.keyCode then mc = BAM.f()	-- Призванное оружие
	if e.isControlDown and (P.con17 or tes3.isAffectedBy{reference = p, effect = 601}) and mp.magicka.current > mc then	if mp.readiedWeapon then BAM.am = BAM[mp.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
		if mwscript.getItemCount{reference = p, item = BAM.am} == 0 then tes3.addItem{reference = p, item = BAM.am, count = 1, playSound = false}	Mod(mc) end mp:equip{item = BAM.am}
	else	local M = {}	M.M = tes3ui.createMenu{id = 402, fixedFrame = true}	M.M.minHeight = 800	M.M.minWidth = 800		local el	M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
		for i = 1, 4 do M[i] = M.B:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 5		M[i].flowDirection = "top_to_bottom" end
		for i, l in ipairs(L.BW) do for _, id in ipairs(l) do
			el = M[i]:createLabel{text = id}	el.borderBottom = 2		el:register("mouseClick", function() D.boundw = "4_bound " .. id	M.M:destroy()	tes3ui.leaveMenuMode() end)
		end end		tes3ui.enterMenuMode(402)
	end
elseif k == cf.parkey.keyCode then	-- Парирование
	D.nopar = not D.nopar	M.NoPar.visible = D.nopar		tes3.messageBox("Parry mode: %s", D.nopar and "disabled" or "enabled")
elseif k == cf.poisonkey.keyCode then D.poimod = not D.poimod		M.drop.visible = D.poimod		tes3.messageBox("Poison mode %s", M.drop.visible and "enabled" or "disabled")	-- Режим яда
elseif k == cf.dwmkey.keyCode then if e.isAltDown then W.WL = nil W.DL = nil else L.DWMOD(not W.DWM) end	-- Двойное оружие
elseif k == cf.pkey.keyCode and L.READY then	local M = {}	M.M = tes3ui.createMenu{id = 400, fixedFrame = true}	M.M.minHeight = 1100	M.M.minWidth = 1240	-- Перки
	M.S = 0		for i, l in ipairs(L.PR) do for _, t in ipairs(l) do if P[t[1]] then M.S = M.S + t.f end end end	local pat
	M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
	M.F = M.B:createFillBar{current = M.S, max = p.object.level * cf.pmult}	M.F.width = 300		M.F.height = 24		M.F.widget.fillColor = {1,0,1}
	M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkSpells()	L.HPUpdate() end)
	M.class = M.B:createButton{text = cf.en and "Legendary" or "Легендарность"}
	M.class:register("mouseClick", function() if mp.inCombat then tes3.messageBox("%s", cf.en and "In combat" or "Вы в бою") else M.M:destroy()	tes3ui.leaveMenuMode()	L.LegSelect() end end)
	M.resp = M.B:createButton{text = cf.en and "Reset perks" or "Сброс перков"}		M.resp:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkReset() end)
	M.take = M.B:createButton{text = cf.en and "Take free perks" or "Взять бесплатные перки"}		M.take:register("mouseClick", function()
		for i, l in ipairs(L.PR) do for _, t in ipairs(l) do if t.f < 1 and mp[L.PRL[i][1]].base >= t[2] and t[1] ~= "int0" then P[t[1]] = true end end end
		M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkSpells()	L.HPUpdate()
	end)
	if P.int16 and not mp.inCombat then M.spcrea = M.B:createButton{text = cf.en and "Spell making" or "Создание заклинаний"}		M.spcrea:register("mouseClick", function()
		M.M:destroy()	tes3ui.leaveMenuMode()		tes3.findGMST("fSpellMakingValueMult").value = 0		tes3.showSpellmakingMenu{serviceActor = mp, useDialogActor = false}
		timer.delayOneFrame(function() tes3.findGMST("fSpellMakingValueMult").value = P.merc7 and 10 or 20 end)
	end) end
	for i = 1, 35 do M[i] = M.A:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 1		M[i].flowDirection = "top_to_bottom" end
	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do pat = "icons/p/"..t[1]..".tga"		t.m = M[i]:createImage{path = tes3.getFileExists(pat) and pat or L.PRL[i][2]}
		t.m.borderBottom = 2	if not P[t[1]] then t.m.color = {0.2,0.2,0.2} end
		t.m:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}		tt.autoHeight = true	tt.autoWidth = true		tt.maxWidth = 600
		tt:createLabel{text = ("%s   Cost: %s - %s = %s   Required %s: %s  -  %s"):format(t[cf.en and 4 or 3], t.x, t.c or 0, t.f, L.PRL[i][1], t[2], t[cf.en and 6 or 5])} end)
		if M.F.widget.max >= M.S + t.f and not P[t[1]] and mp[L.PRL[i][1]].base >= t[2] then t.m:register("mouseClick", function() if not P[t[1]] and M.F.widget.max >= M.S + t.f then P[t[1]] = true
		M.S = M.S + t.f		M.F.widget.current = M.S	M.F:updateLayout()	tes3.playSound{sound = "skillraise"} end end) end
	end end		tes3ui.enterMenuMode(400)
	if e.isAltDown then	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do P[t[1]] = true end end		for _, num in ipairs(L.SFS) do tes3.addSpell{reference = p, spell = "4s_"..num, updateGUI = false} end
	tes3.updateMagicGUI{reference = p, updateEnchantments = false}		D.resetday = 0		tes3.messageBox("TESTER MOD ACTIVATED!")	tes3.playSound{sound = "Thunder0"} end
end end end		event.register("keyDown", KEYDOWN)


local function CALCFLYSPEED(e) if e.mobile == mp then e.speed = mp.levitate
	* (20 + mp:getSkillValue(11)/(P.alt15 and 5 or 10))
	* (1 + mp.speed.current/(P.spd18 and 400 or 1000))
	* (1 - (1 - math.min(mp.fatigue.normalized,1)) * (P.atl2 and 0.25 or 0.5))
elseif not e.mobile.object.flies then e.speed = (2 + e.mobile.levitate) * 40 * (1 + e.mobile.speed.current/400) 		--tes3.messageBox("fly = %s  lev = %.1f  speed = %d", e.reference, e.mobile.levitate, e.speed)
end end		event.register("calcFlySpeed", CALCFLYSPEED)

local function CALCMOVESPEED(e) local m = e.mobile		if m == mp then e.speed = e.speed
	* math.min(D.AR.ms + math.max(-mp.encumbrance.currentRaw,0)/2000, 1)
	* (P.atl3 and 1 or (1 - mp.encumbrance.normalized/3))
	* (mp.isMovingBack and (P.agi16 and math.min(0.5 + mp.agility.current/400, 0.75) or 0.5) or 1)
	* ((mp.isMovingLeft or mp.isMovingRight) and (mp.isMovingForward or mp.isMovingBack) and 0.8 or 1)
	* (mp.isRunning and (P.spd0 and mp.isMovingForward and not (mp.isMovingLeft or mp.isMovingRight) and 1 or 0.75)
	* (1 - (1 - math.min(mp.fatigue.normalized,1)) * (P.atl2 and 0.25 or 0.5))
	* (ad.animationAttackState == 2 and (P.spd10 and 0.8 or 2/3) or 1) or 1)
	--tes3.messageBox("speed = %d  run = %s / %s", e.speed, mp.isRunning, mp.alwaysRun)
else e.speed = e.speed * (0.5 + math.min(m.fatigue.normalized,1)/2)
	if DOM[m] then	local t = DOM[m]
		m.impulseVelocity = t.v * (1/wc.deltaTime)*TSK		t.fr = t.fr - TSK
		--e.speed = 0
		if t.fr <= 0 then DOM[m] = nil end
	end
end end		if cf.Spd then event.register("calcMoveSpeed", CALCMOVESPEED) end

local function JUMP(e)	local m = e.mobile	if m == mp then
local Kstat = 150 + m:getSkillValue(20) + m.agility.current/2 + (P.acr1 and 50 or 0) + m.jump * (P.alt24 and 20 or 15)
local Kstam = math.min(math.lerp((P.atl13 and 0.6 or 0.3), 1, m.fatigue.normalized), 1)
local Kenc = (1 - math.min(m.encumbrance.normalized,1) * (P.atl6 and 0.5 or 0.8)) * math.min(D.AR.ms + math.max(-m.encumbrance.currentRaw,0)/2000, 1)
e.velocity = e.velocity:normalized() * Kstat * Kstam * Kenc

--local vec = tes3.getPlayerEyeVector():normalized()	vec.z = 0.2
--e.velocity = vec * 1000

--tes3.messageBox("Jump! %d = %d stat * %d%% stam * %d%% enc   %d", e.velocity.z, Kstat, Kstam*100, Kenc*100, e.velocity.x)
else e.velocity = e.velocity:normalized() * (250 + m:getSkillValue(20) + m.agility.current/2 + m.jump*20)
	tes3.messageBox("Jump npc! z = %d   x = %d", e.velocity.z, e.velocity.x)
end end		event.register("jump", JUMP)


local function CALCARMORRATING(e) local m = e.mobile	if m then	local a = e.armor
	e.armorRating = a.armorRating * (1 + m:getSkillValue(AT[a.weightClass].s)/((m ~= mp or P[AT[a.weightClass].p]) and 100 or 200)) * (a.weight == 0 and 0.5 + m:getSkillValue(13)/((m ~= mp or P.con9) and 200 or 400) or 1)
e.block = true end end		event.register("calcArmorRating", CALCARMORRATING)

L.ADIR = {[0] = 2, [4] = 2}
-- Для ближнего боя хит это первое событие. Определяются таргет, направление атаки и свинг, НО физдамаг все еще старый на момент завершения события - он обновится сразу после события и уже учтет силу и прочность оружия
-- Свинг можно менять только для ближнего боя.	ad.physicalDamage бесполезно менять и для ближнего и для дальнего боя. В событии дамага ad.physicalDamage для дальнего боя отображается неверно.
local function CALCHITCHANCE(e) local a = e.attackerMobile	local t = e.targetMobile	local ad = a.actionData
local chance = 100 + a.agility.current - a.blind - (t.chameleon + t.invisibility*300)*((t ~= mp or P.snek7) and 0.5 or 0.25)
if t == mp then		local extra = 0		local sanct = t.sanctuary/5 * (1+(P.una11 and D.AR.u*0.01 or 0))
	if L.ADIR[ad.attackDirection] then L.skarm = math.max((a.object.level * 4 + 20 - p.object.level/2) / (a.object.level + 20) * ad.physicalDamage/50, 0) end	-- Назначаем опыт доспехов для снарядов
	local dodge = (P.lig8 and D.AR.l > 19 and t.isRunning or ((t.isMovingLeft or t.isMovingRight) and not t.isMovingForward)) and
	math.min(math.min(t.fatigue.normalized,1) * (D.AR.dk > 1 and D.AR.dk or math.min(D.AR.dk + math.max(-mp.encumbrance.currentRaw,0)/1000, 1))
	* (t.agility.current*(P.agi20 and 0.3 or 0.2) + (P.luc3 and t.luck.current/10 or 0)) + sanct + (P.acr6 and t.isJumping and t:getSkillValue(20)/5 or 0), 100) or 0
	local DodK = T.Dod.timeLeft and (T.Dod.timeLeft - (P.spd17 and 2.3 or 2.5))/(P.spd17 and 0.7 or 0.5) or 0
	if DodK > 0 then extra = (t.agility.current/(1+t.agility.current/400)/(P.agi2 and 8 or 16) + (P.lig2 and D.AR.l * t:getSkillValue(21)/100 or 0) + (P.agi23 and W.DWM and 10 or 0) + sanct) * (P.spd2 and 2 or 1) * DodK
		L.skarm = math.max((a.object.level * 4 + 20 - p.object.level/2) / (a.object.level + 20) * ad.physicalDamage/50, 0)		mp:exerciseSkill(21, D.AR.l/100)	mp:exerciseSkill(17, D.AR.u/100)
	end
	e.hitChance = chance - dodge - extra		--tes3.messageBox("Hit chance = %d%% (%.1f - %.1f passive - %.1f active (x%.2f))   tim = %s", e.hitChance, chance, dodge, extra, DodK, T.Dod.timeLeft)
	if cf.m3 and dodge + extra > 0 then tes3.messageBox("Hit chance = %d%% (%.1f - %.1f passive - %.1f active (x%.2f))", e.hitChance, chance, dodge, extra, DodK) end
else e.hitChance = chance - t.sanctuary/2	--	local r = e.target
end
if a ~= mp and not L.ADIR[ad.attackDirection] then local sw = math.random(50,100)/100		ad.attackSwing = sw
	a.animationController.weaponSpeed = a.animationController.weaponSpeed * (1.25 - sw/2)
end
--	tes3.messageBox("HIT!  dir = %s  swing = %.2f  dmg = %.2f   spd = %.3f", ad.attackDirection, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed)
--	local pos = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*150		local post = e.target.sceneNode:getObjectByName("Bip01 Head").worldTransform.translation
--	tes3.createReference{object = "4nm_boundstar", position = pos, cell = p.cell}	tes3.createReference{object = "4nm_boundstar", position = post, cell = p.cell, scale = 2}
end		if cf.hit then event.register("calcHitChance", CALCHITCHANCE) end


-- Первое событие для дальнего боя: менять свинг: он уже не изменится при хите, который идет после атаки. Для ближнего боя идет сразу после хита. Дамаг НЕ определен если не было события хита.
-- Можно менять ad.physicalDamage для ближнего боя и это сработает. Но ad.physicalDamage не поменяется для дальнего боя.
local function ATTACK(e) local a = e.mobile	local ar = e.reference	local w = a.readiedWeapon	local ob = w and w.object	local wt = w and (a == mp and W.wt or ob.type) or -1	local ad = a.actionData		local t = e.targetMobile
if a.fatigue.normalized < 1 then local stret = a ~= mp and 10 or ((P[WT[wt].p3] and a:getSkillValue(WT[wt].s)/20 or 0) + (P.end6 and math.min(a.endurance.current/20, 5) or 0))
if stret > 0 then a.fatigue.current = a.fatigue.current + stret end end

if a == mp and w then	local wd = w.variables
	if ob.weight == 0 then
		if ob.id:sub(1,7) == "4_bound" and not tes3.isAffectedBy{reference = p, effect = 603} then timer.delayOneFrame(function() mp:unequip{item = ob}	timer.delayOneFrame(function()
			for _, st in pairs(inv) do if st.object.objectType == tes3.objectType.weapon and st.object.weight == 0 and st.object.id:sub(1,7) == "4_bound" then tes3.removeItem{reference = p, item = st.object} end end
		end) end) return end
	elseif ob.isMelee and MB[cf.mbmet] == 128 then	local ow = ob.weight	local kw = ow/(1 + ow/20) * (P.str12 and 0.05 or 0.075)
		local sdmg = math.max(math.max(ob.chopMax, ob.thrustMax) * math.max(wd.condition/ob.maxCondition, P.arm2 and 0.3 or 0.1), ob.weight/2) * (P.mark13 and 0.75 or 0.5)
		local Kstr = mp.strength.current/(P.str1 and 1 or 2)		local Kstam = (50 + (P.end1 and 0 or 10) + (P.mark2c and 0 or 20)) * math.max(1-mp.fatigue.normalized,0)
		local Kskill = mp:getSkillValue(23) * ((P.mark1c and 0.2 or 0.1) + (P[WT[wt].h1 and "agi5" or "str2"] and 0.1 or 0.05))		local Kbonus = mp.attackBonus/5		
		local DMag = math.min(tes3.getEffectMagnitude{reference = p, effect = 600}, cf.metlim)		local mc = 0	local Kkin = 0
		if DMag > 0 then mc = DMag * (P.alt17 and 0.5 or 1)		if mp.magicka.current > mc then Kkin = DMag * (Cpow(mp,0,4,true) + (P.alt16 and 50 or 0))/2000 / (1 + ow/10) 	Mod(mc) end end
		W.acs = math.clamp(ad.attackSwing * (100 + Kstr - Kstam)/100 - kw + Kkin, 0.5, 4)
		W.metd = sdmg * (Kkin + ad.attackSwing * (100 + Kstr - Kstam + Kskill + Kbonus)/100)
		W.met = tes3.dropItem{reference = p, item = ob, itemData = wd}		if W.DWM then L.DWMOD(false) end
		if cf.m then tes3.messageBox("Throw %s!  Acs = %.2f (%.2f w)  Dmg = %.1f (%.1f +%d%% str -%d%% stam +%d%% skill +%d%% atb)  Kin = %.2f (%d cost)", ob.name, W.acs, kw, W.metd, sdmg, Kstr, Kstam, Kskill, Kbonus, Kkin, mc) end
		tes3.applyMagicSource{reference = p, name = "4nm_met", effects = {{id = 610, rangeType = 2}}}	return
	end
	
	if W.f == 1 and ob == W.ob and (wt > 8 or not t) then tes3.applyMagicSource{reference = p, source = ob.enchantment, fromStack = w} end
	
	if wt == 10 then
		if T.Arb.timeLeft then ad.attackSwing = 0.5		T.Arb:cancel() else ad.attackSwing = 1 end
		--	if MB[3] == 128 then mp.animationController.weaponSpeed = 1000000 end
		--	if mp.readiedAmmo and BAM[mp.readiedAmmo.object.id] then BAM.am = mp.readiedAmmo.object.id	if P.con17 or tes3.isAffectedBy{reference = p, effect = 601} then mc = BAM.f()
		--		BAM.E[1].id = MID[math.random(3)]	BAM.E[1].min = math.random(5) + mp:getSkillValue(10)/20		BAM.E[1].max = BAM.E[1].min*2		BAM.E[1].radius = math.random(5) + L.GetRad(mp)
		--		if cf.autoammo and mp.magicka.current > mc then	mp.readiedAmmoCount = 2		tes3.addItem{reference = p, item = BAM.am, count = 1, playSound = false}	Mod(mc) end
		--	end end
	elseif P.str8 and ob.isTwoHanded and ad.attackDirection == 1 and ad.attackSwing > 0.95 then local dist = 150 * ob.reach
		local dmg = ob.slashMax/2*(1 + mp.strength.current/200) * math.max(wd.condition/ob.maxCondition, P.arm2 and 0.3 or 0.1)
		timer.start{duration = 0.2/ob.speed, callback = function()	local fdmg	local num = 0
			for _, m in pairs(tes3.findActorsInProximity{reference = p, range = dist}) do if m ~= mp and m ~= t and tes3.getCurrentAIPackageId(m) ~= 3 then	num = num + 1
				if m.actionData.animationAttackState == 4 and m.readiedWeapon and m.readiedWeapon.object.type < 9 then m.actionData.animationAttackState = 0
					local tab = L.PSO[WT[wt].pso][WT[m.readiedWeapon.object.type].pso]		tes3.playSound{reference = m.reference, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2]))}
				else fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true, resistAttribute = not (ob.enchantment or ob.ignoresNormalWeaponResistance) and 12 or nil}		L.CrimeAt(m) end
				if cf.m then tes3.messageBox("Round attack! %s (%d)  Dmg = %d/%d",  m.object.name, num, fdmg, dmg) end
			end end
		end}
	elseif W.DWM and T.DWB.timeLeft then T.DWB:cancel() end
elseif a ~= mp then
	if ad.attackDirection == 4 then ad.attackSwing = wt == 10 and 1 or math.random(70,100)/100
		if cf.ammofix and a.readiedAmmoCount == 0 then a.readiedAmmoCount = 1	if cf.m then tes3.messageBox("AMMO FIX!") end end
	else
		if cf.pvp then L.DodM(ar, a) end
		if t == mp then L.skarm = math.max((a.object.level * 4 + 20 - p.object.level/2) / (a.object.level + 20) * ad.physicalDamage/50, 0) end
	end
end

if ar.data.CW then local rt = (a ~= mp and 2) or (not D.CWdis and not (cf.smartcw and wt > 8) and (D.CWm and 2 or (t and t.playerDistance < 192 and 1)))
	if rt == 2 then timer.delayOneFrame(function() L.CWF(ar, 2, 1.5) end) elseif rt == 1 then L.CWF(ar, 1, 1) end
end
--tes3.messageBox("ATA!  ref = %s  wt = %s  dir = %s  swing = %.2f  dmg = %.2f  spd = %.3f  tar = %s  Ammo = %s %s",
--ar, wt, ad.attackDirection, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed, e.targetReference, a.readiedAmmo and a.readiedAmmo.object, a.readiedAmmoCount)
end		event.register("attack", ATTACK)



-- Вызывается после атаки для ближнего боя и после хита для дальнего. Можно менять слот, по которому попадет удар. Далее идёт дамаг. НЕ вызывается если попали по щиту или кричеру.
local function CALCARMORPIECEHIT(e) local s = tes3.getEquippedItem{actor = e.reference, objectType = tes3.objectType.armor, slot = e.slot}
if not s and e.fallback then s = tes3.getEquippedItem{actor = e.reference, objectType = tes3.objectType.armor, slot = e.fallback} end
arm = s and s.object:calculateArmorRating(e.mobile) or 0		arp = s and s.object.weightClass or 3
--e.slot = 0		tes3.messageBox("ARM! ref = %s  slot = %s  fall = %s", e.reference, e.slot, e.fallback)
end		event.register("calcArmorPieceHit", CALCARMORPIECEHIT)


L.AD = {[1] = {"slashMin", "slashMax"}, [2] = {"chopMin", "chopMax"}, [3] = {"thrustMin", "thrustMax"}, [4] = {"chopMin", "chopMax"}, [5] = 1, [6] = 1, [7] = 1, [0] = {"chopMin", "chopMax"}}
local function DAMAGE(e) if e.source == "attack" then local a = e.attacker	local t = e.mobile	local ar = e.attackerReference	local tr = e.reference	local ad = a.actionData		local tad = t.actionData
local rw = a.readiedWeapon		local pr = e.projectile		local Arm = t.armorRating		local Mult, Kstam, Kperk, Kstr, Kskill, Kbonus, Kdash = 100, 1, 0, 0, 0, 0, 0
local WS, WD, SD, Norm		local w = pr and pr.firingWeapon or (rw and rw.object)	local wt = w and (not pr and a == mp and W.wt or w.type) or -1			local Res = t.resistNormalWeapons	local magw
local sw = ad.attackSwing	 local dir = ad.attackDirection		local Agi = a.agility.current		local Tagi = t.agility.current		local bid = ar.baseObject.id
local BaseHP = t.health.base	local fat = math.min(t.fatigue.normalized,1)
if t.actorType == 0 then arm = t.shield		arp = nil	end
if a.actorType == 0 then WS = a.combat.current		if not w then Kperk = (1 - a.health.normalized) * WS/2		WD = 10 * sw end
else WS = a:getSkillValue(WT[wt].s)	end
local Armult = 1 - (pr and (arp == 2 and (t ~= mp or P.hev14) and -0.2 or 0) or (w and math.min(w.weight,30)/((a ~= mp or P.str11) and 100 or 200) or 0))

if pr then SD = pr.damage		WD = SD		magw = (pr.reference.object.ignoresNormalWeaponResistance or pr.reference.object.enchantment) and 100 or 0
else
	if L.AD[dir] == 1 then WD = ar.object.attacks[1].max * sw		magw = 50
	elseif w then local Cond = rw.variables.condition/w.maxCondition		magw = (w.ignoresNormalWeaponResistance or w.enchantment) and 100 or 0
		WD = math.lerp(w[L.AD[dir][1]], w[L.AD[dir][2]], sw) * (Cond > 1 and Cond or math.lerp((a ~= mp or P.arm2) and 0.3 or 0.2, 1, Cond))
		* (w.weight == 0 and 1 + a:getSkillValue(13)*((a ~= mp or P.con8) and 0.003 or 0.002) or 1)
	elseif not WD then
		local gau = (a ~= mp or P.hand7) and tes3.getEquippedItem{actor = ar, objectType = tes3.objectType.armor, slot = dir == 3 and 6 or 7} or nil		gau = gau and gau.object.weight*(0.3 + WS/500) or 0
		WD = sw * (a.werewolf and 40 or ((a ~= mp or P.str14) and 10 or 5) + gau)
	end
	Kstr = 100 + a.strength.current * ((a ~= mp or P.str1) and 0.5 or 0.4)
	Kskill = WS * (((a ~= mp or P[WT[wt].p1]) and 0.2 or 0.1) + ((a ~= mp or P[WT[wt].h1 and "agi5" or "str2"]) and 0.1 or 0.05))
	Kbonus = a.attackBonus/5 + (a == mp and 0 or ar.object.level)
	Kstam = math.min(math.lerp(((a ~= mp or P.end1) and 0.4 or 0.3) + ((a ~= mp or P[WT[wt].p2]) and 0.2 or 0), 1, a.fatigue.normalized*1.1), 1)
	Kdash = a == mp and (T.Dash.timeLeft or 0) > 2 and V.dd/(P.str9 and 50 or 100) or 0
	SD = WD * (Kstr + Kskill + Kbonus)/100 * Kstam
end

--if Res > 0 then Norm = magw and 1 or (1 - math.min(Res/(100 + Res/2), 1)) else Norm = 1 - Res/100 end
if Res > 0 then Norm = 1 - math.clamp(Res - (magw or 0), 0, 100)/100 else Norm = 1 - Res/100 end


local as = (a.isMovingForward and wt < 9 and 1) or (a.isMovingLeft or a.isMovingRight and 2) or (a.isMovingBack and wt < 9 and 3) or 0
local ts = (t.isMovingForward and 1) or (t.isMovingLeft or t.isMovingRight and 2) or (t.isMovingBack and 3) or 0
local hs = 100 + (WS + a.strength.current + Agi)/((a ~= mp or P.str13) and 10 or 20) + (as == 1 and (a ~= mp or P.str3) and 20 or 0) + (a == mp and math.min(com, G.maxcomb) * (P.agi9 and 10 or 5) or 0)
+ ((a ~= mp or P.str4 and sw > 0.95) and 20 or 0) + (ts == 1 and (not (t == mp and P.med10 and D.AR.m > 19) and 30 or 0) - (arp == 1 and (t ~= mp or P.med8) and t:getSkillValue(2)/5 or 0) or 0)
- (arp == 2 and (t ~= mp or P.hev8) and t:getSkillValue(3)/5 or 0) - (t == mp and P.hev12 and D.AR.h or 0)
- (t.endurance.current)/((t ~= mp or P.end5) and 5 or 10) - Tagi/((t ~= mp or P.agi26) and 5 or 10) - (ts == 0 and (t ~= mp or P.str5) and t.strength.current/10 or 0)


local CritC = (pr and a.attackBonus/5 + (a == mp and 0 or ar.object.level) or Kbonus)
+ Agi/((a ~= mp or P.agi1) and 10 or 20) + WS/((a ~= mp or P[WT[wt].p6]) and 10 or 20) + ((a ~= mp or P.luc1) and a.luck.current/20 or 0) + (as == 1 and (a ~= mp or P.spd3) and 10 or 0)
+ (ts == 1 and ((t == mp and P.med10 and D.AR.m > 19 and 0 or 10) + ((t ~= mp or P.agi7) and 0 or 10)) or 0) + (t == mp and arp == 3 and math.max(20 - t:getSkillValue(17)/(P.una13 and 5 or 10), 0) or 0)
+ (a == mp and math.min(com, G.maxcomb) * (P.agi6 and 5 or 3) + (wt == 2 and P.long10 and Kdash/2 or 0) + (wt < 9 and a.isJumping and P.acr4 and a:getSkillValue(20)/10 or 0) - 10 or 10)
- (t.endurance.current + Tagi)/((t ~= mp or P.end3) and 20 or 40) - ((t ~= mp or P.luc2) and t.luck.current/20 or 0) - arm/10 - t.sanctuary/10
+ (1 - fat)*((a ~= mp or P.agi11) and 20 or 10) - (t == mp and ts == 0 and P.hev11 and D.AR.h or 0)
- (arp == 0 and ts ~= 0 and (t ~= mp or P.lig7) and t:getSkillValue(21)/10 or 0) - (arp == 1 and ts == 3 and (t ~= mp or P.med7) and t:getSkillValue(2)/10 or 0) - (arp == 2 and (t ~= mp or P.hev7) and t:getSkillValue(3)/10 or 0)

local dist
if w then
	if a ~= mp or P[WT[wt].p] then
		if wt > 8 then dist = ar.position:distance(tr.position)
			if wt == 9 then Kperk = dist * WS/20000 -- Луки 5% за каждую 1000 дистанции
			elseif wt == 10 then Kperk = WS * ((a ~= mp or P.mark9) and math.max(1000 - dist,0)/5000 or 0)		Armult = Armult - WS*0.003
				if a ~= mp or P.mark9 then hs = hs + WS * math.max(3000 - dist,0)/6000 end		--pr.attackSwing
			elseif wt == 11 then if not A[ar] then A[ar] = {met = -1} end
				if (A[ar].met or -1) < ((a ~= mp or P.mark10) and 10 or 5) then A[ar].met = (A[ar].met or -1) + 1 end		Kperk = A[ar].met * WS/20
				if A[ar].mettim then A[ar].mettim:reset() else A[ar].mettim = timer.start{duration = a == mp and 1 + (P.mark8 and WS/200 or 0) or 2 + WS/100, callback = function() A[ar].met = -1	A[ar].mettim = nil end} end
			end
		else
			if wt > 6 then	if not A[ar] then A[ar] = {axe = -1} end
				if (A[ar].axe or -1) < ((a ~= mp or P.axe10) and 10 or 5)  then A[ar].axe = (A[ar].axe or -1) + 1 end		
				if not A[ar].axetim then A[ar].axetim = timer.start{duration = a == mp and 1 + (P.axe11 and WS/200 or 0) or 2 + WS/100, iterations = -1, callback = function()
					A[ar].axe = A[ar].axe - 1		if A[ar].axe < 0 then A[ar].axetim:cancel()	A[ar].axetim = nil end
				end} end
				Kperk = A[ar].axe * WS/20		if a ~= mp or P.axe7 then CritC = CritC + A[ar].axe * WS/50 end
			elseif wt == 6 or wt == -2 then Kperk = (1 - fat) * WS * 0.3
				if dir == 3 and (a ~= mp or P.spear11 and sw > 0.95) then CritC = CritC + 10 end
			elseif wt == 5 or wt == -3 then Kperk = math.min(a.magicka.normalized, 1) * WS * 0.3
			elseif wt > 2 then hs = hs + WS/((a ~= mp or P.blu7) and 2 or 4)		Armult = Armult - WS*0.003
			elseif wt > 0 then if not A[ar] then A[ar] = {long = 0} end
				if A[ar].longtim then A[ar].longtim:reset() else A[ar].longtim = timer.start{duration = a == mp and 0.8 + (P.long7 and WS/250 or 0) or 1.5 + WS/200, callback = function() A[ar].long = 0	A[ar].longtim = nil end} end
				if (A[ar].long or 0) < 2 then A[ar].long = (A[ar].long or 0) + 1 else A[ar].long = 0	Kperk = WS/2		if (a ~= mp or P.long12) then hs = hs + WS/2		CritC = CritC + WS/10 end end
			elseif wt == 0 then Kperk = (1 - t.health.normalized) * WS * 0.3	if a ~= mp or P.short11 then CritC = CritC + (1 - fat) * WS/5 end
				if a == mp and P.short10 and sw < 0.3 then mp.animationController.weaponSpeed = 1000000 end		--ad.animationAttackState = 0
			end
		end
	end
	if (a ~= mp or P.bloc11) and A[tr] and A[tr].part then	local bls = a:getSkillValue(0)	Kperk = Kperk + bls*0.2		if a ~= mp or P.bloc12 then CritC = CritC + bls/10 end	end
end


if a == mp then
	if P.str15 then Mult = Mult + 20 * math.max(1 - mp.health.normalized, 0) end
	if not R[tr] or not R[tr].cm then if pr then
		if P.mark14 and math.max(math.abs(t:getViewToActor(mp)),50) * dist * (mp.isSneaking and 2 or 1) > (P.snek8 and 50000 or 100000) then
			Mult = Mult + 50		Armult = Armult - (P.snek13 and 0.3 or 0.1)			mp:exerciseSkill(19, 1 + tr.object.level/10)
		end
	elseif math.abs(t:getViewToActor(mp)) > (P.snek8 and 135 or 150) then	Armult = Armult - (P.snek13 and 0.3 or 0.1) - (wt == 0 and 0.2 or 0)
		Mult = Mult + 100 + (P.snek3 and mp.isSneaking and 100 or 0) + ((wt == 0 and P.short12) and 100 or 0)	mp:exerciseSkill(19, 1 + tr.object.level/5)
	end end
	if ((P.con12 and t.object.type == 1) or (P.con13 and t.object.type == 2)) then Mult = Mult + mp:getSkillValue(13)/10 end
	if w then
		if wt < 9 then
			if T.Comb.timeLeft then		local maxcom = (P[WT[wt].pc] and 4 or 3) + math.floor(WS/50) + (P.spd14 and W.DWM and 1 or 0)
				if dir == last then com = math.max(com - 2, 0) elseif dir == pred and com > 2 then com = com - 1 elseif dir ~= pred then com = math.min(com + 1, maxcom) end
				M.CombK.text = ("%s/%s"):format(com, maxcom)		T.Comb:reset()	pred = last		last = dir
			else last = dir		T.Comb = timer.start{duration = (P.spd4 and 2 or 1.5) + (WT[wt].s == 5 and P.long11 and 0.5 or 0), callback = function() com = 0	last = nil	pred = nil	M.CombK.text = "" end} end
		end
		if T.CST.timeLeft then local bls = a:getSkillValue(0)		Kperk = Kperk + bls*0.2	if P.bloc5 then hs = hs + bls/2		CritC = CritC + bls/10 end		if cf.m3 then tes3.messageBox("Counterstrike!") end end
	end
else
	if t ~= mp and L.Summon[bid] then Mult = Mult - 30 end
	local MagAt = L.CMAG[bid]		if MagAt and MagAt[2] > math.random(100) then tes3.applyMagicSource{reference = ar, source = B[MagAt[1]]} end
end


local tw = t.readiedWeapon		local two = tw and tw.object		local twt = two and two.type or -1		local tsh = t.readiedShield	
if tad.animationAttackState == 4 then
	if pr and t == mp and P.bloc18 and tw and twt < 9 then	local ang = math.abs(mp:getViewToPoint(pr.position))
		local bloc = (t:getSkillValue(0) + t:getSkillValue(WT[twt].s)/2 + Tagi/5 + t.luck.current/10) * fat * math.clamp(t.animationController.weaponSpeed - 0.5, 0.2, 1) - WS/2 - Agi/5
		if cf.m3 then tes3.messageBox("Weapon block projectile chance = %d%%   Angle = %d", bloc, ang) end
		if ang < 20 and bloc > math.random(100) then
			mp:exerciseSkill(0, 2)		tes3.playSound{reference = p, soundPath = ("Fx\\par\\1_%s.wav"):format(math.random(4))}
			G.KOGMST.value = 100	e.damage = 0	 return
		end
	elseif (a == mp and not D.nopar or (a ~= mp and cf.par)) then		
		--if t == mp then tes3.messageBox("Angle %d ", math.abs(mp:getViewToActor(a))) end
		if wt < 9 and w and tw and twt < 9 then
			local Tdash = (t == mp and (T.Dash.timeLeft or 0) > 2 and V.dd/(P.str9 and 50 or 100) or 0) * 3
			local PK1 = (w.weight*5 + WS + a.strength.current + Agi + a:getSkillValue(0) + Kbonus*2 + Kdash*2) * (a == mp and sw or 0.3 + sw) * Kstam
			* ((WT[wt].h1 and 0.5 or 0.75) + ((a ~= mp or P.bloc10) and 0.25 or 0) + ((a ~= mp or P[WT[wt].p9]) and 0.25 or 0))
			local PK2 = (two.weight*10 + t:getSkillValue(WT[twt].s) + t.strength.current + Tagi + t.attackBonus + Tdash)
			* ((WT[twt].h1 and 0.5 or 0.75) + ((t ~= mp or P.str6) and 0.25 or 0)) * tad.attackSwing * (t == mp and math.clamp(t.animationController.weaponSpeed - 0.5, 0.2, 1) or 1)
			local park = PK1 / PK2
			rw.variables.condition = math.max(rw.variables.condition - tad.physicalDamage / ((a ~= mp or P.arm3) and 20 or 10), 0)
			tw.variables.condition = math.max(tw.variables.condition - ad.physicalDamage / ((t ~= mp or P.arm3) and 20 or 10), 0)
			if not A[tr] then A[tr] = {} end
			if park > 0.8 then
				tad.animationAttackState = 0	--	if t == mp then MB[1] = 0 end
				if t == mp then MB[1] = 0 else tes3.playAnimation{reference = tr, group = tes3.animationGroup[(t.actorType == 1 or t.object.biped) and table.choice{"hit2", "hit3", "hit4", "hit5"} or "hit1"], loopCount = 0} end
				
				local min = (a == mp and (P.bloc14 and 0.2 or 0.1)) or (t == mp and (P.agi26 and 0.1 or 0.2)) or 0.2
				local max = (a == mp and (P.bloc14 and 1 or 0.5)) or (t == mp and (1 - math.min(Tagi,100)/(P.agi26 and 200 or 500))) or 1
				A[tr].part = timer.start{type = timer.game, duration = math.clamp(park - 1, min, max)*G.sis, callback = function() if park < 2 then
					if t == mp then if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
					else tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}		tad.animationAttackState = 0 end
				end A[tr].part = nil end}
				
			--	A[tr].part = timer.start{type = timer.game, duration = math.clamp(park - 1, min, max)*G.sis,
			--	callback = function() if park < 2 and tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end		A[tr].part = nil end}
				

				if a == mp and P.sec7 then tes3.applyMagicSource{reference = p, name = "Parry", effects = {{id = 510, min = 30, max = 30, duration = 1}}} end
			else
				A[tr].park = 1 - park		A[tr].fiz = tad.physicalDamage		--wc.systemTime
			end
			local parcost = ((a ~= mp or P.bloc13) and 10 or 20) * math.min(PK2/PK1, 1)		a.fatigue.current = math.max(a.fatigue.current - parcost, 0)
			
			if cf.m3 then tes3.messageBox("Par! %s (%s)    %.2f = %d/%d    fiz = %.2f/%.2f    spd = %.2f   Cost = %d", ar.baseObject.name, tad.animationAttackState, park, PK1, PK2, ad.physicalDamage, tad.physicalDamage,
			t.animationController.weaponSpeed, parcost) end
			if t ~= mp then for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end end
			local tab = L.PSO[WT[wt].pso][WT[twt].pso]		tes3.playSound{reference = (a==mp or t==mp) and p or ar, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2]))}
			
			if a == mp then L.skw = math.max((tr.object.level * 4 + 20 - p.object.level/2) / (tr.object.level + 20) * tad.physicalDamage/200 * math.min(park,2), 0)	L.skarm = L.skw*2	mp:exerciseSkill(0, 1)
				if not P.bloc15 then com = math.max(com - 1, 0)		M.CombK.text = ("%s"):format(com) end
			end
			
			G.KOGMST.value = 100	e.damage = 0	 return
		end
	end
elseif t == mp and tad.animationAttackState == 2 and W.DWM and wt < 9 and w then
	if T.DWB.timeLeft and math.abs(mp:getViewToActor(a)) < (P.bloc17 and 30 or 20) then		local bls = t:getSkillValue(0)		local WTL = WT[W[W.WL.id] or W.WL.type]
		local PK1 = (W.WL.weight*5 + t:getSkillValue(WTL.s) + t.strength.current + Tagi + bls) * math.lerp((P.bloc19 and 0.6 or 0.3), 1, fat) * ((P.bloc10 and 0.75 or 0.5) + (P[WTL.p9] and 0.25 or 0))
		local PK2 = (w.weight*10 + WS + a.strength.current + Agi + Kbonus*3) * math.random(80,120)/100 * (WT[wt].h1 and 0.75 or 1)
		local park = PK1 / PK2
		local parcost = (P.bloc13 and 10 or 20) * math.min(PK2/PK1, 2)		mp.fatigue.current = math.max(mp.fatigue.current - parcost, 0)
		W.DL.condition = math.max(W.DL.condition - ad.physicalDamage / (P.arm3 and 10 or 5), 0)
		local tab = L.PSO[WT[wt].pso][WTL.pso]		tes3.playSound{reference = p, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2]))}
		L.skarm = math.max((ar.object.level * 4 + 20 - p.object.level/2) / (ar.object.level + 20) * ad.physicalDamage/100 * math.min(park,2), 0)	mp:exerciseSkill(0, 1)
		if cf.m3 then tes3.messageBox("DW Block!  %.2f = %d/%d   cost = %d   time left = %.2f   angle = %d", park, PK1, PK2, parcost, T.DWB.timeLeft/G.sis, math.abs(mp:getViewToActor(a))) end
		if park > 0.8 then
			if T.CST.timeLeft then T.CST:reset() elseif P.bloc4 then T.CST = timer.start{type = timer.game, duration = (0.4 + (P.bloc8 and (Tagi + bls)/1000 or 0))*G.sis, callback = function() end} end
			G.KOGMST.value = 100	e.damage = 0	 return
		else SD = SD * (1 - park) end
	elseif cf.m3 then tes3.messageBox("No DW block  time left = %.2f   angle = %d", (T.DWB.timeLeft or 0)/G.sis, math.abs(mp:getViewToActor(a))) end
end
if A[ar] and A[ar].park and A[ar].fiz == ad.physicalDamage then SD = SD * A[ar].park	A[ar].park = nil end



--[[
if L.ASP[tad.animationAttackState] then
	local tw = t.readiedWeapon		local two = tw and tw.object			--if t == mp then tes3.messageBox("Angle %d ", math.abs(mp:getViewToActor(a))) end
	if wt < 9 and w and tw and two.isMelee and (t ~= mp or math.abs(mp:getViewToActor(a)) < 100) then		local twt = two.type
	
		local PK1 = (w.weight*10 + WS + a.strength.current + Agi) * sw
		local PK2 = (two.weight*20 + a:getSkillValue(0) + t:getSkillValue(WT[twt].s) + t.strength.current + Tagi) * tad.attackSwing
		local park = PK1 / PK2
		
	--	rw.variables.condition = math.max(rw.variables.condition - PK2 / ((a ~= mp or P.arm3) and 400 or 200), 0)
	--	tw.variables.condition = math.max(tw.variables.condition - PK1 / ((a ~= mp or P.arm3) and 400 or 200), 0)
		
		if park < 1 then
			ad.animationAttackState = 0		if a == mp then MB[1] = 0 end
			tes3.playAnimation{reference = ar, group = tes3.animationGroup[table.choice{"hit2", "hit3", "hit4", "hit5"}], loopCount = 0}
			
			timer.start{duration = math.max(1 - park, 0.1), callback = function()
				tes3.playAnimation{reference = ar, group = 0x0, loopCount = 0}		ad.animationAttackState = 0
				--if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
			end}
			if t == mp and P.sec6 then tes3.applyMagicSource{reference = p, name = "Parry", effects = {{id = 510, min = 30, max = 30, duration = 1}}} end
			if t ~= mp then for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end end
			
			local tab = L.PSO[WT[wt].pso][WT[twt].pso]		tes3.playSound{reference = ar, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2]))}
			tes3.messageBox("Par! %s    %.2f = %d/%d   sw = %.2f/%.2f   fiz = %.2f/%.2f", tr.object.name, park, PK1, PK2, sw, tad.attackSwing, ad.physicalDamage, tad.physicalDamage)
			G.KOGMST.value = 100	e.damage = 0	 return
		--else
		--	if not A[tr] then A[tr] = {} end	A[tr].park = 1 - park				A[tr].fiz = tad.physicalDamage		--wc.systemTime
		end
	end
end
--]]

--[[
if a == mp then
	tes3.messageBox("Dmg!  %s   par = %s", t.actionData.animationAttackState, L.ASP[t.actionData.animationAttackState] == 1)
	if L.ASP[t.actionData.animationAttackState] == 1 and not tr.data.nopar then
		local parc = M.drop.visible and 110 or 0
		if parc > math.random(100) then
			t.actionData.animationAttackState = 0
			
			--tr.data.nopar = true
			--tes3.playAnimation{reference = tr, group = tes3.animationGroup[table.choice{"hit2", "hit3", "hit4", "hit5"}], loopCount = 0}
			timer.start{duration = 0.7, callback = function() --tes3.messageBox("Allow! %s", t.actionData.animationAttackState)
				if t.actionData.animationAttackState == 1 and not L.AG[t.actionData.currentAnimationGroup] then t.actionData.animationAttackState = 0 end
			
			--	tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}		t.actionData.animationAttackState = 0
				--t.animationController.weaponSpeed = 1000000
			--	tr.data.nopar = nil
			end}
			
			
			for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end		G.KOGMST.value = 100
			tes3.playSound{soundPath = "Fx\\Par\\blade1hand_parry_00" .. table.choice{1,2,3,4} .. ".wav"}		e.damage = 0	 return
		else
			t.actionData.animationAttackState = 0
			timer.start{duration = 0.2, callback = function()
				if t.actionData.animationAttackState == 1 and not L.AG[t.actionData.currentAnimationGroup] then t.actionData.animationAttackState = 0 end
			end}
			for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end		G.KOGMST.value = 100
			tes3.playSound{soundPath = "Fx\\Par\\blade1hand_parry_00" .. table.choice{1,2,3,4} .. ".wav"}		DMG = 0		tr.data.park = 0		e.damage = 0	 return
		end
--	elseif tr.data.park then DMG = DMG * tr.data.park		tr.data.park = nil
--		for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end
--		tes3.playSound{soundPath = "Fx\\Par\\blade1hand_parry_00" .. table.choice{1,2,3,4} .. ".wav"}
	end
	
	
elseif t == mp and cf then
	tes3.messageBox("Enemy!  %s   par = %s", mp.actionData.animationAttackState, L.ASP[mp.actionData.animationAttackState] == 1)
	if L.ASP[t.actionData.animationAttackState] == 1 and not D.nopar then
		local parc = M.drop.visible and 110 or 0
		if parc > math.random(100) then
			mp.actionData.animationAttackState = 0		MB[1] = 0
		--	D.nopar = true
		--	timer.start{duration = 0.5, callback = function() D.nopar = nil end}
			tes3.playSound{soundPath = "Fx\\Par\\blade1hand_parry_00" .. table.choice{1,2,3,4} .. ".wav"}		G.KOGMST.value = 100	e.damage = 0	 return
		else
			mp.actionData.animationAttackState = 0		MB[1] = 0
			timer.start{duration = 0.2, callback = function()
				if t.actionData.animationAttackState == 1 and not L.AG[t.actionData.currentAnimationGroup] then t.actionData.animationAttackState = 0 end
			end}
			tes3.playSound{soundPath = "Fx\\Par\\blade1hand_parry_00" .. table.choice{1,2,3,4} .. ".wav"}		DMG = 0		ar.data.park = 0	G.KOGMST.value = 100	e.damage = 0	 return
		end
--	elseif ar.data.park then DMG = DMG * ar.data.park		ar.data.park = nil
--		tes3.playSound{soundPath = "Fx\\Par\\blade1hand_parry_00" .. table.choice{1,2,3,4} .. ".wav"}
	end
end
--]]



local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + ((a ~= mp or P.agi8) and 10 or 0) + ((a ~= mp or P[WT[wt].p5]) and 20 or 0)
if Kcrit > cf.crit then tes3.playSound{reference = tr, sound = "critical damage"} end end

Mult = Mult - math.min(((ts == 3 or (t == mp and P.hev10 and ts == 0 and D.AR.h > 19)) and math.min((Tagi + t.endurance.current)/((t ~= mp or P.end2) and 10 or 20)
+ ((t ~= mp or P.bloc2) and tsh and t:getSkillValue(0)/20 or 0), 30) or 0)
+ (as == 3 and a == mp and math.max(50 - (WS + Agi)/(P.agi19 and 10 or 20) - (wt == 6 and P.spear10 and 10 or 0), 0) or 0)
+ (not tsh and (not tw and (t.actorType ~= 0 and (t ~= mp or P.hand20) and (t:getSkillValue(26)/10 + Tagi/20) or 0) or
((t ~= mp or P.hand9 and not W.DWM) and WT[twt].h1 and (t:getSkillValue(26) + Tagi)/20 or 0)) or 0), 50)	
+ (L.AG[tad.currentAnimationGroup] and 20 + ((a~= mp or P.str14) and 30 or 0) or 0)

local stam = (t == mp and (P.end12 and 1 or 2) + ((ts == 3 or (P.hev10 and ts == 0 and D.AR.h > 19)) and (P.med10 and D.AR.m > 19 and 0 or 1) or 0)
- (ts == 0 and P.hev9 and arp == 2 and mp:getSkillValue(3)/100 or 0) - (ts ~= 0 and P.lig3 and arp == 0 and mp:getSkillValue(21)/200 or 0) - (P.med9 and D.AR.m*0.02 or 0) or 0)
+ (wt == 4 and (a ~= mp or P.blu11 and dir == 1 and sw > 0.95) and 1 or 0)

DMG = SD * (Mult + Kperk + Kcrit + Kdash)/100		local Karm = DMG / (DMG + Arm * math.max(Armult,0))			DMG = DMG * Karm * Norm
hs = (a == mp and 500*DMG/BaseHP or math.max(5*DMG, 500*DMG/BaseHP)) * (hs + Kcrit/2)/100

if pr and tsh then	local ang = t:getViewToPoint(pr.position)		if (t ~= mp or tad.animationAttackState == 2) and math.abs(ang) < 45 or (ang > -90 and ang < 0) then
	local bloc = (t:getSkillValue(0) + Tagi/5 + t.luck.current/10) * fat * ((t ~= mp or P.bloc6) and 1.5 or 1) * ((t ~= mp or tad.animationAttackState == 2) and 1 or 0.3) - WS/2 - Agi/5
	if cf.m3 then tes3.messageBox("Block projectile chance = %d%%   Ang = %d", bloc, ang) end
	if bloc > math.random(100) then tsh.variables.condition = math.max(tsh.variables.condition - DMG/2, 0)
		if t == mp then mp:exerciseSkill(0, 1)	L.UpdShield(tsh) end	if tsh.variables.condition < 0.1 then t:unequip{item = tsh.object} end
		G.KOGMST.value = 100	e.damage = 0		tes3.playSound{reference = tr, soundPath = ("Fx\\par\\sh_%s.wav"):format(math.random(4))}		return
	end
end end

local Dred, KSM, smc, trauma = 0, 0, 0, 0
if tr.data.KS then KSM = Mag(508,tr)	if KSM > 0 then		if t.magicka.current > 5 then	KSM = KSM * (1 + (t == mp and P.una7 and D.AR.u * t:getSkillValue(17)/10000 or 0))
	Dred = math.min(t.magicka.current/4, DMG, KSM)	smc = Dred * (t == mp and (1 + D.AR.l*0.08 + D.AR.m*0.10 + D.AR.h*0.12) * (1 - (arp == 3 and P.una8 and 0.25 or 0) - (P.alt21 and 0.25 or 0)) or 0.5)
	DMG = DMG - Dred		Mod(smc,t)		if arp == 3 then tes3.playSound{reference = tr, sound = "Spell Failure Destruction"} end
end else tr.data.KS = nil end end

if ar.data.LL then local LLM = Mag(509,ar)	if LLM > 0 then		if a.health.normalized < 1 and a.magicka.current > 5 then
	local LLhp = math.min(a.magicka.current/4, LLM/100 * DMG, a.health.base - a.health.current)		mc = LLhp * ((a ~= mp or P.res8) and 0.5 or 1)
	tes3.modStatistic{reference = ar, name = "health", current = LLhp}		Mod(mc,a)
	if a.fatigue.normalized < 1 and (a ~= mp or P.res8) then a.fatigue.current = a.fatigue.current + LLhp*2 end
	if cf.m3 then tes3.messageBox("Life leech for %.1f hp (%.1f damage)  %.1f mag  Cost = %.1f", LLhp, DMG, LLM, mc) end
end else ar.data.LL = nil end end

if cf.traum then
	if stam > 0 and t.fatigue.current > 0 then t.fatigue.current = t.fatigue.current - DMG * stam end
	if DMG/BaseHP > ((t ~= mp or P.end4) and 0.1 or 0.05) then
		trauma = math.random(5 + Kcrit/10 + (sw > 0.95 and (a ~= mp or P.str7) and 10 or 0)) + 50*DMG/BaseHP - (t.endurance.current + t.luck.current + t.sanctuary)/((t ~= mp or P.luc4) and 20 or 40)
		if trauma > 0 then tes3.modStatistic{reference = tr, name = L.Traum[math.random(5)], current = - trauma} end
	end
end

if a == mp and w and D.poison and DMG > 0 then
	if wt < 9 then D.poison = D.poison - math.max(100 - Agi/(P.agi12 and 2 or 4),50)	M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end end
	local chance = 50 + (Agi/2 + mp.luck.current/4)*(P.agi13 and 2 or 1) - Tagi/2 - t.luck.current/4 - math.max(t.resistPoison,0)/2 - arm/2
	if chance > math.random(100) then tes3.applyMagicSource{reference = e.reference, source = B.poi}		if cf.m5 then tes3.messageBox("Poisoned! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end
	elseif cf.m5 then tes3.messageBox("Poison failure! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end 
end

local KO = math.min(math.min(100*DMG/BaseHP,40) * (((a ~= mp or P.str4 and sw > 0.95) and 1.5 or 1) + (1 - fat + t.encumbrance.normalized) * ((t ~= mp or P.end22) and 0.5 or 1)
+ ((a ~= mp or P.blu9 and sw > 0.95 and dir == 2) and (wt == 3 or wt == 4) and 0.5 or 0)) - Tagi*((t ~= mp or P.agi26) and 0.5 or 0.25), DMG)

if KO > math.random(100) then G.KOGMST.value = 0 else G.KOGMST.value = 100		hs = hs + math.max(KO,0)
	if hs < math.random(100) and tad.animationAttackState ~= 1 then
		timer.delayOneFrame(function() if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0
		else timer.delayOneFrame(function() if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end end) end end)
	end
end

e.damage = DMG
if cf.m30 then tes3.messageBox([[%.1f = %.1f * (%d%% str + %d%% sk + %d%% at)
* %d%% stam * %d%% arm (%d * %d%% * %.2f)
* %d%% mult + %d%% perk + %d%% crit (%d%%)
Hs %d%%   KO %d%%   StamD %d%%
%.1f Shield (%.1f mag, %.1f mc)  %d traum]],
DMG, WD, Kstr, Kskill, Kbonus, Kstam*100, Karm*100, Arm, Armult*100, Norm, Mult + Kdash, Kperk, Kcrit, CritC, hs, KO, stam*100, Dred, KSM, smc, trauma) end


if a == mp then L.skw = math.max((tr.object.level * 4 + 20 - p.object.level/2) / (tr.object.level + 20) * DMG/30, 0)
	if P.axe9 and WT[wt].s == 6 and t.health.current - DMG < 0 then A[ar].axe = math.min(A[ar].axe + 5, 10) end
else
	if t == mp then
		if P.sec3 and (mp.health.current - DMG)/BaseHP < 0.2 and not tes3.isAffectedBy{reference = p, object = B.TS} then 
			--local min = 20 + mp:getSkillValue(18)/5		tes3.applyMagicSource{reference = p, name = "Survival_instinct", effects = {{id = 510, min = min, max = min + 10, duration = 3}}}
			B.TS.effects[1].id = 510  B.TS.effects[1].min = 20 + mp:getSkillValue(18)/5   B.TS.effects[1].max = B.TS.effects[1].min + 10   B.TS.effects[1].duration = 3
			tes3.applyMagicSource{reference = p, source = B.TS, createCopy = false}
		end
	end
	local Pois = L.CPOI[bid]		if Pois and DMG > 0 and Pois[2] > math.random(100) then tes3.applyMagicSource{reference = tr, source = B[Pois[1]]} end
end
elseif e.source == "shield" then	e.damage = 0	local el = e.activeMagicEffect.effectId		local El = L.ELSH[el]		local ts = tes3.getSimulationTimestamp()
	if El.ts ~= ts then		local ar = e.attackerReference	local tr = e.reference
		if ar.position:distance(tr.position) < ((ar ~= p or P.alt12) and 300 or 200) then
			local mag = math.random(0, Mag(el,ar) * ((ar ~= p or P.alt22) and 1 or 0.8))		local E = B.ElSh.effects[1]		E.id = El.id	E.min = mag		E.max = mag		E.duration = 1
			SNC[(tes3.applyMagicSource{reference = tr, source = B.ElSh}).serialNumber] = e.attacker		--tes3.messageBox("%s   mag = %s   ar = %s", el, mag, ar)
		end
	end		El.ts = ts
elseif e.source == "fall" and e.reference == p and D.KS then local KSM = Mag(508)		mp:exerciseSkill(20, e.damage/20)
	if KSM > 0 and mp.magicka.current > 4 then KSM = KSM * (1 + (P.una7 and D.AR.u * mp:getSkillValue(17)/10000 or 0))
		local Dred = math.min(mp.magicka.current/4, e.damage, KSM)	mc = Dred * (1 + D.AR.l*0.08 + D.AR.m*0.10 + D.AR.h*0.12) * (P.alt21 and 0.5 or 0.75)		e.damage = e.damage - Dred		Mod(mc)
		if cf.m then tes3.messageBox("Shield! %.1f damage  %.1f reduction  %.1f mag  Cost = %.1f", e.damage, Dred, KSM, mc) end
end end end		event.register("damage", DAMAGE)



local function DAMAGEHANDTOHAND(e) local a = e.attacker	local ar = e.attackerReference	local t = e.mobile	local tr = e.reference	local ad = a.actionData		local Mult = 100
local sw = ad.attackSwing	 local dir = ad.attackDirection		local s = a:getSkillValue(26)	local fistd = 0		local Agi = a.agility.current
local as = (a.isMovingForward and 1) or (a.isMovingLeft or a.isMovingRight and 2) or (a.isMovingBack and 3) or 0
local ts = (t.isMovingForward and 1) or (t.isMovingLeft or t.isMovingRight and 2) or (t.isMovingBack and 3) or 0

local Kstr = 100 + a.strength.current * ((a ~= mp or P.str1) and 0.5 or 0.4)
local Kskill = s * (((a ~= mp or P.hand1) and 0.2 or 0.1) + ((a ~= mp or P.str2) and 0.1 or 0.05))
local Kbonus = a.attackBonus/5 + (a == mp and 0 or ar.object.level)
local Kstam = math.min(math.lerp(((a ~= mp or P.end1) and 0.4 or 0.3) + ((a ~= mp or P.hand2) and 0.2 or 0), 1, a.fatigue.normalized*1.1), 1)

local CritC = Kbonus + Agi/((a ~= mp or P.agi1) and 10 or 20) + s/((a ~= mp or P.hand6) and 10 or 20) + ((a ~= mp or P.luc1) and a.luck.current/20 or 0) + (as == 1 and (a ~= mp or P.spd3) and 10 or 0)
+ (ts == 1 and ((t == mp and P.med10 and D.AR.m > 19 and 0 or 10) + ((t ~= mp or P.agi7) and 0 or 10)) or 0)
+ (a == mp and math.min(com, G.maxcomb) * (P.agi6 and 5 or 3) + (a.isJumping and P.acr4 and a:getSkillValue(20)/10 or 0) - 10 or 10)
- (t.endurance.current + t.agility.current)/((t ~= mp or P.end3) and 20 or 40) - ((t ~= mp or P.luc2) and t.luck.current/20 or 0) - t.armorRating/10 - t.sanctuary/10
+ math.max(1-t.fatigue.normalized,0)*((a ~= mp or P.agi11) and 20 or 10) - (t == mp and ts == 0 and P.hev11 and D.AR.h or 0)
local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + ((a ~= mp or P.agi8) and 10 or 0) + ((a ~= mp or P.hand5) and 20 or 0) end
Mult = Mult - math.min(((ts == 3 or (t == mp and P.hev10 and ts == 0 and D.AR.h > 19)) and math.min((t.agility.current + t.endurance.current)/((t ~= mp or P.end2) and 10 or 20)
+ ((t ~= mp or P.bloc2) and t.readiedShield and t:getSkillValue(0)/20 or 0), 30) or 0)
+ (not t.readiedShield and (not t.readiedWeapon and (t.actorType ~= 0 and (t ~= mp or P.hand20) and (t:getSkillValue(26)/10 + t.agility.current/20) or 0) or
((t ~= mp or P.hand9 and not W.DWM) and WT[t.readiedWeapon.object.type].h1 and (t:getSkillValue(26) + t.agility.current)/20 or 0)) or 0), 50)


if a == mp then
	if P.str15 then Mult = Mult + 20 * math.max(1 - mp.health.normalized, 0) end
	if (not R[tr] or not R[tr].cm) and math.abs(t:getViewToActor(mp)) > (P.snek8 and 135 or 150) then Mult = Mult + 100 + (P.snek3 and mp.isSneaking and 100 or 0) + (P.hand18 and 100 or 0)	mp:exerciseSkill(19, 1 + tr.object.level/5) end
	if (T.Dash.timeLeft or 0) > 2 then Mult = Mult + V.dd/(P.str9 and 50 or 100) end
	if ((P.con12 and t.object.type == 1) or (P.con13 and t.object.type == 2)) then Mult = Mult + mp:getSkillValue(13)/10 end
	if T.Comb.timeLeft then		local maxcom = (P[WT[-1].pc] and 4 or 3) + math.floor(s/50)
		if dir == last then com = math.max(com - 2, 0) elseif dir == pred and com > 2 then com = com - 1 elseif dir ~= pred then com = math.min(com + 1, maxcom) end
		M.CombK.text = ("%s/%s"):format(com, maxcom)		T.Comb:reset()	pred = last		last = dir
	else	last = dir	T.Comb = timer.start{duration = P.spd4 and 2 or 1.5, callback = function() com = 0	last = nil	pred = nil	M.CombK.text = "" end} end
elseif t == mp then Mult = Mult + (P.end12 and 0 or 50)
end



local SD = sw * ((a ~= mp or P.hand17) and 20 or 15)
local Koef = (Kstr + Kskill + Kbonus)/100 * Kstam * (Mult + Kcrit)/100
local FD = SD * Koef

if a ~= mp or P.hand19 then
	local gau = (a ~= mp or P.hand7) and tes3.getEquippedItem{actor = ar, objectType = tes3.objectType.armor, slot = dir == 3 and 6 or 7} or nil		gau = gau and gau.object.weight*(0.3 + s/500) or 0
	fistd = sw * (s/50 + gau) * Koef
end


local hs = (100 + Kcrit/2 + (s + a.strength.current + Agi)/((a ~= mp or P.str13) and 10 or 20) + (as == 1 and (a ~= mp or P.str3) and 20 or 0) + (a == mp and math.min(com, G.maxcomb) * (P.agi9 and 10 or 5) or 0)
+ (ts == 1 and (not (t == mp and P.med10 and D.AR.m > 19) and 30 or 0) or 0) - (t == mp and P.hev12 and D.AR.h or 0)
- (t.endurance.current + t.agility.current)/((t ~= mp or P.end5) and 5 or 10) - (ts == 0 and (t ~= mp or P.str5) and t.strength.current/10 or 0)) * FD*5/t.health.base

if hs < math.random(100) and t.actionData.animationAttackState ~= 1 then timer.delayOneFrame(function()
	if t.actionData.animationAttackState == 1 and not L.AG[t.actionData.currentAnimationGroup] then t.actionData.animationAttackState = 0
	else timer.delayOneFrame(function() if t.actionData.animationAttackState == 1 and not L.AG[t.actionData.currentAnimationGroup] then t.actionData.animationAttackState = 0 end end) end
end) end



if cf.m30 then tes3.messageBox([[Fist %.1f = %.1f * %d%% (%d%% str + %d%% sk + %d%% at)
* %d%% stam * (%d%% mult + %d%% crit (%d%%))   Hs = %d%%   Dmg = %d]],
FD, SD, Koef*100, Kstr, Kskill, Kbonus, Kstam*100, Mult, Kcrit, CritC, hs, fistd) end



if tr.data.KS then local KSM = Mag(508,tr)	if KSM > 0 then		if t.magicka.current > 5 then	KSM = KSM * (1 + (t == mp and P.una7 and D.AR.u * t:getSkillValue(17)/10000 or 0))
	local Dred = math.min(t.magicka.current/4, fistd, KSM)		local cmult = t == mp and (1 + D.AR.l*0.08 + D.AR.m*0.10 + D.AR.h*0.12) * (P.alt21 and 0.5 or 0.75) or 0.5		mc = 0
	if fistd > 0 then mc = Dred * cmult		fistd = fistd - Dred end
	local Stred = math.min(t.magicka.current - mc, FD, KSM)		if Stred > 0 then mc = mc + Stred/5 * cmult		FD = FD - Stred end		Mod(mc,t)
	if cf.m3 then tes3.messageBox("Shield! %d stam damage  (-%d   -%.1f dmg) %.1f mag  Cost = %.1f", FD, Stred, Dred, KSM, mc) end
end else tr.data.KS = nil end end

e.fatigueDamage = FD
if fistd > 0 then t:applyDamage{damage = fistd, applyArmor = true, resistAttribute = 12, playerAttack = a == mp} end

if a == mp then		L.skw = math.max((tr.object.level * 4 + 20 - p.object.level/2) / (tr.object.level + 20) * FD/50, 0)
	--if P.hand4 and sw < s/200 then ad.animationAttackState = 0 end
end
end		event.register("damageHandToHand", DAMAGEHANDTOHAND)


local function CALCBLOCKCHANCE(e)	local a, t = e.attackerMobile, e.targetMobile		local s = t:getSkillValue(0) 	local activ = t.actionData.animationAttackState == 2
local wt = a.readiedWeapon		wt = wt and (a == mp and W.wt or wt.object.type) or -1
local ang = t:getViewToActor(a)			local max = (ang >= 0 and (activ and 30 or 20) or (activ and -30 or -60)) * ((t ~= mp or P.bloc9) and 1.5 or 1)
local Kang = math.clamp((1 - ang/max)*((t ~= mp or P.bloc9) and 1.5 or 1), 0, 1)
local Kstam = math.min(math.lerp(((t ~= mp or P.bloc19) and 0.6 or 0.3), 1, t.fatigue.normalized), 1)
local Ktar = (t == mp and (activ and (P.bloc1 and 100 or 50) or 0) or 100) + (s/2 + t.agility.current/5 + t.luck.current/10) * ((t ~= mp or P.bloc20) and 1.25 or 1)
local Katak = (a:getSkillValue(WT[wt].s)/2 + a.agility.current/5 + a.luck.current/10) * (((a ~= mp or P.agi28) and 1.25 or 1) + (1 - a.actionData.attackSwing))
local bloc = Ktar * Kstam * Kang - Katak		local cost = 0
if bloc > math.random(100) then e.blockChance = 100
	local SH = t.readiedShield		cost = SH.object.weight * math.max(0.5 - s/((t ~= mp or P.bloc3) and 250 or 500), 0.1)		if cost > 0 then t.fatigue.current = math.max(t.fatigue.current - cost, 0) end
	if t == mp then L.UpdShield(SH)
		if T.CST.timeLeft then T.CST:reset() elseif P.bloc4 then T.CST = timer.start{type = timer.game, duration = (0.4 + (P.bloc8 and (t.agility.current + s)/1000 or 0))*G.sis, callback = function() end} end
	end
else e.blockChance = 0 end
if cf.m3 then tes3.messageBox("%s %d%% = %d tar * %d%% stam * %d%% ang (%d/%d) - %d atk  Stam cost +%d", e.blockChance == 100 and "BLOCK!" or "block", bloc, Ktar, Kstam*100, Kang*100, ang, max, Katak, cost) end
end		event.register("calcBlockChance", CALCBLOCKCHANCE)


-- бехевиор: -1 = стоит столбом и ничего не делает хотя и в бою. 5 = убегает и не видит игрока, 6 = убегает; 3 = атака; 2 - идл (но бывает и при атаке); 0 = хеллоу; 8 = бродит
local function COMBATSTARTED(e) local m = e.actor	local ref = m.reference	 	if e.target == mp and not R[ref] and m.combatSession then	local ob = m.object
R[ref] = {m = m, a = m.actionData, ob = ob, c = 0, at = (m.actorType == 1 or ob.biped) and 1 or (not ob.usesEquipment and 3), lim = math.max((P.per7 and 70 or 100) + ob.level*(P.ill19 and 5 or 10), 100),
rc = L.MAC[(m.actorType == 1 and m:getSkillValue(10) > 40) and 0 or ob.baseObject.id]}
timer.delayOneFrame(function() if R[ref] then R[ref].cm = true end end)
if cf.m4 then tes3.messageBox("%s joined the battle! Enemies = %s", ob.name, table.size(R)) end
if not T.CT.timeLeft then	T.CT = timer.start{duration = 1, iterations = -1, callback = function() local s, sa, w, beh, HD, status	--local tik5 = math.floor(T.CT.timing)%5 == 0
	if P.int4 then local ht = ad.hitTarget	if ht and not ht.isDead then M.Sbar.visible = true	M.Sbar.widget.normalized = ht.fatigue.normalized else M.Sbar.visible = false end end
	for r, t in pairs(R) do s = t.m.combatSession	sa = s and s.selectedAction		beh = t.a.aiBehaviorState	w = t.m.readiedWeapon	w = w and w.object		HD = nil
		if s then
			if sa == 7 then
				if t.m.health.normalized > 0.1 and t.m.flee < t.lim then
					if t.m.isPlayerDetected and tes3.testLineOfSight{reference1 = r, reference2 = p} then
						if not w or w.type < 9 then
							HD = math.abs(pp.z - r.position.z) > 128 * (w and w.reach or 0.7)
							if HD then
								if t.at == 1 then
									if t.c > cf.AIsec then status = "STONE!"
										if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(2,3)} end		--t.ob:reevaluateEquipment()
										mwscript.equip{reference = r, item = L.stone}	 r:updateEquipment()
										s.selectedAction = 2
										t.a.aiBehaviorState = 3
									else status = "NO STONE"	if not t.rc then t.c = t.c + 1 end
										s.selectedAction = t.at or 1
										t.a.aiBehaviorState = 3
									end
								else status = "NO RUN MONSTR"
									s.selectedAction = 5
									t.a.aiBehaviorState = 3
								end
							else status = "NO HD"
								s.selectedAction = t.at or 1
								t.a.aiBehaviorState = 3
							end
						else status = "RANGE"
							s.selectedAction = 2
							t.a.aiBehaviorState = 3
						end
						if t.rc then tes3.applyMagicSource{reference = r, source = B[table.choice(t.rc)]} end
					else status = "NO LINE"
						s.selectedAction = t.at or 1
						t.a.aiBehaviorState = 3
					end
				else status = "FLEE" end
			elseif beh == 6 or beh == 5 then
				if t.m.isPlayerDetected and tes3.testLineOfSight{reference1 = r, reference2 = p} then
					if not w or w.type < 9 then
					--	HD = math.abs(pp.z - r.position.z) > 128 * (w and w.reach or 0.7)
					--	if HD then
							if t.at == 1 then
								if t.c > cf.AIsec then status = "SEARCH - STONE!"	t.c = 0
									if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(1,2)} end
									mwscript.equip{reference = r, item = L.stone}	 r:updateEquipment()
									s.selectedAction = 2
									t.a.aiBehaviorState = 3
								else status = "SEARCH - NO STONE"	if not t.rc then t.c = t.c + 1 end
									--s.selectedAction = t.at or 1
									--t.a.aiBehaviorState = 3
								end
							else status = "SEARCH - MONSTR"
								--s.selectedAction = 5
								--t.a.aiBehaviorState = 3
							end
					--	else status = "SEARCH - NO HD"
					--		s.selectedAction = t.at or 1
					--		t.a.aiBehaviorState = 3
					--	end
					else status = "SEARCH - RANGE"
						--s.selectedAction = 2
						--t.a.aiBehaviorState = 3
					end
					if t.rc then tes3.applyMagicSource{reference = r, source = B[table.choice(t.rc)]} end
				else status = "SEARCH - NO LINE" end
			elseif beh == -1 then	status = "EXTRA COMBAT!"	t.m:startCombat(mp)		t.a.aiBehaviorState = 3
			else status = ""	if t.c > 0 and (not w or w.type < 9) then t.c = 0 end		--if not w or w.type < 9 then t.c = t.c > cf.AIsec and cf.AIsec or 0 end
			end
		else	-- если не в бою, то нельзя применять applyMagicSource с шаром даже если стартовать бой
			if t.m.fight > 30 then
				if t.m.isPlayerDetected and tes3.testLineOfSight{reference1 = r, reference2 = p} then
					if not w or w.type < 9 then
						HD = math.abs(pp.z - r.position.z) > 128 * (w and w.reach or 0.7)
						if HD then
							if t.at == 1 then status = "NO COMB - EXTRA STONE!"
								if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(1,2)} end
								mwscript.equip{reference = r, item = L.stone}	 r:updateEquipment()
								t.m:startCombat(mp)		t.a.aiBehaviorState = 3
							else status = "NO COMB - MONSTR"
								--t.a.aiBehaviorState = 3
							end
						else status = "NO COMB - NO HD"
							t.m:startCombat(mp)		t.a.aiBehaviorState = 3
						end
					else status = "NO COMB - RANGE"
						t.m:startCombat(mp)		t.a.aiBehaviorState = 3
					end
				else status = "NO COMB - NO LINE"
					t.m:startCombat(mp)		t.a.aiBehaviorState = 3
				end
			else status = "NO COMB - CALM!"	R[r] = nil end
		end
		if cf.m4 then tes3.messageBox("%s %s(%s) fl %d/%d  fg %d   Beh = %s/%s  SA = %s/%s  %s", r, status, t.c > 0 and t.c or "", t.m.flee, t.lim, t.m.fight, beh,
		t.a.aiBehaviorState, sa, s and s.selectedAction, t.m.isPlayerDetected and "" or "No detect") end
	end
	if table.size(R) == 0 then T.CT:cancel()
	M.Sbar.visible = false	if cf.m4 then tes3.messageBox("The battle is over!") end end
	--if rrr then rrr:disable()	rrr.modified = false end	rrr = tes3.createReference{object = "4nm_light", scale = 3, position = e.actor.actionData.walkDestination, cell = p.cell}
end} end
end end		event.register("combatStarted", COMBATSTARTED)

--[[	local function determineAction(e)	local s = e.session		local m = s.mobile		if R[m.reference] then
tes3.messageBox("DE  %s  SA = %s  Prior = %s", m.reference, s.selectedAction, s.selectionPriority)
end end		--event.register("determineAction", determineAction)
--]]
-- не решил = 0, Атака (1 мили, 2 рейндж, 3 кричер без оружия или рукопашка), AlchemyOrSummon = 6, бегство = 7, Спелл (касание 4, цель 5, на себя 8), UseEnchantedItem = 10		s:changeEquipment()
local function onDeterminedAction(e) local s = e.session	local m = s.mobile 	local t = R[m.reference]	if t then
--tes3.messageBox("DED  %s  SA = %s  Beh = %s  fl = %d  fg = %d  Prior = %s  W = %d %s  S = %d %s  %s", m.object.name, s.selectedAction,  m.actionData.aiBehaviorState, m.flee, m.fight, s.selectionPriority,
--m.readiedWeapon and m.readiedWeapon.object.type or -1, s.selectedWeapon and s.selectedWeapon.object.name, m.readiedShield and 1 or 0, s.selectedShield and "+S" or "", s.selectedSpell and s.selectedSpell.name)
if s.selectedAction == 7 then
	if m.health.normalized > 0.1 and m.flee < t.lim then s.selectedAction = t.at or 1		t.a.aiBehaviorState = 3
		if cf.m4 then tes3.messageBox("UPD NO FLEE!  %s", t.ob.name) end		-- дальнобойные враги (sa == 2 or sa == 5) вообще не убегают даже если фли выше 100
	end
end end	end		event.register("determinedAction", onDeterminedAction)

local function combatStop(e) local m = e.actor	local r = m.reference	if R[r] then local t = R[r]		local status, RetF		local beh = t.a.aiBehaviorState 	--событие не триггерится от контроля и успокоения
if m.fight > 30 then
	if t.at == 1 then
		if math.abs(pp.z - r.position.z) > 128 * (t.m.readiedWeapon and t.m.readiedWeapon.object.reach or 0.7) then		
			if not m.readiedWeapon or m.readiedWeapon.object.type < 9 then
			--	if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(1,2)} end
			--	mwscript.equip{reference = r, item = L.stone} r:updateEquipment()
				status = "NO LEAVE + STONE"
			else status = "NO LEAVE + RANGE" end
		--	t.a.aiBehaviorState = 3
			--RetF = true
		else status = "LEAVE NPC" end
	else status = "LEAVE MONSTR" end
else status = "CALM"	R[r] = nil end

if cf.m4 then tes3.messageBox("STOP - %s  %s  fg = %s   Beh = %s/%s  SA = %s  Tar = %s", status, r, m.fight, beh, t and t.a.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, t and t.a.target and t.a.target.object.name) end
if RetF then return false end
end end		--event.register("combatStop", combatStop)

--[[ local function onCombatStopped(e) local m = e.actor		if R[m.reference] then	-- Триггерится при кальме, но не при контроле
	if cf.m4 then tes3.messageBox("%s leave combat  fg = %s   Beh = %s  SA = %s  Enemies = %s", m.object.name, m.fight, m.actionData.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, table.size(R)) end
end end		--event.register("combatStopped", onCombatStopped)
--]]

local function DETECTSNEAK(e) if e.target == mp then	local m = e.detector	local r = m.reference
--[[	local VMult = Viev < 90 and tes3.findGMST("fSneakViewMult").value or tes3.findGMST("fSneakNoViewMult").value
	local DMult = tes3.findGMST("fSneakDistanceBase").value + r.position:distance(pp) * tes3.findGMST("fSneakDistanceMultiplier").value
	local PKoef = (mp.isSneaking and mp.sneak.current * tes3.findGMST("fSneakSkillMult").value + mp.agility.current/5 + mp.luck.current/10 + mp:getBootsWeight() * tes3.findGMST("fSneakBootMult").value or 0)
	* mp:getFatigueTerm() * DMult + mp.chameleon + (mp.invisibility > 0 and 100 or 0)
	local DKoef = (m.sneak.current + m.agility.current/5 + m.luck.current/10 - m.blind) * VMult * m:getFatigueTerm()
	local chance = PKoef - DKoef		local detected = math.random(100) >= chance		e.isDetected = detected		--m.isPlayerDetected = detected		m.isPlayerHidden = not detected
--]]
local com = R[r] and R[r].cm	local snek = mp.isSneaking or (P.snek12 and mp.movementFlags == 0)
local KP = com and 0 or ((mp:getSkillValue(19) + mp.agility.current/2)*(P.snek1 and 1 or 0.5) + (P.luc10 and mp.luck.current/4 or 0) + (P.sec5 and mp:getSkillValue(18)/4 or 0)) * (snek and 0.5 or (P.snek10 and 0.2 or 0)) * math.min(mp.fatigue.normalized,1)
local KD = com and 0 or (m:getSkillValue(18) + m.agility.current/4 + m.luck.current/4)
local Koef = com and 1 or math.max((100 + KD - KP)/100, 0.5)
local DistKF = math.max(1.5 - r.position:distance(pp)/(P.snek5 and 2000 or 3000), 0.5)
local VPow = com and 200 or math.max(200 - math.abs(m:getViewToActor(mp)) * (P.snek6 and 1.2 or 1), 0)
local Vis = math.max(VPow * Koef * DistKF - (mp.invisibility > 0 and (P.snek11 and 200 or 150) - m:getSkillValue(14)/2 or 0) - mp.chameleon - m.blind, 0)
local Aud = math.max((5 + mp.encumbrance.current/5 + mp:getBootsWeight()) * ((snek and 0 or 2) + (P.snek4 and 1 or 2)) * Koef * DistKF - (P.ill21 and mp.chameleon/2 or 0) - m.sound, 0)
local chance = Vis + Aud		local detected = chance > math.random(100)		e.isDetected = detected		m.isPlayerDetected = detected		m.isPlayerHidden = not detected
if cf.m11 then tes3.messageBox("Det %s %d%%  Vis = %d%% (%d)  Aud = %d%%  DistKF = %.2f  Koef = %.2f (%d - %d)  %s", detected, chance, Vis, VPow, Aud, DistKF, Koef, KD, KP, r) end
end	end		if cf.stels then event.register("detectSneak", DETECTSNEAK) end

local function ACTIVATE(e) if e.activator == p then		local t = e.target
if t.object.objectType == tes3.objectType.npc and t.mobile.fatigue.current < 0 then		--ref.object:hasItemEquipped(item[, itemData])
	if cf.maniac and mp.agility.current*(P.agi18 and 1 or 0.5) > 50 + 50*t.mobile.health.normalized + t.mobile.fatigue.current then
		for _, s in pairs(t.object.equipment) do t.mobile:unequip{item = s.object} end	if cf.m then tes3.messageBox("Playful hands!") end
		timer.delayOneFrame(function() t.object:reevaluateEquipment() end)
	else if t.mobile.readiedWeapon then t.mobile:unequip{item = t.mobile.readiedWeapon.object} end		if t.mobile.readiedAmmo then t.mobile:unequip{item = t.mobile.readiedAmmo.object} end end
elseif t.object.objectType == tes3.objectType.apparatus and ic:isKeyDown(cf.ekey.keyCode) then	local app = {}
	for r in p.cell:iterateReferences(tes3.objectType.apparatus) do
		if (not app[r.object.type] or app[r.object.type].quality < r.object.quality) and tes3.hasOwnershipAccess{target = r} and pp:distance(r.position) < 800 then app[r.object.type] = r.object end
	end
	for i, ob in pairs(app) do tes3.addItem{reference = p, item = ob, playSound = false} end
	timer.delayOneFrame(function() local appar = app[0] or app[1] or app[2] or app[3]	if appar then
		mp:equip{item = appar}	timer.delayOneFrame(function() for i, ob in pairs(app) do tes3.removeItem{reference = p, item = ob, playSound = false} end end)
	end end)
	return false
end		-- if e.activator == p and wc.inputController:isKeyDown(cf.telkey.keyCode) and e.target ~= W.TETR then TELnew(e.target)	return false end
end end		event.register("activate", ACTIVATE)


local function EQUIP(e) if e.reference == p and e.item.weight > 0 then local o = e.item
if (o.objectType == tes3.objectType.alchemy or o.objectType == tes3.objectType.ingredient) then
	if o.objectType == tes3.objectType.alchemy and M.drop.visible then local Btab = L.BotMod[o.mesh:lower()]	if Btab then	local ispoison = true
		if cf.smartpoi then ispoison = nil		for i, ef in ipairs(o.effects) do if ef.object and ef.object.isHarmful then ispoison = true break end end end
		if ispoison then
			if ic:isKeyDown(cf.ekey.keyCode) then -- кидание бутылок
				if not G.pbotswap then G.pbotswap = true	local bot = L.pbottle
					if mp.readiedWeapon and mp.readiedWeapon.object == bot then mp:unequip{item = bot} end
					timer.delayOneFrame(function() G.pbotswap = nil
						local numdel = tes3.getItemCount{reference = p, item = bot}		if numdel > 0 then
							tes3.removeItem{reference = p, item = bot, count = numdel}		tes3.addItem{reference = p, item = D.poisonbid, count = numdel}		D.poisonbid = nil
							if cf.m5 then tes3.messageBox("%d %s", numdel, cf.en and "bottles unequipped" or "старых бутылок снято") end
						end
						local num = tes3.getItemCount{reference = p, item = o}	if num > 0 then		local enc = tes3.getObject("4nm_e_poisonbottle")	local E = enc.effects	local pow = P.alc7 and 3 or 4
							for i, ef in ipairs(o.effects) do E[i].id = ef.id		E[i].radius = 5		E[i].min = L.nomag[ef.id] and ef.min or ef.min/pow		E[i].max = L.nomag[ef.id] and ef.max or ef.max/pow
							E[i].duration = L.nomag[ef.id] and ef.duration/pow or ef.duration	E[i].rangeType = 1		E[i].attribute = ef.attribute		E[i].skill = ef.skill end
							bot.mesh = Btab[1]	bot.icon = Btab[2]	bot.weight = o.weight	D.poisonbid = o.id		enc.modified = true		bot.modified = true		
							tes3.removeItem{reference = p, item = o, count = num}		tes3.addItem{reference = p, item = bot, count = num}		mp:equip{item = bot}
							if cf.m5 then tes3.messageBox("%d %s", num, cf.en and "bootles are ready!" or "бутылок готово к броску!") end
						end
					end)
					return false
				else tes3.messageBox("Not so fast!") return false end
			else -- отравление оружия
				timer.delayOneFrame(function() if tes3.getItemCount{reference = p, item = o} > 0 then	local pow = P.alc5 and 5 or 6
					for i, ef in ipairs(o.effects) do
						B.poi.effects[i].id = ef.id	B.poi.effects[i].min = L.nomag[ef.id] and ef.min or ef.min/pow		B.poi.effects[i].max = L.nomag[ef.id] and ef.max or ef.max/pow
						B.poi.effects[i].duration = L.nomag[ef.id] and ef.duration/pow or ef.duration		B.poi.effects[i].attribute = ef.attribute		B.poi.effects[i].skill = ef.skill
					end
					D.poison = 100 + (mp.alchemy.current + mp.agility.current) * (P.alc6 and 1 or 0.5)		M.WPB.widget.current = D.poison		M.WPB.visible = true
					tes3.removeItem{reference = p, item = o}
					if cf.m5 then tes3.messageBox("%s %d", cf.en and "Poison is ready! Charges =" or "Яд готов! объем =", D.poison) end
				end end)
				return false
			end
		end
	end end

	if D.potmcd then
		if cf.m5 then if cf.en then tes3.messageBox("Not so fast! I need at least %d seconds to swallow what is already in my mouth!", D.potmcd)
		else tes3.messageBox("Не так быстро! Мне надо еще хотя бы %d секунды чтобы проглотить то что уже у меня во рту!", D.potmcd) end end		return false
	elseif D.potcd and D.potcd > G.potlim then
		if cf.m5 then if cf.en then tes3.messageBox("Belly already bursting! I can't take o anymore... I have to wait at least %d seconds before I can swallow something else", D.potcd - G.potlim)
		else tes3.messageBox("Пузо уже по швам трещит! Больше не могу... Надо подождать хотя бы %d секунд прежде, чем я смогу заглотить что-то еще", D.potcd - G.potlim) end end	return false
	end
	D.potmcd = math.max((P.spd5 and 8 or 10) - mp.speed.current/20, 2)		D.potcd = (D.potcd or 0) + math.max(40 - (P.alc9 and mp.alchemy.current/10 or 0), 30)
	if not T.POT.timeLeft then T.POT = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
		if D.potmcd and D.potmcd > D.potcd - G.potlim then M.PCD.max = 5	M.PCD.current = D.potmcd else M.PCD.max = 30	M.PCD.current = D.potcd - G.potlim	if M.PCD.current <= 0 then M.PIC.visible = false end end
		if D.potcd <= 0 then D.potcd = nil	T.POT:cancel() end
	end} end
	M.PCD.max = 5	M.PCD.current = 5	M.PIC.visible = true	if cf.m5 then tes3.messageBox("%s %d / %d", cf.en and "Om-nom-nom! Belly filled at" or "Ням-ням! Пузо заполнилось на", D.potcd, G.potlim) end
elseif o.objectType == tes3.objectType.repairItem and not mp.inCombat then		local anvil
	if P.arm7 then for r in p.cell:iterateReferences(tes3.objectType.static) do if L.Anvil[r.object.id] and pp:distance(r.position) < 1000 then anvil = true	break end end end
	tes3.findGMST("fRepairAmountMult").value = (P.arm1 and 1 or 0.5) + (anvil and 1 or 0)		local Qal = math.min(o.quality,2)	local Skill = math.min(mp:getSkillValue(1) + mp.agility.base/5 + mp.luck.base/10, 100)
	if not G.ImpTab then local ob, ida, Kmax, KF		G.ImpTab = {}	G.ImpD = {}
		for _, s in pairs(cf.upgm and p.object.equipment or inv) do ob = s.object
			if ((ob.objectType == tes3.objectType.armor and P.arm5) or (ob.objectType == tes3.objectType.weapon and ob.type < 11 and P.arm4)) and ob.weight > 0 then
				Kmax = math.min(Qal/10, Skill*(P[ob.objectType == tes3.objectType.weapon and "arm8" or "arm9"] and 0.0015 or 0.001) + (P.luc9 and 0.05 or 0))
				KF = math.min((Skill * Qal - math.min(ob.value,10000)^0.5 * (P.arm12 and 1 or 2) + (ob.enchantment and (P.arm10 and 0 or -50) or (P.arm11 and 50 or 0)))/100, 1)
				if KF > 0 then
					if not cf.upgm then for i = 1, s.count do ida = s.variables and s.variables[i] or tes3.addItemData{to = p, item = ob, updateGUI = false}	ida.tempData.upg = true		G.ImpD[ida] = ob end end
					G.ImpTab[ob] = ob.maxCondition		ob.maxCondition = math.round(ob.maxCondition * (1 + KF * Kmax))
				end
			end
		end
		timer.delayOneFrame(function() for iob, max in pairs(G.ImpTab) do iob.maxCondition = max end	G.ImpTab = nil
			if not cf.upgm then for ida, iob in pairs(G.ImpD) do ida.tempData.upg = nil		tes3.removeItemData{from = p, item = iob, itemData = ida, force = false, updateGUI = false} end
			tes3.updateInventoryGUI{reference = p} end	G.ImpD = nil
		end)
	end
elseif e.item.objectType == tes3.objectType.weapon and ic:isKeyDown(cf.gripkey.keyCode) and not W.AltWCD then
	if L.AltW[o.type] then	local New	local ida = e.itemData	local wg = o.weight
		if o.id:sub(1,2) == "4_" and tes3.getObject(o.id:sub(3)) then New = tes3.getObject(o.id:sub(3)) else	local K = o.isOneHanded and 1.25 or 0.8
			New = tes3.createObject{objectType = tes3.objectType.weapon, id = "4_" .. o.id, type = L.AltW[o.type]}
			New.name = o.name	New.mesh = o.mesh	New.icon = o.icon	New.enchantment = o.enchantment		New.weight = wg		New.value = o.value		New.maxCondition = o.maxCondition
			New.flags = o.flags		New.ignoresNormalWeaponResistance = o.ignoresNormalWeaponResistance		New.isSilver = o.isSilver		New.reach = o.reach		New.enchantCapacity = o.enchantCapacity
			New.speed = math.round((o.isOneHanded and math.clamp(wg > 10 and 2.5 - wg*3/(wg+20) or 2.5 - wg/10, 0.3, 2) or math.max(wg > 15 and 2 - wg*3/(wg+30) or 2.5 - wg/10, 0.3))*20)/20
			New.chopMin = o.chopMin*K	New.chopMax = o.chopMax*K	New.slashMin = o.slashMin*K		New.slashMax = o.slashMax*K		New.thrustMin = o.thrustMin*K		New.thrustMax = o.thrustMax*K
		end
		tes3.addItem{reference = tes3.player, item = New}		--itemData = ida
		if ida then local DAT = tes3.addItemData{to = p, item = New}	DAT.condition = ida.condition		if ida.charge then DAT.charge = ida.charge end end
		W.AltWCD = true		mp:equip{item = New}		timer.delayOneFrame(function() tes3.removeItem{reference = p, item = o, playSound = false}	W.AltWCD = nil end, timer.real)			return false
	end
end
end end		event.register("equip", EQUIP)


-- Во время события equipped mp.readiedWeapon == нил! Надо ждать фрейм
local function EQUIPPED(e) if e.reference == p then	local o = e.item
if o.objectType == tes3.objectType.weapon then local od = e.itemData	timer.delayOneFrame(function() L.GetWstat() end, timer.real)
	if WT[o.type].dw then		if not ((o == W.WL and od == W.DL) or (o == W.WR and od == W.DR)) then	L.DWMOD(false)		L.DWNEW(o, od, ic:isKeyDown(cf.ekey.keyCode)) end
	else L.DWMOD(false)
		if o.type == 9 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 12 then
			for _, s in pairs(inv) do if s.object.type == 12 then mwscript.equip{reference = p, item = s.object} if cf.m8 then tes3.messageBox("arrows equipped") end break end end
		elseif o.type == 10 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 13 then
			for _, s in pairs(inv) do if s.object.type == 13 then mwscript.equip{reference = p, item = s.object} if cf.m8 then tes3.messageBox("bolts equipped") end break end end
		end
	end
	if cf.autoshield and not W.DWM and WT[o.type].h1 and not mp.readiedShield then
		for _, s in pairs(inv) do if s.object.objectType == tes3.objectType.armor and s.object.slot == 8 then mwscript.equip{reference = p, item = s.object} break end end
	end
elseif o.objectType == tes3.objectType.armor then L.GetArmT()		if o.slot == 8 then L.DWMOD(false) end
elseif L.DWOBT[o.objectType] then L.DWMOD(false) end
end end		event.register("equipped", EQUIPPED)


local function UNEQUIPPED(e) if e.reference == p then local it = e.item
if it.objectType == tes3.objectType.weapon then		if D.lw then local w = tes3.getObject(D.lw.id)	w.reach = D.lw.r	D.lw = nil end		L.GetWstat()
	if it == W.ob then W.ob = nil		W.f = nil	W.BAR.visible = false end
	if it == L.pbottle and not G.pbotswap then timer.delayOneFrame(function() local num = mwscript.getItemCount{reference = p, item = it} if num > 0 then
		tes3.removeItem{reference = p, item = it, count = num}		tes3.addItem{reference = p, item = D.poisonbid, count = num}	D.poisonbid = nil
		if cf.m5 then tes3.messageBox("%d bottles unequipped", num) end
	end end) end
else	if it.objectType == tes3.objectType.armor then L.GetArmT() end		if it.enchantment and it.enchantment.castType == 3 then ConstEnLim() end
end end end		event.register("unequipped", UNEQUIPPED)


local function WEAPONREADIED(e) if e.reference == p then	G.HandReach.value = (P.hand11 or e.weaponStack) and 0.7 or 0.5
	if W.DWM then if e.weaponStack then L.Cul(true) else L.DWMOD(false) end end
end end		event.register("weaponReadied", WEAPONREADIED)

local function WEAPONUNREADIED(e) if e.reference == p then	if W.DWM then L.Cul(false) end
	G.HandReach.value = 0.7
end end		event.register("weaponUnreadied", WEAPONUNREADIED)


local function ITEMDROPPED(e) local r = e.reference
	if BAM[r.object.id] then r:delete()		if cf.m then tes3.messageBox("Ammo unbound") end
	elseif r.object == L.pbottle then local num = r.stackSize	tes3.addItem{reference = p, item = D.poisonbid, count = num}
		r:delete()	if cf.m5 then tes3.messageBox("%d %s", num, cf.en and "old bottles unequipped" or "старых бутылок снято") end
	elseif ic:isKeyDown(cf.telkey.keyCode) then TELnew(r) end	-- ic:isKeyDown(cf.telkey.keyCode)
end		event.register("itemDropped", ITEMDROPPED)

local function FILTERINVENTORY(e) if L.BlackItem[e.item.id] and M.Stat and M.Stat.visible == false then e.filter = false end end		event.register("filterInventory", FILTERINVENTORY, {priority = -1000})
--local function filterContentsMenu(e) e.filter = true end		event.register("filterContentsMenu", filterContentsMenu, {priority = -1000})


L.MEDUR = {[2] = 10, [9] = 5, [11] = 10, [40] = 10, [58] = 10, [64] = 10, [65] = 10, [66] = 10, [501] = 10, [502] = 10, [503] = 10, [509] = 10,
[17] = 10, [18] = 10, [19] = 10, [20] = 10, [21] = 10, [28] = 10, [29] = 10, [30] = 10, [31] = 10, [32] = 10, [33] = 10, [34] = 10, [35] = 10, [36] = 10,
[49] = 10, [50] = 10, [51] = 10, [52] = 10, [53] = 10, [54] = 10, [55] = 10, [56] = 10, [101] = 10, [118] = 10, [119] = 10, [44] = 10,
[79] = 10, [80] = 10, [81] = 10, [82] = 10, [83] = 10, [84] = 10, [117] = 10, [42] = 10, [85] = 10, [89] = 10,
[90] = 10, [91] = 10, [92] = 10, [93] = 10, [94] = 10, [95] = 10, [96] = 10, [97] = 10, [98] = 10, [99] = 10, [67] = 5, [68] = 5,
[102] = 10, [103] = 10, [104] = 10, [105] = 10, [106] = 10, [107] = 10, [108] = 10, [109] = 10, [110] = 10, [111] = 10, [112] = 10, [113] = 10, [114] = 10, [115] = 10, [116] = 10,
[134] = 10, [137] = 10, [138] = 10, [139] = 10, [140] = 10, [141] = 10, [142] = 10}
local function MENUSETVALUES(e) local MSVD = e.element:findChild(-789) if MSVD then	e.element:findChild(-783):registerBefore("mouseClick", function()
	local min = (L.MEDUR[e.element:getPropertyObject("MenuSetValues_Effect").id] or 0) * (P.int10 and 1 or 2)
	if MSVD.widget.current < min then tes3.messageBox("Minimum duration = %s", min) return false end
end) end end		if cf.durlim then event.register("uiActivated", MENUSETVALUES, {filter = "MenuSetValues"}) end

local function SPELLCREATED(e) local s = e.spell	local del, rt
for i, ef in ipairs(s.effects) do if ef.id ~= -1 and ef.rangeType ~= 1 then if rt then if ef.rangeType ~= rt then del = true	break end else rt = ef.rangeType end end end
if del then	timer.delayOneFrame(function() mwscript.removeSpell{reference = p, spell = s}	timer.delayOneFrame(function() tes3.deleteObject(s) 	tes3.messageBox("Anti-exploit! Spell deleted!") end) end) end
end		if cf.aspell then event.register("spellCreated", SPELLCREATED, {filter = "service"}) end

local function ENEVENT(e) if e.property == tes3.uiProperty.mouseClick then	--tes3.messageBox("Эвент id = %s   top = %s", e.block.id, tes3ui.getMenuOnTop().id)
	if e.block.id == -267 or e.block.id == -268 then	if tes3ui.getMenuOnTop().id ~= -264 then event.unregister("uiEvent", ENEVENT) end
	else	local MENCH = tes3ui.findMenu(-264)
		if MENCH then tes3.findGMST("fEnchantmentConstantDurationMult").value = math.max((P.enc13 and 40000 or 50000)/math.max(MENCH:findChild(-296).text,200),100) end
	end
end end

local function MENUENCHANTMENT(e) event.register("uiEvent", ENEVENT) local El = e.element
if cf.spmak then
	El.minWidth = 1200	El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
	El:findChild("MenuEnchantment_magicEffectsContainer").width = 32*(vol+1)
	EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
	for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
	s:createImage{path = "icons\\" .. s:getPropertyObject("MenuEnchantment_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end
if not tes3ui.getServiceActor() then
	local SK = {[10] = mp.destruction.base, [11] = mp.alteration.base, [12] = mp.illusion.base, [13] = mp.conjuration.base, [14] = mp.mysticism.base, [15] = mp.restoration.base}
	for i, s in ipairs(El:findChild("PartScrollPane_pane").children) do if SK[s:getPropertyObject("MenuEnchantment_Effect").skill] < 50 then s.visible = false end end
end
end		event.register("uiActivated", MENUENCHANTMENT, {filter = "MenuEnchantment"})

local function MENUSPELLMAKING(e)	local El = e.element
if cf.spmak then El.minWidth = 1200		El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
	El:findChild("MenuSpellmaking_EffectsLayout").width = 32*(vol+1)
	EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
	for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
	s:createImage{path = "icons\\" .. s:getPropertyObject("MenuSpellmaking_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end
if not tes3ui.getServiceActor() then
	El:findChild("MenuSpellmaking_Buybutton"):registerBefore("mouseClick", function() local cost = El:findChild("MenuSpellmaking_SpellPointCost").text		if mp.magicka.current < cost*5 then
		tes3.messageBox("%s %d", cf.en and "You don't have enough mana to create this spell. Need: " or "У вас не хватает маны на создание этого заклинания. Нужно: ", cost*5)		return false
	else Mod(cost*5) end end)
	local SK = {[10] = mp.destruction.base, [11] = mp.alteration.base, [12] = mp.illusion.base, [13] = mp.conjuration.base, [14] = mp.mysticism.base, [15] = mp.restoration.base}
	for i, s in ipairs(El:findChild("PartScrollPane_pane").children) do if SK[s:getPropertyObject("MenuSpellmaking_Effect").skill] < 80 then s.visible = false end end
end
end		event.register("uiActivated", MENUSPELLMAKING, {filter = "MenuSpellmaking"})

L.ALF={[1]={75,76,77,74,79,80,81,82,117,72,73,69,70,90,91,92,93,97,99,94}, [2]={10,8,4,5,6,1,2,0,41,43,39,57,67,68,59,64,65,66}, [3]={27,23,24,25,22,18,19,20,17,35,28,29,30,31,7,45,47}, [4]={}}	L.ALFEF = {[17]=0, [22]=0, [74]=0, [79]=0, [85]=0}
L.ALE = {[75]={5,20}, [76]={5,30}, [77]={10,60}, [74]={5,10}, [79]={20,60}, [83]={20,60}, [80]={20,60}, [81]={100,60}, [82]={100,120}, [84]={10,60}, [117]={30,60}, [42]={30,60}, [72]={1,1}, [73]={1,1}, [69]={1,1}, [70]={1,1},
[90]={30,60}, [91]={30,60}, [92]={30,60}, [93]={30,60}, [97]={30,60}, [99]={30,60}, [98]={20,60}, [94]={50,120}, [95]={50,120}, [96]={30,60},
[10]={10,30}, [8]={100,120}, [3]={30,60}, [4]={10,30}, [5]={10,30}, [6]={10,30}, [1]={30,60}, [2]={1,30}, [0]={1,60}, [9]={20,30}, [11]={20,60},
[41]={30,120}, [43]={30,120}, [39]={1,30}, [40]={30,60}, [57]={100,1}, [67]={10,60}, [68]={10,60}, [59]={30,60}, [64]={200,120}, [65]={200,120}, [66]={200,120},
[27]={5,20}, [23]={5,20}, [14]={5,20}, [15]={5,20}, [16]={5,20}, [24]={10,30}, [25]={10,30}, [22]={3,15}, [18]={50,60}, [19]={100,60}, [20]={100,60}, [17]={30,60}, [21]={30,60},
[28]={30,60}, [29]={30,60}, [30]={30,60}, [31]={30,60}, [34]={30,60}, [35]={30,60}, [36]={30,60}, [32]={50,120}, [33]={50,120}, [7]={100,60}, [45]={1,5}, [46]={1,10}, [47]={50,60}, [48]={50,60}}

local function MENUALCHEMY(e)	M.Alc = e.element
	local RFI = M.Alc:findChild("PartNonDragMenu_main").children[1]:createImage{path = "icons\\potions_blocked.tga"}
	RFI:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Reset alchemy filter"} end)
	RFI:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3.messageBox("Alchemy filter reset") end)
	M.AlcCH = M.Alc:createLabel{text = ("Chance %s%%"):format(cf.alc and "?" or math.floor(mp.alchemy.current + mp.intelligence.current/10 + mp.luck.current/10))}
	M.AlcCH.absolutePosAlignY = -0.1	M.AlcCH.positionY = -247 		M.Alc:updateLayout()
	if cf.alc and not P.alc21 then M.Alc:findChild(-25):registerBefore("mouseClick", function() tes3.messageBox("%s", cf.en and "You are not yet skilled enough to brew 4-ingredient potions" or
	"Вы еще недостаточно искусны чтобы варить зелья из 4 ингредиентов")		return false end) end
end		event.register("uiActivated", MENUALCHEMY, {filter = "MenuAlchemy"})

local function POTIONBREWSKILLCHECK(e)	local Al, Int, Luc, Agi, Mort, Cal, Ret, Alem = mp.alchemy.base, mp.intelligence.base, mp.luck.base, mp.agility.base, math.min(e.mortar.quality,2),
	e.calcinator, e.retort, e.alembic			Cal, Ret, Alem = (Cal and math.min(Cal.quality or 0,2) or 0), (Ret and math.min(Ret.quality or 0,2) or 0), (Alem and math.min(Alem.quality or 0,2) or 0)
	local pow0 = Al/2 + Int/10 + Mort*20 + (P.luc12 and Luc/10 or 0)		local pow = math.min(pow0,100)
	local Chance = Al*(P.alc13 and 1 or 0.5) + Mort*20 + Int/5 + Agi/5 + Luc*(P.luc12 and 0.3 or 0.1) + math.max(pow0-100,0) - (Ret + Cal + Alem) * (P.alc17 and 10 or 20)
	local Mag = (P.alc3 and 60 or 40) + Ret * (P.alc14 and 10 or 5) + Cal * (P.alc16 and 10 or 5)
	local Dur = (P.alc4 and 60 or 40) + Alem * (P.alc15 and 10 or 5) + Cal * (P.alc16 and 10 or 5)
	if math.random(100) <= Chance then e.potionStrength = pow	e.success = true
	elseif P.alc18 and Chance > 20 then pow = pow * math.random(1,Chance)/100	e.potionStrength = pow		e.success = true	else e.potionStrength = -1	e.success = false end
	G.PotM = Mag * pow/10000	G.PotD = Dur * pow/10000
	M.AlcCH.text = ("Chance %d%%  Power %d%%/%d%%/%d%%"):format(Chance, pow, Mag, Dur)		--M.Alc:updateLayout()
end		if cf.alc then event.register("potionBrewSkillCheck", POTIONBREWSKILLCHECK) end

local function POTIONBREWED(e)	local ob = e.object		local Alem = e.alembic		Alem = Alem and math.min(Alem.quality or 0,2)*(P.alc19 and 1 or 0.5) or 0
--local q = L.BotIc[ob.icon]	if q then ob.mesh = ("m\\misc_potion_%s_01.nif"):format(q) end	--ob.icon = ("potions\\%s_%s.dds"):format(q, ob.effects[1].id)

local cost = 0	for _, i in ipairs(e.ingredients) do if i then cost = cost + i.value end end	mp:exerciseSkill(16, cost/50)
if cf.alc then	local E = {}	local norm = not M.drop.visible		local gold = 40
	for i, ef in ipairs(ob.effects) do E[i] = ef	if ef.id ~= -1 then local AE = L.ALE[ef.id]		local harm = norm == ef.object.isHarmful		gold = gold + (harm and -20 or 20)
	if AE then E[i].min = math.max(G.PotM * AE[1]/(harm and (1 + Alem*2) or 1), 1)		E[i].max = E[i].min		E[i].duration = math.max(G.PotD * AE[2]/(harm and (1 + Alem) or 1), 1) end end end
	tes3.removeItem{reference = p, item = ob, playSound = false}
	tes3.addItem{reference = p, item = tes3alchemy.create({name = ob.name, mesh = ob.mesh, icon = ob.icon, weight = P.alc20 and 0.3 or 0.5, value = G.PotM * G.PotD * math.max(gold,10) * (P.alc8 and 1 or 0.5), effects = E}),
	count = 1 + (P.alc22 and (math.random(150) <= mp.alchemy.base/2 + mp.luck.base) and 1 or 0), playSound = false}
end			--	tes3.messageBox("id = %s  name = %s   cost = %d", ob.id, ob.name, cost)
end		event.register("potionBrewed", POTIONBREWED)

local function FilterEnchant(e) if M.EncFilt then local o = e.item	 if o.objectType == tes3.objectType.weapon and not o.enchant and o.id:sub(1,2) == "4_" and tes3.getObject(o.id:sub(3)) then e.filter = false end end end
local function FilterAlc(e) if M.Alf and e.item.objectType == tes3.objectType.ingredient then local filt = false	for i, ef in ipairs(e.item.effects) do if ef == M.Alf then
	if L.ALFEF[ef] and M.AlfAt then if e.item.effectAttributeIds[i] == M.AlfAt then filt = true	break end else filt = true	break end
end end		e.filter = filt end end

local function MENUINVENTORYSELECT(e) e.element.height = 1000	e.element.width = 800	local Name = e.element:findChild("MenuInventorySelect_prompt").text			L.skmag = 1
if Name == tes3.findGMST("sIngredients").value then		if not M.AlcFilt then event.register("filterInventorySelect", FilterAlc)	M.AlcFilt = true end		local EL = {{},{},{},{}}
	for l, tab in ipairs(L.ALF) do if (M.drop.visible and l > 2) or (not M.drop.visible and l ~=3) then	EL[l].b = e.element:createThinBorder{}	EL[l].b.autoHeight = true	EL[l].b.autoWidth = true	for i, ef in ipairs(tab) do
		EL[l][i] = EL[l].b:createImage{path = "icons/s/b_" .. tes3.getMagicEffect(ef).icon:sub(3)}		EL[l][i]:register("mouseClick", function() M.Alf = ef	tes3ui.updateInventorySelectTiles() end)
		EL[l][i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = tes3.getMagicEffect(ef).name} end)
	end end end
	for i = 0, 7 do EL[4][i] = EL[4].b:createImage{path = L.ATRIC[i]}		EL[4][i]:register("mouseClick", function() M.AlfAt = i	tes3ui.updateInventorySelectTiles() end)
	EL[4][i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = L.ATR[i]} end) end
	EL[4][8] = EL[4].b:createImage{path = "icons/k/magic_alchemy.dds"}		EL[4][8]:register("mouseClick", function() M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][8]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "All Attributes"} end)
	EL[4][9] = EL[4].b:createImage{path = "icons/potions_blocked.tga"}		EL[4][9]:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][9]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Reset alchemy filter"} end)
--[[
e.element.width = 1200	local vol = 20	local num = #e.element:findChild("PartScrollPane_pane").children	local stolb, lin	--tes3.messageBox("children = %s", num)
for i, s in ipairs(e.element:findChild("PartScrollPane_pane").children) do	s.height = 40		s.width = 300	s.autoHeight = true		s.autoWidth = true
	lin = i%vol		if lin == 0 then lin = vol end		stolb = (i - lin)/vol
	s.absolutePosAlignX = stolb * 0.36		s.absolutePosAlignY = (lin - 1) * 0.05
	--s.positionX = stolb * 300		s.positionY = (lin - 1) * -42
	tes3.messageBox("width = %s", s.width)
end
--]]
else	if Name == tes3.findGMST("sEnchantItems").value and not M.EncFilt then	event.register("filterInventorySelect", FilterEnchant)	M.EncFilt = true end
end end		event.register("uiActivated", MENUINVENTORYSELECT, {filter = "MenuInventorySelect"})

local function ITEMTILEUPDATED(e)	local ob = e.item
	if ob.objectType == tes3.objectType.alchemy then	local eob = ob.effects[1].object	if eob then
		local Eic = e.element:createImage{path = ("icons\\%s"):format(eob.icon)}		--("icons\\s\\b_%s.tga"):format(icon)	Eic.width = 16		Eic.height = 16		Eic.scaleMode = true
		Eic.absolutePosAlignX = 1.0		Eic.absolutePosAlignY = 0.2		Eic.consumeMouseEvents = false
	end
end end		if cf.lab then event.register("itemTileUpdated", ITEMTILEUPDATED) end

local function MENUEXIT(e)
	if M.EncFilt then M.EncFilt = nil 	event.unregister("filterInventorySelect", FilterEnchant) end
	if M.AlcFilt then M.AlcFilt = nil	event.unregister("filterInventorySelect", FilterAlc) end
end			event.register("menuExit", MENUEXIT)

local function MENUQUICK(e)	local Q = {}	Q.bl = e.element:createThinBorder{}		Q.bl.autoHeight = true	Q.bl.autoWidth = true
local CS = mp.currentSpell		CS = CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 and (CS.alwaysSucceeds or P.int3) and CS or nil
for i = 1, 10 do	local s = D.QSP[tostring(i)] and tes3.getObject(D.QSP[tostring(i)])		Q[i] = Q.bl:createImage{path = s and "icons\\" .. s.effects[1].object.bigIcon or "icons/k/magicka.dds"}
	if i == 10 then Q[i]:register("mouseClick", function() D.QSP["0"] = nil		tes3.messageBox("Universal extra-cast slot") end)
	else
		Q[i]:register("mouseClick", function()
			if CS and ic:isShiftDown() then D.QSP[tostring(i)] = CS.id		tes3.messageBox("%s remembered for %s extra-cast slot", CS.name, i) end
			if s and M.QB.normalized >= (P.spd11 and 0.5 or 1) then
				D.QSP["0"] = tostring(i)		QS = tes3.getObject(D.QSP[D.QSP["0"]])		M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon
				tes3.messageBox("%s prepared for extra-cast  Slot %s  %s", QS.name, D.QSP["0"], QS.alwaysSucceeds and "Is a technique" or "")
			end
		end)
	end
	Q[i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = s and ("Extra-cast slot %s  -  %s    Cost = %s    %s"):format(i, s.name, s.magickaCost, s.alwaysSucceeds and "Is a technique" or "") or
	("Extra-cast slot %s  -  %s %s"):format(i, i == 10 and "Universal" or "Press LMB with Shift to place the current spell in this slot.", P.int3 and "" or "Without a special perk only techniques are available")} end)
end	e.element:updateLayout() end		event.register("uiActivated", MENUQUICK, {filter = "MenuQuick"})

local function UISPELLTOOLTIP(e) local tt = e.tooltip:findChild(tes3ui.registerID("helptext"))	tt.text = ("%s (%d)"):format(tt.text, e.spell.magickaCost) end		event.register("uiSpellTooltip", UISPELLTOOLTIP)


--local function ENCHANTEDITEMCREATED(e)	tes3.messageBox("[enchantedItemCreated] Item: %s; Base: %s; Soul: %s (%s); Enchanter: %s", e.object, e.baseObject, e.soulGem, e.soul, e.enchanterReference)
--end		event.register("enchantedItemCreated", ENCHANTEDITEMCREATED)


local function BARTEROFFER(e)	local m = e.mobile	local k = 0		local C		--#e.selling	#e.buying	tile.item, tile.count		Эвент не срабатывает если игрок не изменил цену первого предложения!
if e.value > 0 then k = e.offer/e.value - 1 else k = e.value/e.offer - 1 end
if k > 0 then	local k0 = 0.1 + (((e.value > 0 and P.merc12) or (e.value < 0 and P.merc11)) and 0.1 or 0) + (P.per11 and math.min(mp.personality.current,100)/2000 or 0)		local disp = m.object.disposition or 50
	if k <= k0 then C = 50*((P.merc4 and 1.1 or 1) - k/k0) * math.min(disp, P.per13 and 150 or 100)/100
		* (20 + mp.mercantile.current + mp.speechcraft.current/(P.spec10 and 2.5 or 5) + (P.per12 and math.min(mp.personality.current,100)/5 or 0) + (P.luc5 and math.min(mp.luck.current,100)/5 or 0))/(m:getSkillValue(24)+50)
	else C = 0 end
	M.Bart2.text = ("  %d%%/%d  %d%%/%d%%"):format(C, disp, k*100, k0*100)
	if cf.m6 then tes3.messageBox("Chance = %d  Koef = %.1f%%  Max = %.1f%%  Gold = %d (%d - %d) Merc = %d  Disp = %d", C, k*100, k0*100, e.offer - e.value, e.offer, e.value, m:getSkillValue(24), disp) end
	e.success = math.random(100) < C		if e.success then mp:exerciseSkill(24, math.abs(e.value)/1000 + (e.offer - e.value)/30) end
end
end

local function BarterK(m) local rang = m.object.faction and m.object.faction.playerRank + 1 or 0		return rang,
(mp.mercantile.current + mp.speechcraft.current/(P.spec3 and 5 or 10) + mp.personality.current/(P.per3 and 5 or 10) + (P.luc5 and mp.luck.current/10 or 0) + rang*(P.spec5 and 10 or 5) + (P.per8 and p.object.factionIndex/2 or 0))/200,
(m:getSkillValue(24) + m:getSkillValue(25)/5 + m.personality.current/5 + m.luck.current/10 + 150 - math.min(m.object.disposition or 50, P.per13 and 150 or 100))/200
end
local function CALCBARTERPRICE(e)	local rang, k1, k2 = BarterK(e.mobile)		--if e.item.id == "Gold_001" then e.price = e.count		buying (игрок покупает)
	local k0 = 1 + (e.buying and (P.merc10 and 0.5 or 0.7) or (P.merc2 and 0.8 or 1))		local koef = math.max(k0 - k1 + k2, 1.25)		local val	local ob, ida = e.item, e.itemData
	if ob.isSoulGem and ida and ida.soul then	local soulval = ida.soul.soul	val = (soulval ^ 3) / 10000 + soulval * 2
	elseif ida and ida.condition and ob.maxCondition then val = ob.value * (0.5 + ida.condition * 0.5 / ob.maxCondition)
	else val = ob.value end
	local bp = math.max(e.buying and math.ceil(val * koef) or math.floor(val / koef), 1)			e.price = bp * e.count
	M.Bart1.text = (" %d%%"):format(koef*100 - 100)
	if cf.m6 then tes3.messageBox("%d = %d * %d   Koef = %.2f (%.2f - %.2f + %.2f)  Disp/Rang = %s/%s", e.price, bp, e.count, koef, k0, k1, k2, e.mobile.object.disposition, rang) end
end
local function CALCPRICE(e)	local rang, k1, k2 = BarterK(e.mobile)		local koef = math.max(1 - k1 + k2, 0.5)		e.price = e.basePrice * koef
	if cf.m6 then tes3.messageBox("Price = %d (base = %d)  Rang = %s  koef = %.2f (1 - %.2f + %.2f)", e.price, e.basePrice, rang, koef, k1, k2) end
end
if cf.barter then event.register("calcBarterPrice", CALCBARTERPRICE)		event.register("barterOffer", BARTEROFFER)	
event.register("calcTrainingPrice", CALCPRICE)	event.register("calcSpellPrice", CALCPRICE)	event.register("calcTravelPrice", CALCPRICE) event.register("calcRepairPrice", CALCPRICE) end


local function MENUBARTER(e) local m = tes3ui.getServiceActor()		local ai = m.object.aiConfig	local aisave
	if P.merc9 then aisave = {}		for it, _ in pairs(L.BartT) do aisave[it] = ai[it]	ai[it] = true end		timer.delayOneFrame(function() for it, _ in pairs(L.BartT) do ai[it] = aisave[it] end end) end
	if P.merc3 then local DI = m.reference.data		local bob = m.object.baseObject		if not DI.invest then DI.invest = {g = bob.barterGold, i = 0} end	DI = DI.invest
		local max = math.round(mp.mercantile.base/10)		local gold = math.ceil(DI.g/2)
		M.Invest = e.element:findChild("MenuBarter_yourgold").parent:createFillBar{current = DI.i, max = 10}		M.Invest.width = 150	M.Invest.height = 12	M.InvestW = M.Invest.widget		M.InvestW.fillColor = {1,0.9,0}	M.InvestW.showText = false
		M.Invest:register("help", function() tes3ui.createTooltipMenu():createLabel{text = ("%s: %d / %d  (%s %d)"):format(cf.en and "Investments" or "Инвестиции", M.InvestW.current, max,
		cf.en and "Click LMB to invest" or "Нажмите ЛКМ чтобы инвестировать", gold)} end)
		M.Invest:register("mouseClick", function() if DI.i < max and tes3.getPlayerGold() >= gold then DI.i = DI.i + 1		bob.barterGold = DI.g * math.min(1 + DI.i * 0.1, 2)		mp:exerciseSkill(24, gold/100)
			tes3.removeItem{reference = p, item = "gold_001", count = gold}		M.InvestW.current = DI.i	M.Invest:updateLayout()
			tes3.messageBox("Invested in %s   Gold = %s / %s  Investments: %s / %s", bob.id, m.barterGold, bob.barterGold, DI.i, max)
			if aisave then timer.delayOneFrame(function() bob.modified = true end) else bob.modified = true end
		end end)
	end
	M.Bart = e.element:findChild("MenuBarter_Price").parent
	M.Bart1 = M.Bart:createLabel{text = " 0%"}	M.Bart1:register("help", function() tes3ui.createTooltipMenu():createLabel{text = cf.en and "Markup" or "Наценка"} end)
	M.Bart2 = M.Bart:createLabel{text = " "}	M.Bart2:register("help", function() tes3ui.createTooltipMenu():createLabel{text = cf.en and "Chance for a deal / Merchant's disposition    Profit / Max profit" or
	"Шанс на сделку / Отношение торговца   Выгода / Максимальная выгода"} end)
	M.Bart:reorderChildren(2, 3, 2)
	
--	for _, stack in pairs(m.object.baseObject.inventory) do mwse.log("base  %s - %s", stack.count, stack.object.id) end
--	for _, stack in pairs(m.object.inventory) do mwse.log("%s - %s", stack.count, stack.object.id) end
	--timer.delayOneFrame(function() m.health.current = 0		TFR(2, function() tes3.runLegacyScript{command = "resurrect", reference = m.reference} end) end, timer.real)
end		event.register("uiActivated", MENUBARTER, {filter = "MenuBarter"})

local function MENUPERSUASION(e)	local m = tes3ui.getServiceActor()		if mp.fatigue.normalized > 1 then mp.fatigue.current = mp.fatigue.base end
if mp.intelligence.current + mp.speechcraft.current + (P.spec1 and 100 or 0) > 150 then
	local fPersMod, fLuckMod, fRepMod, fFatigueBase, fFatigueMult, fLevelMod = tes3.findGMST(1150).value, tes3.findGMST(1151).value, tes3.findGMST(1152).value, tes3.findGMST(1006).value, tes3.findGMST(1007).value, tes3.findGMST(1153).value
	local pLucPers = mp.personality.current/fPersMod + mp.luck.current/fLuckMod		local d = 1 - math.abs(math.min(m.object.disposition,100) - 50)/50
	local npcRepLucPers = m.personality.current/fPersMod + m.luck.current/fLuckMod + m.object.factionIndex * fRepMod
	local pFat = fFatigueBase - fFatigueMult * (1 - mp.fatigue.normalized)			local npcFat = fFatigueBase - fFatigueMult * (1 - m.fatigue.normalized)
	local RAT = 50 + (p.object.factionIndex * fRepMod + pLucPers + mp.speechcraft.current) * pFat - (npcRepLucPers + m.speechcraft.current) * npcFat
	local T = {}	T[1] = d * RAT		T[3] = T[1]		T[2] = d * (RAT + p.object.level * fLevelMod - m.object.level * fLevelMod * npcFat)
	local brib = d * (((pLucPers + mp.mercantile.current) * pFat) - ((npcRepLucPers + m.mercantile.current) * npcFat) + 50)
	T[4], T[5], T[6] = brib + tes3.findGMST(1154).value, brib + tes3.findGMST(1155).value, brib + tes3.findGMST(1156).value			for i=1,6 do T[i] = math.max(tes3.findGMST(1159).value, T[i]) end
	for i, b in ipairs(e.element:findChild(-633).children) do if i < 7 then local t = b.children[1]		t.text = ("%s:  %d%%"):format(t.text, T[i]) end end		e.element:updateLayout()
end
end		event.register("uiActivated", MENUPERSUASION, {filter = "MenuPersuasion"})

local function MENUDIALOG(e)	local r	= tes3ui.getServiceActor().reference	local id = r.baseObject.id		-- закомменчен
	if L.SSEL[id] then for i, sp in ipairs(L.SSEL[id]) do mwscript.addSpell{reference = r, spell = sp} end		--tes3.messageBox("%s get new spells", id)
		if id == "marayn dren" then for _, num in ipairs(L.SFS) do mwscript.addSpell{reference = r, spell = "4s_"..num} end end
	end
end		--event.register("uiActivated", MENUDIALOG, {filter = "MenuDialog"})

local function LOCKPICK(e) L.sksec = e.lockData.level/50 end		event.register("lockPick", LOCKPICK)
local function TRAPDISARM(e) if e.lockData and e.lockData.trap then L.sksec = e.lockData.trap.magickaCost * 10 / (e.lockData.trap.magickaCost + 80) end end		event.register("trapDisarm", TRAPDISARM)



L.SKG = {[0]=1, [2]=1, [3]=1, [4]=1, [5]=1, [6]=1, [7]=1, [8]=1, [17]=1, [18]=1, [19]=1, [20]=1, [21]=1, [22]=1, [23]=1, [26]=1, [9]=2, [10]=2, [11]=2, [12]=2, [13]=2, [14]=2, [15]=2, [1]=3, [16]=3, [24]=4, [25]=4}
L.SKFC = {{0, 1, 0}, {0, 1, 1}, {1, 0, 1}, {1, 1, 0}}			L.SKF = {40, 60, 100, 100}
local function EXERCISESKILL(e) local sk = e.skill
	if sk == 8 then	e.progress = e.progress * (1 + mp.encumbrance.normalized * 2) else		-- Атлетика
		local gr = L.SKG[sk]	local fatk = math.max(100 - D.ExpFat[gr]/((gr == 1 or sk == 24) and 60 or 30), 0)
		if L.SK[sk] then
			if sk == 5 then if W.wt == -2 then e.progress = 0	mp:exerciseSkill(7, 1)	return end end		-- Копья в 1 руке
			e.progress = e.progress * L[L.SK[sk]] * fatk/100
		else e.progress = e.progress * fatk/100 end
	--	D.ExpFat[gr] = math.min(D.ExpFat[gr] + cf.expfat * (gr == 1 and 1 or 2), 3600)
		if cf.fatbar then M.FatBarW.current = fatk		M.FatBarW.fillColor = L.SKFC[gr] 	M.FatBar:updateLayout() end
		if cf.m7 then tes3.messageBox("%s exp = %.2f   fatigue koef = %d%% (%d minutes)", tes3.skillName[sk], e.progress, fatk, D.ExpFat[gr]/60) end
	end
end		if cf.trmod then event.register("exerciseSkill", EXERCISESKILL, {priority = -10}) end

local function SKILLRAISED(e)	local sk = e.skill
if cf.levmod then	local lup = 0.25
	for _, s in pairs(p.object.class.majorSkills) do if s == sk then lup = 1 end end		for _, s in pairs(p.object.class.minorSkills) do if s == sk then lup = 1 end end
	local atr, atr2 = tes3.getSkill(sk).attribute, L.SA2[sk]	local Aname, Aname2 = L.ATR[atr], L.ATR[atr2]	D.L[Aname] = D.L[Aname] + 3		D.L[Aname2] = D.L[Aname2] + 2	D.L.levelup = D.L.levelup + lup
	if D.L[Aname] >= 10 then D.L[Aname] = D.L[Aname] - 10		if mp[Aname].base < 100 then tes3.modStatistic{reference = p, attribute = atr, value = 1}	tes3.messageBox("!!! %s +1 !!!", Aname) end end
	if D.L[Aname2] >= 10 then D.L[Aname2] = D.L[Aname2] - 10	if mp[Aname2].base < 100 then tes3.modStatistic{reference = p, attribute = atr2, value = 1}	tes3.messageBox("!!! %s +1 !!!", Aname2) end end
	if D.L.levelup >= 10 then	D.L.levelup = D.L.levelup - 10		if p.object.level < 100 then
		tes3.messageBox("!!! LEVEL UP !!!")		tes3.streamMusic{path="Special/MW_Triumph.mp3"}		mwscript.setLevel{reference = p, level = p.object.level + 1}
		if mp.luck.base < 100 then tes3.modStatistic{reference = p, attribute = 7, value = 1} elseif mp.personality.base < 100 then tes3.modStatistic{reference = p, attribute = 6, value = 1} end
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))		menu:findChild(tes3ui.registerID("MenuStat_level")).text = p.object.level	menu:updateLayout()
		if p.object.level * G.leskoef > D.L.les and G.stop.value == 1 then G.stop.value = 0 end
	end end
	mp.levelUpProgress = math.min(D.L.levelup, 8)	if cf.m7 then tes3.messageBox("Attr: %s + %s = %s,  %s + %s = %s   Lvl + %s = %s", Aname, 3, D.L[Aname], Aname2, 2, D.L[Aname2], lup, D.L.levelup) end
end
if cf.skillp and e.source == "training" then -- progress, book, training
	D.L.les = D.L.les + 1		if p.object.level * G.leskoef <= D.L.les then	G.stop.value = 1 end
	tes3.messageBox("Trained already %s times. %s left. %s", D.L.les, p.object.level * G.leskoef - D.L.les, G.stop.value == 0 and "" or "It's time to put the acquired knowledge into practice")
end
if cf.trmod then	local gr = L.SKG[sk]	local tim = T.T1.timing - G.Exptim
	for i = 1, 4 do	D.ExpFat[i] = math.clamp(D.ExpFat[i] + (gr == i and L.SKF[i] or 20) * cf.expfat - tim, 0, 3600) end		G.Exptim = T.T1.timing
end
end		event.register("skillRaised", SKILLRAISED)


L.UpdateSpellM = function()	local ob, ic, mc	local ls = cf.lin	local F = {}	local S = {}
local MM = tes3ui.findMenu("MenuMagic")	local PL = MM:findChild("MagicMenu_power_names")	PL.borderBottom = 5		PL.flowDirection = "left_to_right"		local SL = MM:findChild("MagicMenu_spell_names")
local MC = MM:findChild("PartScrollPane_pane").children		MC[1].visible = false	MC[3].visible = false	MC[4].visible = false	MC[6].visible = false	MC[7].visible = false
MM:findChild("MagicMenu_power_costs").visible = false		MM:findChild("MagicMenu_spell_costs").visible = false		MM:findChild("MagicMenu_spell_percents").visible = false
MM:findChild("MagicMenu_icons_list_inner").flowDirection = "left_to_right"
for i, s in ipairs(PL.children) do s:createImage{path = "icons\\" .. s:getPropertyObject("MagicMenu_Spell").effects[1].object.bigIcon}	s.minHeight = 32	s.minWidth = 32		s.text = nil end
for i, s in ipairs(SL.children) do s.minHeight = 32		s.minWidth = 32		s.text = nil	ob = s:getPropertyObject("MagicMenu_Spell")		ic = s:createImage{path = "icons\\" .. ob.effects[1].object.bigIcon}
if cf.UIcol ~= 0 then mc = ic:createLabel{text = ("%s"):format(ob.magickaCost)}	mc.color = L.UItcolor[cf.UIcol]		mc.font = 1 end		table.insert(D.FS[ob.id] and F or S, s) end
if SL.children[1] then SL.children[1]:register("destroy", function(e) timer.delayOneFrame(L.UpdateSpellM, timer.real) end) end
local Flin = math.ceil(#F/ls)	local Slin = math.ceil(#S/ls)	local ML = Flin + Slin
MC[5].maxHeight = 32*ML	+ 5		SL.minWidth = 32*(ls+1)		SL.maxWidth = SL.minWidth	SL.minHeight = 32*(ML+1)	SL.maxHeight = SL.minHeight
for i, s in ipairs(F) do s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/ls)-1) end
for i, s in ipairs(S) do s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/ls)-1+Flin) end
end

L.UpdateEnM = function() local MM = tes3ui.findMenu("MenuMagic")		local MC = MM:findChild("PartScrollPane_pane").children		local ob, ic, icm, mc		local ls = cf.lin
local IL = MM:findChild("MagicMenu_item_names")	local ILin = math.max(math.ceil(#IL.children/ls), 1)		MC[8].maxHeight = 32*ILin + 5
IL.minWidth = 32*(ls+1)		IL.maxWidth = IL.minWidth	IL.minHeight = 32*(ILin+1)	IL.maxHeight = IL.minHeight
for i, s in ipairs(IL.children) do s.minHeight = 32		s.minWidth = 32		s.text = nil	ob = s:getPropertyObject("MagicMenu_object")		ic = s:createImage{path = ("icons\\%s"):format(ob.icon)}
if ob.objectType ~= tes3.objectType.book then icm = ic:createImage{path = ("icons\\%s"):format(ob.enchantment.effects[1].object.icon)}		icm.absolutePosAlignX = 1	icm.absolutePosAlignY = 1
if cf.UIcol ~= 0 then mc = ic:createLabel{text = ("%s"):format(ob.enchantment.chargeCost)}	mc.color = L.UItcolor[cf.UIcol]		mc.font = 1 end end
s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ILin * (math.ceil(i/ls)-1) end
if IL.children[1] then IL.children[1]:register("destroy", function(e) M.EnDF = false	if tes3ui.menuMode() then timer.delayOneFrame(L.UpdateEnM, timer.real) end end)	M.EnDF = true end
end


local function MENUENTER(e) if M.INV and M.INV.visible then	L.GetArStat() end
	if cf.UIen and not M.EnDF then local MagM = tes3ui.findMenu("MenuMagic")		if MagM and MagM.visible and MagM:findChild("MagicMenu_item_names").children[1] then L.UpdateEnM() end end
end		event.register("menuEnter", MENUENTER)

local function SAVE(e) if cf.nosave and mp.inCombat then tes3.messageBox(cf.en and "You cannot save the game in combat" or "Нельзя сохраняться в бою")		return false else
	if W.DWM then D.DW = {IDR = W.WR.id, IDL = W.WL.id, CondR = W.DR.condition, CondL = W.DL.condition} end
	if cf.trmod then local tim = T.T1.timing - G.Exptim		for i = 1, 4 do	D.ExpFat[i] = math.max(D.ExpFat[i] - tim, 0) end		G.Exptim = T.T1.timing end
end end		event.register("save", SAVE)

local function LOAD(e) 
if T.AoE.timeLeft then for i, t in pairs(AOE) do t.r:delete() end	AOE = {} end
if T.Run.timeLeft then for i, t in pairs(RUN) do t.r:delete() end RUN = {} end
if T.Tot.timeLeft then for i, t in pairs(TOT) do t.r:delete() end TOT = {} end
if table.size(LI.R) ~= 0 then	for ref, _ in pairs(LI.R) do ref:delete() end  LI.R = {} end
if V.bcd then event.unregister("calcMoveSpeed", L.BLAST)	V.bcd = nil		KSR = {} end
if T.LI.timeLeft then event.unregister("simulate", LI.SIM)	LI.r = nil end
--if T.TS.timeLeft then event.unregister("simulate", SIMTS)	TSK = 1 end
if T.Frost.timeLeft then event.unregister("calcMoveSpeed", CMSFrost) end
if T.DET.timeLeft then DEDEL() end
if p and D.lw then local w = tes3.getObject(D.lw.id)	w.reach = D.lw.r end 
end		event.register("load", LOAD)


local function LOADED(e) p = tes3.player	mp = tes3.mobilePlayer	ad = mp.actionData		pp = p.position		D = tes3.player.data	inv = p.object.inventory	p1 = tes3.player1stPerson.sceneNode		p3 = p.sceneNode
crot = wc.worldCamera.cameraRoot.rotation
if not D.Mmod then D.Mmod = {} end	DM = D.Mmod		if not D.perks then D.perks = {} end	P = D.perks		if not D.FS then D.FS = {} end
if not D.AR then D.AR = {l=0,m=0,h=0,u=25,as=0,ms=1,dk=1,dc=0,cs=0,cc=0,mc=0} end
if not D.L then D.L = {strength = 0, endurance = 0, intelligence = 0, willpower = 0, speed = 0, agility = 0, personality = 0, levelup = 0, les = 0} end
if not D.LEG then D.LEG = {} end
if cf.trmod then	D.ExpFat = D.ExpFat or {0,0,0,0}	G.Exptim = 0 end
AF = setmetatable({}, MT)	SNC = {}	W = {}	FR = {}		V.BAL = {}	V.MET = {}	V.METR = {}		R = {}	A = {}	com = 0		L.ClearEn()		L.SetGlobal()
L.UpdTSK()	--wc.simulationTimeScalar = 1
G.ck = ic.inputMaps[tes3.keybind.readyMagic + 1].code		G.sis = wc.timescale.value/3600
G.LastMana = nil
if tes3.isAffectedBy{reference = p, effect = 501} then AF[p].T501 = timer.start{duration = 1, iterations = -1, callback = L.RechargeTik}	G.REI = {} end

W.l1 = p1:getObjectByName("Bip01 L Hand")		W.l3 = p3:getObjectByName("Bip01 L Hand")		W.r1 = p1:getObjectByName("Bip01 R Hand")		W.r3 = p3:getObjectByName("Bip01 R Hand")
W.w1 = p1:getObjectByName("Weapon Bone")		W.w3 = p3:getObjectByName("Weapon Bone")		event.unregister("playItemSound", L.DWESound, {priority = 10000})		L.MagefAdd()

local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
if w then	if D.DW then
	if w.id == D.DW.IDR and wd.condition == D.DW.CondR then L.DWNEW(w, wd, false)		local ob = tes3.getObject(D.DW.IDL)
		for i, ida in pairs(inv:findItemStack(ob).variables) do if ida.condition == D.DW.CondL and ida ~= W.DR then L.DWNEW(ob, ida, true)	break end end
	elseif w.id == D.DW.IDL and wd.condition == D.DW.CondL then L.DWNEW(w, wd, true)	local ob = tes3.getObject(D.DW.IDR)
		for i, ida in pairs(inv:findItemStack(ob).variables) do if ida.condition == D.DW.CondR and ida ~= W.DL then L.DWNEW(ob, ida, false)	break end end
	end
	D.DW = nil
elseif WT[w.type].dw then L.DWNEW(w, wd, false) end end


for ref, _ in pairs(PRR) do ref:delete() end		PRR = {}
if D.ligspawn then	local spawn = 0	for _, cell in pairs(tes3.getActiveCells()) do for r in cell:iterateReferences() do if r.baseObject.id == "4nm_light" then spawn = spawn + 1	r:delete() end end end
if spawn > 0 then tes3.messageBox("%s lights extra deleted", spawn) end		D.ligspawn = nil	LI.r = nil end

B.poi = tes3.getObject("4b_poison") or tes3alchemy.create{id = "4b_poison", name = "4b_poison", weight = 0.1, icon = "s\\b_tx_s_sun_dmg.dds"}	--B.poi.sourceless = true
if D.AUR then T.AUR = timer.start{duration = P.alt11 and math.max(3 - mp:getSkillValue(11)/200, 2.5) or 3, iterations = -1, callback = L.AuraTik} end
--if D.Prok then T.Prok = timer.start{duration = P.alt11 and math.max(3 - mp:getSkillValue(11)/100, 2) or 3, iterations = -1, callback = L.ProkTik} end


local MU = tes3ui.findMenu(-526)	M.MU = MU		M.Mana = MU:findChild(-865).widget			M.Stat = tes3ui.findMenu(-855)		M.EHB = MU:findChild(-573)		M.INV = tes3ui.findMenu(-314)
local QBL = MU:findChild(-539).parent:createBlock{}		QBL.autoHeight = true	QBL.autoWidth = true	QBL.borderAllSides = 2		QBL.flowDirection = "top_to_bottom"
local QIC = QBL:createThinBorder{}	QIC.height = 36		QIC.width = 36		M.Qicon = QIC:createImage{path = "icons/k/magicka.dds"}		M.Qicon.borderAllSides = 2
M.Qicon:register("help", function() if QS then local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = ("%s (%s)"):format(QS.name, QS.magickaCost)} end end)
M.Qbar = QBL:createFillBar{current = 20, max = 20}	M.Qbar.width = 36		M.Qbar.height = 7		M.QB = M.Qbar.widget	M.QB.showText = false		M.QB.fillColor = {0,1,0}
M.PIC = MU:findChild(-539).parent:createBlock{}		M.PIC.visible = false	M.PIC.autoHeight = true		M.PIC.autoWidth = true	M.PIC.borderAllSides = 2	M.PIC.flowDirection = "top_to_bottom"
local PICb = M.PIC:createThinBorder{}	PICb.height = 36	PICb.width = 36		local Picon = PICb:createImage{path = "icons/potions_blocked.tga"}	Picon.borderAllSides = 2
local potbar = M.PIC:createFillBar{current = 30, max = 30}	potbar.width = 36		potbar.height = 7		M.PCD = potbar.widget	M.PCD.showText = false		M.PCD.fillColor = {0,1,1}
if D.potcd then M.PIC.visible = true	T.POT = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
	if D.potmcd and D.potmcd > D.potcd - G.potlim then M.PCD.max = 5	M.PCD.current = D.potmcd else M.PCD.max = 30	M.PCD.current = D.potcd - G.potlim	if M.PCD.current <= 0 then M.PIC.visible = false end end
	if D.potcd <= 0 then D.potcd = nil	T.POT:cancel() end
end} end
M.drop = MU:findChild(-539).parent:createImage{path = "icons/poisondrop.tga"}	M.drop.visible = not not D.poimod

M.EHB.parent.flowDirection = "top_to_bottom"
M.AR = M.INV and M.INV:findChild(-322) or M.EHB.parent:createBlock{}	M.AR.minWidth = 150		M.AR.width = 150		M.AR:register("help", L.TTAR)
M.MI = (M.INV and M.INV:findChild(-320) or M.AR):createBlock{}	M.MI.autoHeight = true	M.MI.autoWidth = true	M.MI.flowDirection = "top_to_bottom"
M.SL2 = M.MI:createBlock{}	M.SL2.autoHeight = true	M.SL2.autoWidth = true		M.SL3 = M.MI:createBlock{}	M.SL3.autoHeight = true	M.SL3.autoWidth = true		M.SL4 = M.MI:createBlock{}	M.SL4.autoHeight = true	M.SL4.autoWidth = true
M.SI11 = M.AR:createImage{path = "icons/s/repairArmor.tga"}		M.SI11.borderRight = 28		M.ST11 = M.AR:createLabel{}		M.ST11.borderRight = 5
M.SI12 = M.AR:createImage{path = "icons/s/dash.tga"}	M.ST12 = M.AR:createLabel{}
M.SI21 = M.SL2:createImage{path = "icons/s/chargeFire.tga"}			M.ST21 = M.SL2:createLabel{}	M.ST21.borderRight = 5
M.SI21:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = cf.en and "Physical Damage Modifier" or "Модификатор физического урона"} end)
M.SI22 = M.SL2:createImage{path = "icons/s/repairWeapon.tga"}		M.ST22 = M.SL2:createLabel{}
M.SI22:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = cf.en and "Attack Speed / Maximum combo" or "Cкорость атаки / Максимум комбо"} end)
M.SI31 = M.SL3:createImage{path = "icons/s/recharge.tga"}			M.ST31 = M.SL3:createLabel{}	M.ST31.borderRight = 5
M.SI31:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = cf.en and "Magic power modifier" or "Модификатор мощности магии"} end)
M.SI32 = M.SL3:createImage{path = "icons/s/empowerShock.tga"}	M.ST32 = M.SL3:createLabel{}	M.ST32.borderRight = 5
M.SI32:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = cf.en and "Mana cost modifier" or "Модификатор стоимости заклинаний"} end)
M.SI33 = M.SL3:createImage{path = "icons/s/projectileControl.tga"}		M.ST33 = M.SL3:createLabel{}
M.SI33:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = cf.en and "Cast chance modifier" or "Модификатор шанса каста"} end)
M.SI41 = M.SL4:createImage{path = "icons/s/tx_s_sanctuary.dds"}		M.ST41 = M.SL4:createLabel{}	M.ST41.borderRight = 5
M.SI41:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true
tt:createLabel{text = cf.en and "Passive dodge / Dodge maneuver / Stamina cost for dodge maneuver" or "Пассивное уклонение / Маневр уклонения / Расход стамины на маневр уклонения"} end)
M.SI42 = M.SL4:createImage{path = "icons/s/tx_s_feather.dds"}		M.ST42 = M.SL4:createLabel{}
M.SI42:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = cf.en and "Stamina cost for attacks / jumping / running" or "Расход стамины на атаки / прыжки / бег"} end)

M.ENLB = M.MI:createFillBar{current = D.ENconst or 0, max = 4000 + mp.enchant.base*20 + (P.enc16 and 2000 or 0)}
M.ENLB.width = 150	M.ENLB.height = 12	M.ENL = M.ENLB.widget	M.ENL.showText = false	M.ENL.fillColor = {0,1,1}
M.ENLB:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true
tt:createLabel{text = ("%s: %d / %d"):format(cf.en and "Constant enchant limit" or "Лимит постоянных зачарований", M.ENL.current, M.ENL.max)} end)

M.Sbar = M.EHB.parent:createFillBar{current = 100, max = 100}		M.Sbar.visible = false	M.Sbar.widget.showText = false	M.Sbar.width = 65		M.Sbar.height = 7		M.Sbar.widget.fillColor = {0,1,0}
M.Bar4 = M.EHB.parent:createFillBar{current = 0, max = L.GetPCmax()}	M.PC = M.Bar4.widget	M.PC.showText = false	M.Bar4.width = 65	M.Bar4.height = 12	M.PC.fillColor = {1,0,1}
M.Bar4:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true
tt:createLabel{text = ("%s: %d / %d"):format(cf.en and "Potential charge" or "Потенциальный заряд", M.PC.current, M.PC.max)} end)

T.PCT = timer.start{duration = 1, iterations = -1, callback = function() M.PC.current = M.PC.current + M.PC.max * (0.005 + (P.enc18 and math.min(tes3.getEffectMagnitude{reference = p, effect = 76},20)*0.0005 or 0))
if M.PC.normalized > 1 then M.PC.current = M.PC.max		T.PCT:cancel()	D.PCcur = nil	M.Bar4.visible = false else D.PCcur = M.PC.current end end}
M.PC.current = D.PCcur or M.PC.max		if not D.PCcur then T.PCT:cancel()	M.Bar4.visible = false end


if not D.QSP then D.QSP = {} end
QS = D.QSP["0"] and tes3.getObject(D.QSP[D.QSP["0"]]) or (mp.currentSpell and mp.currentSpell.objectType == tes3.objectType.spell and mp.currentSpell.castType == 0 and (P.int3 or mp.currentSpell.alwaysSucceeds) and mp.currentSpell)
if QS then M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon end

W.BAR = MU:findChild(-547):createFillBar{current = 10, max = 10}	W.BAR.width = 36	W.BAR.height = 7	W.BAR.visible = false
W.bar = W.BAR.widget	W.bar.showText = false		W.bar.fillColor = D.NoEnStrike and {1,0,0} or {0,1,1}
T.T1 = timer.start{duration = 1, iterations = -1, callback = function() if W.ob then W.bar.current = W.v.charge end end}
L.GetWstat()
M.WPB = MU:findChild(-547):createFillBar{current = D.poison or 0, max = 300}	M.WPB.width = 36	M.WPB.height = 7	M.WPB.widget.showText = false	M.WPB.widget.fillColor = {0,1,0}	M.WPB.visible = not not D.poison
M.MCbar = MU:findChild(-548):createFillBar{current = 0, max = 100}	M.MCbar.width = 36	M.MCbar.height = 7	M.MCB = M.MCbar.widget	M.MCB.showText = false	M.MCB.fillColor = {0,1,1}

M.CombK = MU:findChild(-543):createLabel{text = ""}		M.CombK.color = {0.5,0.5,0}		M.CombK.absolutePosAlignX = 1	M.CombK.absolutePosAlignY = 0		--M.CombK.visible = false
M.NoPar = MU:findChild(-543):createLabel{text = "*"}	M.NoPar.color = {1,0,0}			M.NoPar.absolutePosAlignX = 0	M.NoPar.absolutePosAlignY = 1		M.NoPar.visible = not not D.nopar

MU:findChild(-866).parent.flowDirection = "top_to_bottom"
M.SHbar = MU:findChild(-866).parent:createFillBar{current = 100, max = 100}	M.SHbar.visible = false		M.SHbar.widget.showText = false	M.SHbar.width = 65	M.SHbar.height = 7	M.SHbar.widget.fillColor = {0,1,1}

if cf.fatbar then
	M.MAP = MU:findChild(tes3ui.registerID("MenuMap_panel")).parent		M.MAP.flowDirection = "top_to_bottom"	--M.MAP.alpha = tes3.worldController.menuAlpha
	M.FatBar = M.MAP:createFillBar{current = 100, max = 100}	M.FatBar.width = 65		M.FatBar.height = 8		M.FatBarW = M.FatBar.widget		M.FatBarW.showText = false		M.FatBarW.fillColor = {0, 1, 0}
	M.FatBar:register("help", function() tes3ui.createTooltipMenu():createLabel{text = cf.en and "Training fatigue" or "Тренировочная усталость"} end)		
	M.MAP:reorderChildren(0, table.size(M.MAP.children) - 1, 1)
end


local o = tes3.getObject("4s_546")
if not o or o.effects[1].min ~= 3 then	local s		for _, t in ipairs(L.NEWSP) do s = tes3.getObject("4s_"..t[1]) or tes3spell.create("4s_"..t[1])	--s.sourceless = true
	s.name = t[9]		s.magickaCost = t[8] or 0	s = s.effects[1]	s.rangeType = t[2]	s.id = t[3]		s.min = t[4]	s.max = t[5]	s.radius = t[6]		s.duration = t[7]
end		tes3.messageBox("New effects and spells updated")	end

o = tes3.getObject("4p_mag1")				--mag1 = {84,1,"res04","Мастер Восстановления","Master of Restoration"}
if not o or o.name ~= (cf.en and "Master of Restoration" or "Мастер Восстановления") or o.effects[1].max ~= 1 then	local s		tes3.messageBox("Perk abilities updated")
	for id, t in pairs(L.PA) do s = tes3.getObject("4p_"..id) or tes3spell.create("4p_"..id)	s.name = cf.en and t[5] or t[4] or "4p_"..id	s.castType = 1	s = s.effects[1]	s.id = t[1]		s.min = t[2]	s.max = t.m or t[2] end
	for id, t in pairs(L.NSU) do s = tes3.getObject(id) or tes3spell.create(id)		s.name = cf.en and t.en or t.ru		s.magickaCost = t.c		if t.f then s.alwaysSucceeds = true end		s = s.effects
	for i, ef in ipairs(t) do s[i].rangeType = t.rt	or 0	s[i].id	= ef[1]		s[i].min = ef[2] or t.m		s[i].max = ef[3] or t.ma	s[i].radius = ef.r or t.r or 0		s[i].duration = ef.d or t.d		s[i].attribute = ef.a or -1 end end
end

o = tes3.getObject("marayn dren")
if not o.spells:contains("4s_570") then				for _, num in ipairs(L.SFS) do o.spells:add("4s_"..num) end
	for id, list in pairs(L.SSEL) do o = tes3.getObject(id)		for i, sp in ipairs(list) do o.spells:add(sp) end	o.modified = true end	tes3.messageBox("Spellsellers get new spells")
end

if not e.newGame then L.READY = true	local PS = {}	local PA = {}	PS.sp = p.object.class.specialization	local id	local b = L.BS[mp.birthsign.id]
	for _, s in pairs(p.object.class.majorSkills) do PS[s] = 1 end		for _, s in pairs(p.object.class.minorSkills) do PS[s] = 2 end		for _, at in pairs(p.object.class.attributes) do PA[at] = true end
	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do	id = L.PRL[i][3]		--mp[L.PRL[i][1]].type
		if i < 9 then t.x = PA[id] and 1 or 2 else t.x = (PS[id] or 3) - (L.SS[id] == PS.sp and (PA[L.SA[id]] or PA[L.SA2[id]]) and 1 or 0) end		t.f = math.max(t.x - (t.c or 0),0)
	end end
	if not D.chimstar and b and p.object.level >= 20 then if b ~= "shadow" then mwscript.removeSpell{reference = p, spell = "4nm_star_"..b.."1"}	mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."2"} end
		if tes3.getObject("4nm_star_"..b.."2a") then mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."2a"} end
		if b == "atronach" then mwscript.addSpell{reference = p, spell = "4as_atr4"}	mwscript.addSpell{reference = p, spell = "4as_atr5"}	mwscript.addSpell{reference = p, spell = "4as_atr6"} end
		tes3.messageBox(cf.en and "You have awakened the power of your Birth Sign" or "Вы пробудили силу своего Знака")	D.chimstar = 1
	elseif D.chimstar == 1 and b and p.object.level >= 50 then if b ~= "shadow" then mwscript.removeSpell{reference = p, spell = "4nm_star_"..b.."2"}	mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."3"} end
		if tes3.getObject("4nm_star_"..b.."3a") then mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."3a"} end
		if b == "atronach" then mwscript.addSpell{reference = p, spell = "4as_atr7"}	mwscript.addSpell{reference = p, spell = "4as_atr8"}	mwscript.addSpell{reference = p, spell = "4as_atr9"}	mwscript.addSpell{reference = p, spell = "4as_atr10"} end
		tes3.messageBox(cf.en and "You have ascended to level of the gods and unleashed the true potential of your Birth Sign" or "Вы вознеслись до уровня богов и раскрыли истинный потенциал своего Знака")	D.chimstar = 2
	end
	if cf.UIsp then L.UpdateSpellM() end
	if cf.UIen then local MM = tes3ui.findMenu("MenuMagic")	MM:findChild("MagicMenu_item_costs").visible = false		MM:findChild("MagicMenu_item_percents").visible = false		M.EnDF = false end
else L.READY = nil end
end		event.register("loaded", LOADED)

local function initialized(e)	wc = tes3.worldController	ic = wc.inputController		MB = ic.mouseState.buttons		local o, E
--ГМСТ едины для игровой сессии и обновляются из плагинов при старте игры. Если поменять ГМСТ через луа, то они сохранятся для всех последующих сейвов в этой сессии но сбросятся на дефолтные при следующем запуске игры
G.KOGMST = tes3.findGMST("iKnockDownOddsBase")			G.KOGMST.value = 0				G.HandReach = tes3.findGMST("fHandToHandReach")
G.CombatDistance = tes3.findGMST("fCombatDistance")		G.CombatAngleXY = tes3.findGMST("fCombatAngleXY")			--tes3.findGMST("fCombatAngleZ").value = 0.6
--G.CriticalMult = tes3.findGMST("fCombatCriticalStrikeMult")

tes3.findGMST("fEffectCostMult").value = 1				tes3.findGMST("fNPCbaseMagickaMult").value = 3			tes3.findGMST("iAutoSpellTimesCanCast").value = 5
tes3.findGMST("fTargetSpellMaxSpeed").value = 2000		tes3.findGMST("fMagicCreatureCastDelay").value = 0		tes3.findGMST("fEnchantmentMult").value = 0.1
tes3.findGMST("fFatigueSpellBase").value = 0.5			tes3.findGMST("fFatigueSpellMult").value = 0.5			tes3.findGMST("fElementalShieldMult").value = 1
tes3.findGMST("fEncumberedMoveEffect").value = 0.5		tes3.findGMST("fBaseRunMultiplier").value = 3			tes3.findGMST("fSwimRunBase").value = 0.3
tes3.findGMST("fFallDistanceMult").value = 0.1
tes3.findGMST("fFatigueReturnBase").value = 0			tes3.findGMST("fFatigueReturnMult").value = 0.2		tes3.findGMST("fFatigueBase").value = 1.5				tes3.findGMST("fFatigueMult").value = 0.5
tes3.findGMST("fFatigueAttackBase").value = 10			tes3.findGMST("fFatigueAttackMult").value = 10		tes3.findGMST("fWeaponFatigueMult").value = 1
tes3.findGMST("fFatigueBlockBase").value = 5			tes3.findGMST("fFatigueBlockMult").value = 10		tes3.findGMST("fWeaponFatigueBlockMult").value = 2
tes3.findGMST("fCombatBlockLeftAngle").value = -1		tes3.findGMST("fCombatBlockRightAngle").value = 0.5
tes3.findGMST("fFatigueRunBase").value = 10				tes3.findGMST("fFatigueRunMult").value = 30			tes3.findGMST("fFatigueSwimWalkBase").value = 10		tes3.findGMST("fFatigueSwimWalkMult").value = 30
tes3.findGMST("fFatigueSwimRunBase").value = 20			tes3.findGMST("fFatigueSwimRunMult").value = 30		tes3.findGMST("fFatigueSneakBase").value = 0			tes3.findGMST("fFatigueSneakMult").value = 10
tes3.findGMST("fMinHandToHandMult").value = 0			tes3.findGMST("fMaxHandToHandMult").value = 0.2		tes3.findGMST("fHandtoHandHealthPer").value = 0.25
tes3.findGMST("fKnockDownMult").value = 0				tes3.findGMST("iKnockDownOddsMult").value = 0		tes3.findGMST("fCombatKODamageMult").value = 1.5		
tes3.findGMST("fDamageStrengthBase").value = 1			tes3.findGMST("fDamageStrengthMult").value = 0.05	tes3.findGMST("fCombatArmorMinMult").value = 0.01
tes3.findGMST("fProjectileMinSpeed").value = 1000		tes3.findGMST("fProjectileMaxSpeed").value = 5000	tes3.findGMST("fThrownWeaponMinSpeed").value = 1000			tes3.findGMST("fThrownWeaponMaxSpeed").value = 3000
tes3.findGMST("fCombatDelayCreature").value = -0.4		tes3.findGMST("fCombatDelayNPC").value = -0.4		
tes3.findGMST("fAIFleeHealthMult").value = 88.888		tes3.findGMST("fFleeDistance").value = 5000			tes3.findGMST("fAIRangeMeleeWeaponMult").value = 70			tes3.findGMST("fSuffocationDamage").value = 10
tes3.findGMST("fAIFleeFleeMult").value = 0	--0.3	 float rating = (1.0f - healthPercentage) * fAIFleeHealthMult + flee * fAIFleeFleeMult;
tes3.findGMST("fSleepRestMod").value = 0.5				tes3.findGMST("fDispDiseaseMod").value = -30		tes3.findGMST("fSpecialSkillBonus").value = 0.8
tes3.findGMST("fRestMagicMult").value = 0.5				tes3.findGMST("iMonthsToRespawn").value = 7	
tes3.findGMST("sArmor").value = " "		tes3.findGMST("sTo").value = "-"
tes3.findGMST("sMagicPCResisted").value = ""	tes3.findGMST("sMagicTargetResisted").value = ""	tes3.findGMST("sMagicInsufficientCharge").value = ""	tes3.findGMST("sTargetCriticalStrike").value = ""	

if cf.alc then tes3.findGMST("fPotionT1MagMult").value = 2		tes3.findGMST("fPotionT1DurMult").value = 0.5 end

--for _, v in ipairs(L.SREG) do o = tes3spell.create("4s_"..v, "4s_"..v) 	o.magickaCost = 0	o.sourceless = true		S[v] = o end
for _, n in ipairs(L.BREG) do o = tes3alchemy.create{id = "4b_"..n, name = "4b_"..n, icon = "s\\b_tx_s_sun_dmg.dds"} 	o.sourceless = true 	B[n] = o 	G[n] = o.effects end
for _, t in ipairs(L.BU) do o = tes3alchemy.create{id = "4b_"..t.n, name = "4b_"..t.n, icon = "s\\b_tx_s_sun_dmg.dds"}	o.sourceless = true		o.weight = t.w or 0		B[t.n] = o		E = o.effects
for i, ef in ipairs(t) do E[i].rangeType = ef[1]	E[i].id = ef[2]		E[i].min = ef[3]	E[i].max = ef[4]	E[i].radius = ef[5]		E[i].duration = ef[6] end end

BAM.E = tes3.getObject("4nm_e_boundammo").effects		LI.l = tes3.getObject("4nm_light")		L.stone = tes3.getObject("4nm_stone")		L.magef = tes3.loadMesh("e\\magef.nif")
L.pbottle = tes3.getObject("4nm_poisonbottle")
L.DEO = {["door"] = {m = tes3.loadMesh("e\\detect_door.nif"), s = 3}, ["cont"] = {m = tes3.loadMesh("e\\detect_cont.nif"), s = 3}, ["npc"] = {m = tes3.loadMesh("e\\detect_npc.nif"), s = 1},
["ani"] = {m = tes3.loadMesh("e\\detect_animal.nif"), s = 1}, ["dae"] = {m = tes3.loadMesh("e\\detect_daedra.nif"), s = 1}, ["und"] = {m = tes3.loadMesh("e\\detect_undead.nif"), s = 1},
["robo"] = {m = tes3.loadMesh("e\\detect_robo.nif"), s = 1}, ["key"] = {m = tes3.loadMesh("e\\detect_key.nif"), s = 2}, ["en"] = {m = tes3.loadMesh("e\\detect_ench.nif"), s = 2}}

local S = {[0] = {l = {0.5,0,1}, p = "vfx_alt_glow.tga", sc = "alteration cast", sb = "alteration bolt", sh = "alteration hit", sa = "alteration area", vc = "VFX_AlterationCast", vb = "VFX_AlterationBolt", vh = "VFX_AlterationHit", va = "VFX_AlterationArea"},
[1] = {l = {1,1,0}, p = "vfx_conj_flare02.tga", sc = "conjuration cast", sb = "conjuration bolt", sh = "conjuration hit", sa = "conjuration area", vc = "VFX_ConjureCast", vb = "VFX_ConjureBolt", vh = "VFX_DefaultHit", va = "VFX_ConjureArea"},
[2] = {l = {1,0,0}, p = "vfx_alpha_bolt01.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_DestructCast", vb = "VFX_DestructBolt", vh = "VFX_DestructHit", va = "VFX_DestructArea"},
[3] = {l = {0,1,0.5}, p = "vfx_greenglow.tga", sc = "illusion cast", sb = "illusion bolt", sh = "illusion hit", sa = "illusion area", vc = "VFX_IllusionCast", vb = "VFX_IllusionBolt", vh = "VFX_IllusionHit", va = "VFX_IllusionArea"},
[4] = {l = {1,0.5,1}, p = "vfx_myst_flare01.tga", sc = "mysticism cast", sb = "mysticism bolt", sh = "mysticism hit", sa = "mysticism area", vc = "VFX_MysticismCast", vb = "VFX_MysticismBolt", vh = "VFX_MysticismHit", va = "VFX_MysticismArea"},
[5] = {l = {0,0.5,1}, p = "vfx_bluecloud.tga", sc = "restoration cast", sb = "restoration bolt", sh = "restoration hit", sa = "restoration area", vc = "VFX_RestorationCast", vb = "VFX_RestoreBolt", vh = "VFX_RestorationHit", va = "VFX_RestorationArea"},
[6] = {l = {1,0.5,0}, p = "e\\vfx_##lensw.dds", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_FireCast", vb = "VFX_FireBolt", vh = "VFX_FireHit", va = "VFX_FireArea"},
[7] = {l = {0,1,1}, p = "e\\vfx_frsstr.dds", sc = "frost_cast", sb = "frost_bolt", sh = "frost_hit", sa = "frost area", vc = "VFX_FrostCast", vb = "VFX_FrostBolt", vh = "VFX_FrostHit", va = "VFX_FrostArea"},
[8] = {l = {1,0,1}, p = "e\\vfx_shock1.dds", sc = "shock cast", sb = "shock bolt", sh = "shock hit", sa = "shock area", vc = "VFX_LightningCast", vb = "VFX_ShockBolt", vh = "VFX_LightningHit", va = "VFX_LightningArea"},
[9] = {l = {0.5,1,0}, p = "vfx_poison.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_PoisonCast", vb = "VFX_PoisonBolt", vh = "VFX_PoisonHit", va = "VFX_PoisonArea"},
[10] = {l = {1,0,0.5}, p = "e\\vfx_spark_red.dds", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_DestructCast", vb = "VFX_DestructBolt", vh = "VFX_DestructHit", va = "VFX_DestructArea"}}
local MEN = {{600, "dash", "Dash", 1, s=0, "Gives the ability to quickly move in the selected direction, as well as make kinetic kicks", c1=0, c2=0},
{601, "boundAmmo", "Bound ammo", 1, s=1, "Bounds arrows, bolts or throwing stars from Oblivion", c1=0, c2=0, nom=1},
{602, "kineticStrike", "Kinetic strike", 2, s=0, "A burst of power knocks back enemies and deals damage", c0=0, c1=0, nod=1, h=1, snd=2, col = KSCollision},
{603, "boundWeapon", "Bound weapon", 5, s=1, "Bounds any weapon from Oblivion", c1=0, c2=0, nom=1, tik = function(e) e:triggerBoundWeapon(D and D.boundw or "4_bound longsword") end},
{610, "bolt", "Dummy bolt", 0.01, s=2, ss=6, "Dummy bolt", c0=0, c1=0, h=1, nod=1, nom=1, unr=1, ale=0, als=0, vfb = "VFX_DefaultBolt", sb = "Sound Test", tik = L.METW},
{500, "teleport", "Teleport", 10, s=4, "Teleports caster to the point, indicated by him", c0=0, c1=0, nod=1, nom=1, sp=2, col = TeleportCollision},
{501, "recharge", "Recharge", 10, s=4, "Restores charges of equipped magic items", ale=0},
{502, "repairWeapon", "Repair weapon", 5, s=0, "Repairing equipped weapon"},
{503, "repairArmor", "Repair armor", 3, s=0, "Repairing equipped armor"},
{504, "lightTarget", "Magic light", 0.1, s=0, "Creates a light, following a caster or attached to hit point", snd=3, vfx=3, col = LightCollision},
{505, "teleportToTown", "Teleport to town", 1000, s=4, "Teleports the caster to the town", c1=0, c2=0, nod=1, nom=1, ale=0, tik = L.TownTP},
{506, "projectileControl", "Projectile control", 1, s=0, "Allows to control projectile flight", c1=0, c2=0, nom=1},
{507, "reflectSpell", "Reflect Spell", 1, s=4, "Reflects enemy spells"},
{508, "kineticShield", "Kinetic shield", 1, s=0, "Absorbs physical damage, spending mana", vfh="VFX_ShieldHit", vfc="VFX_ShieldCast"},
{509, "lifeLeech", "Life leech", 0.5, s=4, "Heals for a portion of your physical damage"},
{510, "timeShift", "Time shift", 1, s=3, "Slows perception of time"},
{511, "chargeFire", "Charge fire", 0.5, s=4, ss=6, "Adds fire damage to attacks", snd=4},
{512, "chargeFrost", "Charge frost", 0.5, s=4, ss=7, "Adds frost damage to attacks", snd=4},
{513, "chargeShock", "Charge shock", 0.5, s=4, ss=8, "Adds shock damage to attacks", snd=4},
{514, "chargePoison", "Charge poison", 0.5, s=4, ss=9, "Adds poison damage to attacks", snd=4},
{515, "chargeVitality", "Charge chaos", 0.5, s=4, ss=10, "Adds chaos damage to attacks", snd=4},
{516, "auraFire", "Aura fire", 0.5, s=2, ss=6, "Deals fire damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_FireShield"},
{517, "auraFrost", "Aura frost", 0.5, s=2, ss=7, "Deals frost damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_FrostShield"},
{518, "auraShock", "Aura shock", 0.5, s=2, ss=8, "Deals shock damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_LightningShield"},
{519, "auraPoison", "Aura poison", 0.5, s=2, ss=9, "Deals poison damage to all enemies around you", con=1, c1=0, c2=0},
{520, "auraVitality", "Aura chaos", 0.5, s=2, ss=10, "Deals chaos damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_DestructHit"},
{521, "aoeFire", "AoE fire", 3, s=2, ss=6, "Deals fire damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{522, "aoeFrost", "AoE frost", 3, s=2, ss=7, "Deals frost damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{523, "aoeShock", "AoE shock", 4, s=2, ss=8, "Deals shock damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{524, "aoePoison", "AoE poison", 5, s=2, ss=9, "Deals poison damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{525, "aoeVitality", "AoE chaos", 4, s=2, ss=10, "Deals chaos damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{526, "runeFire", "Rune fire", 3, s=2, ss=6, "Creates fire rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{527, "runeFrost", "Rune frost", 3, s=2, ss=7, "Creates frost rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{528, "runeShock", "Rune shock", 4, s=2, ss=8, "Creates shock rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{529, "runePoison", "Rune poison", 5, s=2, ss=9, "Creates poison rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{530, "runeVitality", "Rune chaos", 4, s=2, ss=10, "Creates chaos rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{531, "explodeFire", "Explode fire", 0.5, s=4, ss=6, "Adds fire blasts to your magic projectiles", c1=0, c2=0, snd=4},
{532, "explodeFrost", "Explode frost", 0.5, s=4, ss=7, "Adds frost blasts to your magic projectiles", c1=0, c2=0, snd=4},
{533, "explodeShock", "Explode shock", 0.5, s=4, ss=8, "Adds shock blasts to your magic projectiles", c1=0, c2=0, snd=4},
{534, "explodePoison", "Explode poison", 0.5, s=4, ss=9, "Adds poison blasts to your magic projectiles", c1=0, c2=0, snd=4},
{535, "explodeVitality", "Explode chaos", 0.5, s=4, ss=10, "Adds chaos blasts to your magic projectiles", c1=0, c2=0, snd=4},
{536, "shotgunFire", "Spread fire", 15, s=2, ss=6, "Shoots a group of fire balls", c0=0, c2=0},
{537, "shotgunFrost", "Spread frost", 15, s=2, ss=7, "Shoots a group of frost balls", c0=0, c2=0},
{538, "shotgunShock", "Spread shock", 20, s=2, ss=8, "Shoots a group of shock balls", c0=0, c2=0},
{539, "shotgunPoison", "Spread poison", 25, s=2, ss=9, "Shoots a group of poison balls", c0=0, c2=0},
{540, "shotgunVitality", "Spread chaos", 20, s=2, ss=10, "Shoots a group of chaos balls", c0=0, c2=0},
{541, "dischargeFire", "Discharge fire", 3, s=2, ss=6, "Explosion of fire strikes everyone around", c0=0, c2=0},
{542, "dischargeFrost", "Discharge frost", 3, s=2, ss=7, "Explosion of frost strikes everyone around", c0=0, c2=0},
{543, "dischargeShock", "Discharge shock", 4, s=2, ss=8, "Explosion of lightning strikes everyone around", c0=0, c2=0},
{544, "dischargePoison", "Discharge poison", 5, s=2, ss=9, "Explosion of poison strikes everyone around", c0=0, c2=0},
{545, "dischargeVitality", "Discharge chaos", 4, s=2, ss=10, "Explosion of chaos strikes everyone around", c0=0, c2=0},
{546, "rayFire", "Ray fire", 30, s=2, ss=6, "Fires a ray of fire", c0=0, c2=0},
{547, "rayFrost", "Ray frost", 30, s=2, ss=7, "Fires a ray of frost", c0=0, c2=0},
{548, "rayShock", "Ray shock", 40, s=2, ss=8, "Fires a ray of lightning", c0=0, c2=0},
{549, "rayPoison", "Ray poison", 50, s=2, ss=9, "Fires a ray of poison", c0=0, c2=0},
{550, "rayVitality", "Ray chaos", 40, s=2, ss=10, "Fires a ray of chaos magic", c0=0, c2=0},
{551, "totemFire", "Totem fire", 0.5, s=4, ss=6, "Creates a totem that shoots fire at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{552, "totemFrost", "Totem frost", 0.5, s=4, ss=7, "Creates a totem that shoots frost at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{553, "totemShock", "Totem shock", 0.5, s=4, ss=8, "Creates a totem that shoots lightning at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{554, "totemPoison", "Totem poison", 0.5, s=4, ss=9, "Creates a totem that shoots poison at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{555, "totemVitality", "Totem chaos", 0.5, s=4, ss=10, "Creates a totem that shoots chaos balls at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{556, "empowerFire", "Empower fire", 1, s=4, ss=6, "Empower your fire spells", snd=4},
{557, "empowerFrost", "Empower frost", 1, s=4, ss=7, "Empower your frost spells", snd=4},
{558, "empowerShock", "Empower shock", 1, s=4, ss=8, "Empower your shock spells", snd=4},
{559, "empowerPoison", "Empower poison", 1, s=4, ss=9, "Empower your poison spells", snd=4},
{560, "empowerVitality", "Empower chaos", 1, s=4, ss=10, "Empower your chaos damage spells", snd=4},
{561, "reflectFire", "Reflect fire", 1, s=4, ss=6, "Converts enemy spells energy into fire and reflects it", snd=4},
{562, "reflectFrost", "Reflect frost", 1, s=4, ss=7, "Converts enemy spells energy into frost and reflects it", snd=4},
{563, "reflectShock", "Reflect shock", 1, s=4, ss=8, "Converts enemy spells energy into lightning and reflects it", snd=4},
{564, "reflectPoison", "Reflect poison", 1, s=4, ss=9, "Converts enemy spells energy into poison and reflects it", snd=4},
{565, "reflectVitality", "Reflect chaos", 1, s=4, ss=10, "Converts enemy spells energy into chaos and reflects it", snd=4},
{566, "waveFire", "Wave fire", 6, s=2, ss=6, "Launches a wave of fire, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{567, "waveFrost", "Wave frost", 6, s=2, ss=7, "Launches a wave of frost, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{568, "waveShock", "Wave shock", 8, s=2, ss=8, "Launches a wave of shock, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{569, "wavePoison", "Wave poison", 10, s=2, ss=9, "Launches a wave of poison, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{570, "waveVitality", "Wave chaos", 8, s=2, ss=10, "Launches a wave of chaos, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol}}
for _,e in ipairs(MEN) do tes3.claimSpellEffectId(e[2], e[1])	tes3.addMagicEffect{id = e[1], name = e[3], baseCost = e[4], school = e.s, description = e[5] or e[3],
allowEnchanting = not e.ale, allowSpellmaking = not e.als, canCastSelf = not e.c0, canCastTarget = not e.c1, canCastTouch = not e.c2, isHarmful = not not e.h, hasNoDuration = not not e.nod, hasNoMagnitude = not not e.nom,
nonRecastable = not not e.nor, hasContinuousVFX = not not e.con, appliesOnce = not e.apo, unreflectable = not not e.unr, casterLinked = false, illegalDaedra = false, targetsAttributes = false, targetsSkills = false, usesNegativeLighting = false,
castSound = S[e.snd or e.ss or e.s].sc, boltSound = e.sb or S[e.snd or e.ss or e.s].sb, hitSound = S[e.snd or e.ss or e.s].sh, areaSound = S[e.snd or e.ss or e.s].sa,
castVFX = e.vfc or S[e.vfx or e.ss or e.s].vc, boltVFX = e.vfb or S[e.vfx or e.ss or e.s].vb, hitVFX = e.vfh or S[e.vfx or e.ss or e.s].vh, areaVFX = e.vfa or S[e.vfx or e.ss or e.s].va,
particleTexture = e.p or S[e.ss or e.s].p, icon = "s\\"..e[2]..".tga", speed = e.sp or 1, size = 1, sizeCap = 50, lighting = S[e.ss or e.s].l, onCollision = e.col or nil, onTick = e.tik or nil} end

local OBJ = {["potion_skooma_01"] = {[4]=510},	["4nm_star_shadow3a"] = {[7]=600},		["thunder fist"] = {[2]=512, [3]=513},		["wizard's brand"] = {[2]=511, [3]=513},
["4a_con1"] = {[1]=601,[7]=603},	["4a_enc"] = {[1]=501},		["4a_alt1"] = {[3]=600},		["4a_mys3"] = {[2]=507},	["4a_sec"] = {[1]=510},		["4a_arm"] = {[1]=502,[2]=503},
["ward of endus"] = {[2]=501,[3]=556,[4]=557,[5]=558},	["ward of odros"] = {[3]=511,[4]=561},		["ward of vemyn"] = {[3]=509},		["ward of tureynul"] = {[6]=507,[7]=508},	["ward of uthol"] = {[3]=506},
["ward of araynys"] = {[2]=501},	["ward of dagoth"] = {[2]=510},		["drakespride_en_uniq"] = {[2]=501},		--["ward of gilvoth"] = {[4]=561,[5]=562,[6]=563,[7]=506},	--["necromancers_amulet_en"] = {[5]=501},
["levitate_peakstar_en"] = {[2]=600}, 			["Wind Whisper"] = {[3]=600}, 			["Caius' Subtlety"] = {[2]=600}, 		["bm_amulspd"] = {[4]=600}, 				["wraithguard_en"] = {[1]=507,[2]=508},
["warlock's sphere"] = {[4]=507,[5]=509}, 		["watchful spirit"] = {[3]=508}, 		["hircine's blessing"] = {[2]=507},			["theranafeather_en_uniq"] = {[2]=508}, 	["Marara's Boon"] = {[2]=507,[3]=508},
["hort_ledd_shield"] = {[2]=507,[3]=508}, 		["will_en"] = {[2]=507},				["armor of god_en"] = {[1]=507,[2]=508}, 	["Spell Breaker"] = {[2]=507},				["dragon aura"] = {[2]=556},
["stroris"] = {[2]=512,[3]=557,[4]=562},		["bitter mercy"] = {[2]=513,[3]=558,[4]=563},
["bound cuirass_effects_en"] = {[1]=508},		["bound boots_effect_en"] = {[2]=600},		["bound shield_effect_en"] = {[1]=507,[2]=508},
["tenpaceboots_en"] = {[5]=600}, 				["we_stormforge_en"] = {[2]=513}, 		["mazedband"] = {[1]=500},
} -- [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=},
for id, t in pairs(OBJ) do E = tes3.getObject(id).effects	for i, eid in pairs(t) do E[i].id = eid end end

if cf.scroll then for b in tes3.iterateObjects(tes3.objectType.book) do if b.type == 1 and b.enchantment then b.icon = ("scrolls\\tx_scroll_%s.dds"):format(b.enchantment.effects[1].id) end end end
mwse.memory.writeFunctionCall{address = 0x4D0CD5, length = 0x10, signature = {returns = "int"}, call = function() if P then return tes3.player.object.level > 99 and 100 or math.max(tes3.player.object.level * (P.luc11 and 1 or 0.3), 5) end end}
mwse.memory.writeBytes{address = 0x5C3B6C, bytes={0x90, 0x90, 0x90, 0x90, 0xD9, 0x44, 0x24, 0x10}} -- фикс стоимости зачарований
mwse.memory.writeNoOperation{address = 0x515203, length = 0x515215 - 0x515203}	-- убирает звук фейла зачарований
mwse.memory.writeFunctionCall{address = 0x515217, previousCall = 0x4A9F00, signature = {this = "tes3object", returns = "tes3object"}, call = function() end}	-- убирает звук фейла зачарований
end		event.register("initialized", initialized)

local function registerModConfig()		local template = mwse.mcm.createTemplate("4NM")	template:saveOnClose("4NM", cf)		template:register()		local var = mwse.mcm.createTableVariable
local p1, p0, p3, p2, pm = template:createPage(cf.en and "Interface" or "Интерфейс"), template:createPage(cf.en and "Modules" or "Модули"), template:createPage(cf.en and "Mechanics" or "Удобства"),
template:createPage(cf.en and "Buttons" or "Кнопки"), template:createPage(cf.en and "Mouse" or "Мышь")
p0:createSlider{label = cf.en and "Difficulty level: 1 - Hardcore, 2 - Medium, 3 - Easy. The difficulty only affects the number of perkpoints per level" or
"Уровень сложности: 1 - Хардкор, 2 - Средне, 3 - Легко. Сложность влияет только на количество перкпоинтов за уровень", min = 1, max = 3, step = 1, jump = 1, variable = var{id = "pmult", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable PvP-mode (NPCs move better in combat)" or "ПвП-мод (нпс лучше двигаются в бою)", variable = var{id = "pvp", table = cf}}
p0:createYesNoButton{label = cf.en and "NPCs will try to dodge your projectiles" or "Нпс будут пытаться увернуться от ваших снарядов", variable = var{id = "pvp1", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable parrying for enemies" or "Включить парирование для врагов", variable = var{id = "par", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable improved creature abilities" or "Улучшенные способности существ", variable = var{id = "full", table = cf}}
p0:createSlider{label = cf.en and "The minimum percentage of creature power (80 by default)" or "Минимальный процент силы существ (80 по умолчанию)", min = 50, max = 200, step = 1, jump = 5, variable = var{id = "min", table = cf}}
p0:createSlider{label = cf.en and "The maximum percentage of creature power (120 by default)" or "Максимальный процент силы существ (120 по умолчанию)", min = 50, max = 200, step = 1, jump = 5, variable = var{id = "max", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable advanced leveling system" or "Продвинутая система левелинга", variable = var{id = "levmod", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable advanced skill training system" or "Продвинутая система набора опыта в навыках", variable = var{id = "trmod", table = cf}, restartRequired = true}
p0:createSlider{label = cf.en and "Fatigue multiplier when training skills (5 by default)" or "Множитель усталости при повышении навыков (3 по умолчанию)",
min = 0, max = 10, step = 1, jump = 1, variable = var{id = "expfat", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable skill points system for teachers" or "Включить систему скиллпоинтов для обучения у тренеров", variable = var{id = "skillp", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable realistic run speed" or "Реалистичная скорость бега", variable = var{id = "Spd", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Enable realistic hit chance" or "Реалистичный шанс на попадание", variable = var{id = "hit", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Enable realistic injury and fatigue in combat" or "Реалистичная травматичность и утомляемость в бою", variable = var{id = "traum", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable advanced alchemy" or "Продвинутая алхимия", variable = var{id = "alc", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Enable advanced economics" or "Продвинутая экономика", variable = var{id = "barter", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Enable advanced stealth" or "Продвинутый стелс", variable = var{id = "stels", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Enable constant enchantments limit" or "Ограничение объема постоянных зачарований", variable = var{id = "enchlim", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable minimum duration for homemade spells" or "Ограничение длительности самодельных спеллов", variable = var{id = "durlim", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Enable improved targeting magic for enemies" or "Улучшенное наведение магии для врагов", variable = var{id = "spellhit", table = cf}}
p0:createYesNoButton{label = cf.en and "Arrows get stuck on hit" or "Стрелы будут застревать при попадании", variable = var{id = "Proj", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Bug-fix of idle shooting - enable only if shooters are bugged" or "Баг-фикс стрельбы вхолостую - включать только если забагуются стрелки", variable = var{id = "ammofix", table = cf}}
p0:createYesNoButton{label = cf.en and "Anti-exploit for homemade spells" or "Анти-эксплойт с самодельными спеллами", variable = var{id = "aspell", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Disable saves during combat" or "Запрет сохранений во время боя", variable = var{id = "nosave", table = cf}}
p0:createSlider{label = cf.en and "How many seconds does it take for enemies to switch to throwing stones" or "Сколько секунд надо затупившим врагам на то чтобы начать кидать камни в героя",
min = 0, max = 10, step = 1, jump = 1, variable = var{id = "AIsec", table = cf}}

p1:createYesNoButton{label = "English language", variable = var{id = "en", table = cf}, restartRequired = true}
p1:createYesNoButton{label = cf.en and "Show new mechanics messages" or "Показывать сообщения о новых механиках", variable = var{id = "m", table = cf}}
p1:createYesNoButton{label = cf.en and "Show magic power messages" or "Показывать сообщения о силе магии", variable = var{id = "m1", table = cf}}
p1:createYesNoButton{label = cf.en and "Show magic cast messages" or "Показывать сообщения о касте магии", variable = var{id = "m10", table = cf}}
p1:createYesNoButton{label = cf.en and "Show magic affect messages" or "Показывать сообщения о вторичных магических эффектах", variable = var{id = "m2", table = cf}}
p1:createYesNoButton{label = cf.en and "Show physical damage messages" or "Показывать сообщения о физическом уроне", variable = var{id = "m30", table = cf}}
p1:createYesNoButton{label = cf.en and "Show other combat messages" or "Показывать другие боевые сообщения", variable = var{id = "m3", table = cf}}
p1:createYesNoButton{label = cf.en and "Show AI messages" or "Показывать сообщения для модуля ИИ", variable = var{id = "m4", table = cf}}
p1:createYesNoButton{label = cf.en and "Show item messages" or "Показывать сообщений о предметах", variable = var{id = "m8", table = cf}}
p1:createYesNoButton{label = cf.en and "Show alchemy messages" or "Показывать алхимические сообщения", variable = var{id = "m5", table = cf}}
p1:createYesNoButton{label = cf.en and "Show economic messages" or "Показывать экономические сообщения", variable = var{id = "m6", table = cf}}
p1:createYesNoButton{label = cf.en and "Show training messages" or "Показывать сообщения об опыте", variable = var{id = "m7", table = cf}}
p1:createYesNoButton{label = cf.en and "Show randomizer messages" or "Показывать сообщения рандомизатора", variable = var{id = "m9", table = cf}}
p1:createYesNoButton{label = cf.en and "Show stealth messages" or "Показывать сообщения о скрытности", variable = var{id = "m11", table = cf}}
p1:createSlider{label = cf.en and "Set number of icons in 1 line in Improved magic menu" or "Сколько иконок будет в одной строке Улучшенного меню магии", min = 5, max = 50, step = 1, jump = 5, variable = var{id = "lin", table = cf}}
p1:createSlider{label = cf.en and "Font color in Improved magic menu (0 = no text)" or "Цвет шрифта в улучшенном меню магии (0 = без текста)", min = 0, max = 8, step = 1, jump = 1, variable = var{id = "UIcol", table = cf}}
p1:createYesNoButton{label = cf.en and "Improved spell menu (requires save load)" or "Улучшенное меню заклинаний", variable = var{id = "UIsp", table = cf}}
p1:createYesNoButton{label = cf.en and "Improved enchanted items menu (requires save load)" or "Улучшенное меню зачарованных предметов", variable = var{id = "UIen", table = cf}}
p1:createYesNoButton{label = cf.en and "Improved spell creation menu" or "Улучшеное меню создания заклинаний", variable = var{id = "spmak", table = cf}}
p1:createYesNoButton{label = cf.en and "Show a strip of training fatigue bar (green - movement, blue - magic, lilac - craft, yellow - social)" or
"Показывать полоску тренировочной усталости (зеленый - движения, голубой - магия, сиреневый - крафт, желтый - социалка)", variable = var{id = "fatbar", table = cf}}
p1:createYesNoButton{label = cf.en and "Replace potion icons with better ones" or "Заменить иконки зелий на информативные", variable = var{id = "lab", table = cf}, restartRequired = true}
p1:createYesNoButton{label = cf.en and "Replace scroll icons with beautiful ones" or "Заменить иконки свитков на красивые", variable = var{id = "scroll", table = cf}, restartRequired = true}

p3:createSlider{label = cf.en and "Magnitude limiter for your dashes. Use a dash with middle mouse button pressed to remove this limitation" or
"Ограничитель магнитуды для ваших дэшей. Используйте дэш с зажатой средней кнопкой мыши чтобы снять это ограничение", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "dash", table = cf}}
p3:createSlider{label = cf.en and "Magnitude limiter for your charge attacks" or "Ограничитель магнитуды для ваших чардж-атак", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "charglim", table = cf}}
p3:createSlider{label = cf.en and "Magnitude limiter for your kinetic kicks" or "Ограничитель магнитуды для ваших кинетических пинков", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "moment", table = cf}}
p3:createSlider{label = cf.en and "Magnitude limiter for your kinetic throws" or "Ограничитель магнитуды для ваших кинетических бросков", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "metlim", table = cf}}
p3:createYesNoButton{label = cf.en and "Automatically kick after dash (if dash is done with middle mouse button pressed)" or "Автоматически делать пинок после дэша (если дэш сделан с зажатой средней кнопкой мыши)", variable = var{id = "autokik", table = cf}}
p3:createYesNoButton{label = cf.en and "Automatically charge attack if you are looking at an enemy" or "Автоматически делать чардж-атаку если вы смотрите на врага", variable = var{id = "autocharg", table = cf}}
p3:createSlider{label = cf.en and "Percentage limiter for your manashield" or "Ограничитель процента эффективности для вашего манащита", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "mshmax", table = cf}}
p3:createSlider{label = cf.en and "Percentage limiter for your reflects" or "Ограничитель процента эффективности для ваших отражений", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "rfmax", table = cf}}
p3:createYesNoButton{label = cf.en and "Charged weapon: smart mode for range weapons" or "Эффект заряженного оружия: включить умный режим для дальнобойного оружия", variable = var{id = "smartcw", table = cf}}
p3:createYesNoButton{label = cf.en and "Agressive mode for your kicks, auras, totems" or "Агрессивный режим для ваших пинков, аур, тотемов", variable = var{id = "agr", table = cf}}
p3:createYesNoButton{label = cf.en and "Allow projectile control for magic rays" or "Разрешить контроль снарядов для магических лучей", variable = var{id = "raycon", table = cf}}
p3:createYesNoButton{label = cf.en and "Default ray mode (if not then spray)" or "Режим луча по умолчанию (если нет то будет спрей)", variable = var{id = "ray", table = cf}}
p3:createYesNoButton{label = cf.en and "Automatic replenishment of bound ammo" or "Автоматически пополнять призванные снаряды", variable = var{id = "autoammo", table = cf}}
p3:createYesNoButton{label = cf.en and "Allow telekinetic return of thrown weapons" or "Разрешить телекинетический возврат кинутого оружия", variable = var{id = "metret", table = cf}}
p3:createYesNoButton{label = cf.en and "Always shoot a crossbow in alternate mode" or "Всегда стрелять из арбалета в альтернативном режиме", variable = var{id = "autoarb", table = cf}}
p3:createSlider{label = cf.en and "Set color saturation of magic lights (0 = maximum colorfulness, 255 = full white)" or
"Насыщенность цвета для магических фонарей (0 = максимум цвета, 255 = чисто белый свет)", min = 0, max = 255, step = 1, jump = 5, variable = var{id = "col", table = cf}}
p3:createYesNoButton{label = cf.en and "Play sound of magic concentration (hold Left Mouse Button for concentrate power)" or
"Звук магической концентрации (удерживайте левую кнопку мыши чтобы сконцентрировать магию и зарядить спелл)", variable = var{id = "mcs", table = cf}}
p3:createSlider{label = cf.en and "Minimum crit power to play crit strike sound" or "Минимальная мощь крита для проигрывания звука крита", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "crit", table = cf}}
p3:createYesNoButton{label = cf.en and "Maniac mode! You will try to undress knocked out enemies" or "Режим маньяка! Вы будете пытаться раздеть нокаутированных врагов", variable = var{id = "maniac", table = cf}}
p3:createYesNoButton{label = cf.en and "Automatic shield equipment" or "Автоматическая экипировка щитов", variable = var{id = "autoshield", table = cf}}
p3:createYesNoButton{label = cf.en and "Smart potion/poison discrimination mode. If the potion contains at least 1 negative effect, then this is poison" or
"Умный режим различения зелий и ядов. Работает со включенным режимом яда. Если зелье содержит хотябы 1 негативный эффект, то это яд, иначе зелье и вы его выпьете", variable = var{id = "smartpoi", table = cf}}
p3:createYesNoButton{label = cf.en and "Allow to upgrade only equipped weapons and armor" or "Разрешить улучшать только экипированные оружие и броню", variable = var{id = "upgm", table = cf}}

p2:createKeyBinder{variable = var{id = "pkey", table = cf}, label = cf.en and "Perks Menu" or "Вызвать меню перков"}
p2:createKeyBinder{variable = var{id = "tpkey", table = cf}, label = cf.en and "Dash / active dodge key" or "Кнопка для дэшей и активных уклонений"}
p2:createKeyBinder{variable = var{id = "kikkey", table = cf}, label = cf.en and "Kicking and climbing key. It is recommended to assign the same button as for the jump" or
"Кнопка для удара ногой и карабканья. Рекомендуется назначить ту же кнопку что и для прыжка"}
p2:createKeyBinder{variable = var{id = "magkey", table = cf}, label = cf.en and "Key for Extra cast. Press slot key with SHIFT to assign the current spell to this Extra cast slot" or
"Кнопка Экстра-каста. Нажмите одну из кнопок выбора слота экстра-каста вместе с SHIFT чтобы назначить текущий спелл для этого слота"}
p2:createKeyBinder{variable = var{id = "ekey", table = cf}, label = cf.en and
[[Hold this key when: Equipping weapon - to remember it for left hand; Equipping poison - to use it for throwing; Activating the apparatus - to display the alchemy menu without adding it to your inventory]] or
[[Удерживайте эту кнопку: При экипировке оружия - чтобы запомнить его для левой руки; При экипировке яда - чтобы кидать бутылки; При активации аппарата - чтобы алхимическое меню появилось без взятия этого апаарата]]}
p2:createKeyBinder{variable = var{id = "dwmkey", table = cf}, label = cf.en and "Switch to dual-weapon mode. Press this button while holding ALT to forget the left weapon" or
"Переключение режима двух оружий. Нажмите эту кнопку, удерживая ALT, чтобы забыть оружие для левой руки"}
p2:createKeyBinder{variable = var{id = "gripkey", table = cf}, label = cf.en and "Press this key when equip weapon to change it grip" or "Нажмите эту кнопку при экипировке оружия чтобы сменить его хват"}
p2:createKeyBinder{variable = var{id = "cpkey", table = cf}, label = cf.en and "Projectile control mode key. Press with: Move buttons = switch modes; ALT = turn Smart mode; CTRL = turn Mine mode; LMB = release projectiles" or
"Кнопка для контроля снарядов. Нажмите ее вместе с: кнопками движения = переключить режимы; ALT = переключить умный режим; CTRL = переключить режим мин; ЛКМ = отпустить снаряды"}
p2:createKeyBinder{variable = var{id = "telkey", table = cf}, label = cf.en and "Telekinetic Throw key. Press again to return thrown weapon. Hold while activating or dropping weapons." or
"Кнопка для телекинетического броска. Нажмите повторно чтобы вернуть брошенное оружие. Удерживайте ее во время активации или выбрасывания предмета."}
p2:createKeyBinder{variable = var{id = "cwkey", table = cf}, label = cf.en and "Charge weapon key. Press with SHIFT to turn mode. Press with CTRL to switch ranged/touch mode. Press with ALT to disable enchantments on strike" or
"Конпка для эффекта заряженного оружия. Нажмите ее вместе с SHIFT для переключения режима. Нажмите вместе с CTRL для пререключения дальности. Нажмите вместе с ALT для запрета применять зачарования при ударе"}
p2:createKeyBinder{variable = var{id = "reflkey", table = cf}, label = cf.en and "Turn reflect/manashield mode for new reflect spells. Press with: CTRL - switch auras mode; SHIFT - switch magic explode mode" or
"Кнопка для переключения режима отражения и манащита для эффектов нового отражения. Нажмите ее вместе с: CTRL - переключить режим аур; SHIFT - переключить режим магических взрывов"}
p2:createKeyBinder{variable = var{id = "totkey", table = cf}, label = cf.en and "Press to switch totem mode. Press with SHIFT to explode all runes. Press with CTRL to explode all totems." or
"Нажмите для переключения режима тотемов. Нажмите вместе с SHIFT чтобы взорвать все руны. Нажмите вместе с CTRL чтобы взорвать все тотемы."}
p2:createKeyBinder{variable = var{id = "detkey", table = cf}, label = cf.en and "Use magic vision for detection" or "Кнопка для применения магического зрения для магии обнаружения"}
p2:createKeyBinder{variable = var{id = "markkey", table = cf}, label = cf.en and "Key for select mark for recall" or "Кнопка для выбора текущей Пометки для магии Возврата"}
p2:createKeyBinder{variable = var{id = "bwkey", table = cf}, label = cf.en and "Choosing a bound weapon. Press with CTRL for replenishment of bound ammo" or
"Выбор призванного оружия. Нажмите вместе с CTRL для пополнения призванных снарядов"}
p2:createKeyBinder{variable = var{id = "poisonkey", table = cf}, label = cf.en and "Assign a button to toggle poison mode. If poison mode enabled, you will create poisons instead of potions, and also apply them to your weapons instead of drinking" or
"Кнопка для режима яда. Когда режим яда включен, вы варите яды вместо зелий а также отравляете свое оружие ядом вместо выпивания"}
p2:createKeyBinder{variable = var{id = "parkey", table = cf}, label = cf.en and "Assign a button to toggle parry mode. In this mode, your attacks will try to repel the enemy's weapons if possible" or
"Кнопка для режима парирования. В этом режиме ваши атаки будут пытаться отбить оружие врага если это возможно"}
p2:createKeyBinder{variable = var{id = "q0", table = cf}, label = cf.en and [[Universal Extra cast slot. If selected, the current spell will always be prepared for a Extra cast.
Press this button with SHIFT to add/remove current spell to Favorite Spells list. Press this button with ALT to clear this list.
Spells from Favorite list are placed at the top of the Improved Magic Menu. Changes to the list take effect after loading the save.]] or
[[Кнопка выбора универсального слота для экстра-каста. Если универсальный слот выбран, то для экстра-каста всегда будет использован только ваш текущий спелл.
Нажмите эту кнопку вместе с SHIFT чтобы добавить/удалить текущий спелл в список Избранных Спеллов. Нажмите эту кнопку вместе с ALT чтобы очистить этот список.
Спеллы из Избранного списка помещаются наверх в Улучшенном меню магии. Изменения списка вступают в силу после загрузки сейва.]]}
p2:createCategory(cf.en and "By default these are buttons on the num-bar:" or "По умолчанию это кнопки на num-панели:")
p2:createKeyBinder{variable = var{id = "q1", table = cf}, label = cf.en and "Extra cast slot #1" or "Слот экстра-каста #1"}
p2:createKeyBinder{variable = var{id = "q2", table = cf}, label = cf.en and "Extra cast slot #2" or "Слот экстра-каста #2"}
p2:createKeyBinder{variable = var{id = "q3", table = cf}, label = cf.en and "Extra cast slot #3" or "Слот экстра-каста #3"}
p2:createKeyBinder{variable = var{id = "q4", table = cf}, label = cf.en and "Extra cast slot #4" or "Слот экстра-каста #4"}
p2:createKeyBinder{variable = var{id = "q5", table = cf}, label = cf.en and "Extra cast slot #5" or "Слот экстра-каста #5"}
p2:createKeyBinder{variable = var{id = "q6", table = cf}, label = cf.en and "Extra cast slot #6" or "Слот экстра-каста #6"}
p2:createKeyBinder{variable = var{id = "q7", table = cf}, label = cf.en and "Extra cast slot #7" or "Слот экстра-каста #7"}
p2:createKeyBinder{variable = var{id = "q8", table = cf}, label = cf.en and "Extra cast slot #8" or "Слот экстра-каста #8"}
p2:createKeyBinder{variable = var{id = "q9", table = cf}, label = cf.en and "Extra cast slot #9" or "Слот экстра-каста #9"}

pm:createCategory(cf.en and "Mouse buttons: 1 - left, 2 - right, 3 - middle, 4-7 - side" or "Кнопки мыши: 1 - левая, 2 - правая, 3 - средняя, 4-7 - боковые")
pm:createSlider{label = cf.en and "Mouse button for active dodge (hold while using dash to use active dodge instead of dash)" or 
"Кнопка мыши для активного уклонения (зажмите при использовании дэша, чтобы применить активное уклонение вместо дэша)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbdod", table = cf}}
pm:createSlider{label = cf.en and "Mouse button for kicking and climbing" or "Кнопка мыши для удара ногой и карабканья", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbkik", table = cf}}
pm:createSlider{label = cf.en and "Mouse button for charge attack (hold while attack)" or "Кнопка мыши для чардж-атаки (зажмите при атаке)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbcharg", table = cf}}
pm:createSlider{label = cf.en and "Mouse button for throwing weapons (hold while attacking)" or "Кнопка мыши для кидания оружия (зажмите при атаке)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbmet", table = cf}}
pm:createSlider{label = cf.en and "Mouse button for alternative shots (press while holding LMB for bows and throwing weapons; hold and press LMB for crossbows)" or
"Кнопка мыши для альтернативных выстрелов (нажмите при зажатой ЛКМ для луков и метательного оружия; удерживайте и нажимайте ЛКМ для арбалетов)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbshot", table = cf}}
pm:createSlider{label = cf.en and "Mouse button to hold breath when archery (select 1 for automatic hold)" or
"Кнопка мыши для задержки дыхания при стрельбе из лука (выберите 1 для автоматической задержки)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbarc", table = cf}}
pm:createSlider{label = cf.en and "Mouse button for weighting magic projectiles (hold while casting)" or "Кнопка мыши для утяжеления магических снарядов (зажмите при касте)",
min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbhev", table = cf}}
pm:createSlider{label = cf.en and "Mouse button for alternate ray mode (hold while casting)" or "Кнопка мыши для альтернативного режима луча (зажмите при касте)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbray", table = cf}}
pm:createSlider{label = cf.en and "Mouse button to extend the life of summoned creatures (hold while charging magic and looking at the creature)" or
"Кнопка мыши для продления жизни призванных существ (удерживайте, заряжая магию и смотря на существо)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbsum", table = cf}}
pm:createSlider{label = cf.en and "Mouse button to return controlled projectiles" or "Кнопка мыши для возврата контролируемых снарядов", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbret", table = cf}}
end		event.register("modConfigReady", registerModConfig)