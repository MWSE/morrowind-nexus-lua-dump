local cfg = mwse.loadConfig("4NM_MAGIC_8!") or {msg = false, msg1 = false, msg2 = false, acscast = true, agr = true, smartcw = true, autoammo = true, Arch = false, enchlim = true, durlim = true, mcs = true, scroll = true, testmod = false, Lvol = 15, col = 0,
magkey = {keyCode = 157}, tpkey = {keyCode = 54}, cpkey = {keyCode = 44}, ammokey = {keyCode = 45}, reflkey = {keyCode = 46}, detkey = {keyCode = 47}, markkey = {keyCode = 48}, cwkey = {keyCode = 207}, telkey = {keyCode = 211},
q1 = {keyCode = 79}, q2 = {keyCode = 80}, q3 = {keyCode = 81}, q4 = {keyCode = 75}, q5 = {keyCode = 76}, q6 = {keyCode = 77}, q7 = {keyCode = 71}, q8 = {keyCode = 72}, q9 = {keyCode = 73}, q0 = {keyCode = 156}}
local p, mp, D, DM, msg, msg1, msg2, MB, Acells, mc, n, md, M, K, P, W, ENPC, wc, ic, dt		local MT = {__index = function(t, k) t[k] = {} return t[k] end}		local AF = setmetatable({}, MT)
local SS = setmetatable({}, MT)		local BS = setmetatable({}, MT)		local B = {}	local S = {}	local SI = {}	local Matr = tes3matrix33.new()		local EW = {}

local SID = {["4s_DC"] = "discharge", ["4s_CWT"] = "CWT", ["4s_rune1"] = "rune", ["4s_rune2"] = "rune", ["4s_rune3"] = "rune", ["4s_rune4"] = "rune", ["4s_rune5"] = "rune", ["4s_rune0"] = "rune",
["4s_totem1"] = "totem", ["4s_totem2"] = "totem", ["4s_totem3"] = "totem", ["4s_totem4"] = "totem", ["4s_totem5"] = "totem", ["4s_totemexp"] = "totem"}
local School = {[0] = 11, [1] = 13, [2] = 10, [3] = 12, [4] = 14, [5] = 15} -- 11 Изменение, 13 Колдовство, 10 Разрушение, 12 Иллюзии, 14 Мистицизм, 15 Восстановление
local ResAtr = {[3] = 11, [4] = 11, [5] = 11, [9] = 15} -- 3 огонь, 4 мороз, 5 молния, 9 яд. Для всего отсального Мистицизм (14)
local DurKF = {[14] = 5, [15] = 5, [16] = 5, [23] = 5, [27] = 5, [22] = 5, [24] = 5, [25] = 5, [26] = 5, [37] = 10, [38] = 10, [74] = 5, [75] = 5, [76] = 5, [77] = 5, [78] = 5, [86] = 5, [87] = 5, [88] = 5,
[516] = 5, [517] = 5, [518] = 5, [519] = 5, [520] = 5}
local CME = {[4] = "frost", [6] = "fire", [5] = "shock", [73] = "shock", [72] = "poison", [57] = "vital"}
local MEF = {[511] = "charge", [512] = "charge", [513] = "charge", [514] = "charge", [515] = "charge", [516] = "aura", [517] = "aura", [518] = "aura", [519] = "aura", [520] = "aura",
[521] = "aoe", [522] = "aoe", [523] = "aoe", [524] = "aoe", [525] = "aoe", [526] = "rune", [527] = "rune", [528] = "rune", [529] = "rune", [530] = "rune",
[531] = "prok", [532] = "prok", [533] = "prok", [534] = "prok", [535] = "prok", [536] = "shotgun", [537] = "shotgun", [538] = "shotgun", [539] = "shotgun", [540] = "shotgun",
[541] = "discharge", [542] = "discharge", [543] = "discharge", [544] = "discharge", [545] = "discharge", [546] = "ray", [547] = "ray", [548] = "ray", [549] = "ray", [550] = "ray",
[551] = "totem", [552] = "totem", [553] = "totem", [554] = "totem", [555] = "totem", [556] = "empower", [557] = "empower", [558] = "empower", [559] = "empower", [560] = "empower",
[561] = "reflect", [562] = "reflect", [563] = "reflect", [564] = "reflect", [565] = "reflect"}
local MID = {[0] = 23, [1] = 14, [2] = 16, [3] = 15, [4] = 27, [5] = 23}		local AoEmod = {[0] = "4nm_aoe_vitality", [1] = "4nm_aoe_fire", [2] = "4nm_aoe_frost", [3] = "4nm_aoe_shock", [4] = "4nm_aoe_poison"}
local LID = {[0] = {255,0,128}, [1] = {255,128,0}, [2] = {0,255,255}, [3] = {128,0,255}, [4] = {0,128,64}}		local EMP = {[14] = 556, [16] = 557, [15] = 558, [27] = 559, [23] = 560}
local BAM = {[9] = "4nm_boundarrow", [10] = "4nm_boundbolt", ["met"] = "4nm_boundstar", ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true}
local T = {Fire = timer, Frost = timer, Shock = timer, Poison = timer, Vital = timer, Heal = timer, Prok = timer, DA = timer, DC = timer, TS = timer, DET = timer}

local function BREG(...) for i, v in ipairs{...} do B[v] = tes3.getObject("4b_"..v)		if not B[v] then B[v] = tes3alchemy.create{id = "4b_"..v, name = "4b_"..v, icon = "s\\b_tx_s_sun_dmg.dds"} 	B[v].effects[1].id = -1 end end end
local function SREG(...) for i, v in ipairs{...} do S[v] = tes3.getObject("4s_"..v)		if not S[v] then S[v] = tes3spell.create("4s_"..v, "4s_"..v) 	S[v].magickaCost = 0	S[v].effects[1].id = 0 end end end
--local function BN(v, range, eff, min, max, rad, dur, icon)		B[v] = tes3.getObject("4b_"..v) or tes3alchemy.create{id = "4b_"..v, name = "4b_"..v, icon = icon or "s\\b_tx_s_sun_dmg.dds"}
--B[v].effects[1].rangeType = range		B[v].effects[1].id = eff		B[v].effects[1].min = min		B[v].effects[1].max = max		B[v].effects[1].radius = rad		B[v].effects[1].duration = dur end
local function SN(v, range, eff, min, max, rad, dur, cost, name)	S[v] = tes3.getObject("4s_"..v) or tes3spell.create("4s_"..v, (name or "4s_"..v)) 	S[v].magickaCost = (cost or 0)
S[v].effects[1].rangeType = range		S[v].effects[1].id = eff		S[v].effects[1].min = min		S[v].effects[1].max = max		S[v].effects[1].radius = rad		S[v].effects[1].duration = dur end
local function Cpower(m, s1, s2) return 100 + m.willpower.current/5 + m:getSkillValue(s1)/5 + m:getSkillValue(s2)/10 + (m.spellReadied and m.magicka.current/(25 + m.magicka.current/40) or 0) - 50*(1 - math.min(m.fatigue.normalized,1)) end
local function Armor(m, k) local st = m.actorType ~= 0 and tes3.getEquippedItem{actor = m.reference, objectType = tes3.objectType.armor, slot = math.random(3) == 1 and 1 or math.random(0,8)}	
return (m.shield + (st and st.object:calculateArmorRating(m) or 0)) * (k or 0.3) end
local function mag(i,r) return tes3.getEffectMagnitude{reference = r or p, effect = i} end
local function s(i,m) return (m or mp):getSkillValue(i) end
local function hitp() local pos = tes3.getPlayerEyePosition()	local vec = tes3.getPlayerEyeVector()	local hit = tes3.rayTest{position = pos, direction = vec}
return hit and hit.intersection:distance(pos) < 4800 and hit.intersection - vec*40 or pos + vec*4800 end
local function Kcost(x,k,m,s1,s2) return x - x/k * math.min((m:getSkillValue(s1) + m:getSkillValue(s2)),200)/200 end

local function Curve(x, k1, k2) return (k1 * x)/(1 + x/k2) end
local function durbonus(mag, dur, koef)		if dur < 1 then return mag else return mag * (1 + koef/100 * dur^0.5) end end
local function Rcol(x) local c = {{math.random(x,255),x,255}, {math.random(x,255),255,x}, {x,math.random(x,255),255}, {255,math.random(x,255),x}, {x,255,math.random(x,255)}, {255,x,math.random(x,255)}}	return c[math.random(6)] end

local TSK = 1	local function SIMTS() wc.deltaTime = wc.deltaTime * TSK end
local function CMSFrost(e) if AF[e.reference].frost and AF[e.reference].frkf then e.speed = e.speed * AF[e.reference].frkf end end
local function ConstEnLim()	local csl = {300,300,500,300,1000,300,300,300,1000,1000}	local asl = {1000,500,100,100,200,300,500,500,500,400,400}	D.ENconst = 0
	for _, s in pairs(p.object.equipment) do if s.object.enchantment and s.object.enchantment.castType == 3 then
		if s.object.objectType == tes3.objectType.clothing then D.ENconst = D.ENconst + math.max(csl[s.object.slot+1] or 0, s.object.enchantCapacity)
		elseif s.object.objectType == tes3.objectType.armor then D.ENconst = D.ENconst + math.max(asl[s.object.slot+1] or 0, s.object.enchantCapacity) end
	end end		ENPC.max = (mp.willpower.base*10 + mp.enchant.base*10) * (1 - D.ENconst/(5000 + mp.enchant.base*30)/2)
end

local CWM, CWR
local function CWMag(r, k)	CWM = {tes3.getEffectMagnitude{reference = r, effect = 511}, tes3.getEffectMagnitude{reference = r, effect = 512}, tes3.getEffectMagnitude{reference = r, effect = 513},
tes3.getEffectMagnitude{reference = r, effect = 514}, tes3.getEffectMagnitude{reference = r, effect = 515}}		return (CWM[1]*0.3 + CWM[2]*0.3 + CWM[3]*0.4 + CWM[4]*0.5 + CWM[5]*0.4) * k end

local L, LTS, LTiter, LTpos	local LTRef = {}
local function LTnew(it, spos) if LTS then L.radius = tes3.getEffectMagnitude{reference = p, effect = 504} * Cpower(mp, 11, 11) end
	LTS = tes3.createReference{object = "4nm_light", scale = math.min(1+L.radius/1000, 9), position = spos, cell = p.cell}		LTS.modified = false
	LTRef[LTS] = timer.start{duration = 0.05, iterations = it, callback = function()
		if LTRef[LTS].iterations == 1 then LTS:disable()	LTS.modified = false	LTRef[LTS]:cancel()		LTRef[LTS] = nil	LTS = nil
		elseif LTS.cell ~= p.cell then LTiter = LTRef[LTS].iterations	LTS:disable()	LTS.modified = false	LTRef[LTS]:cancel()		LTRef[LTS] = nil	LTnew(LTiter, p.position)
		elseif LTRef[LTS].iterations%100 == 0 then	LTiter = LTRef[LTS].iterations	LTpos = LTS.position	LTS:disable()	LTS.modified = false	LTRef[LTS]:cancel()		LTRef[LTS] = nil	LTnew(LTiter-1, LTpos)
		else local pos = p.position:copy()	pos.z = pos.z + 200 + L.radius/50		LTS.position = LTS.position:interpolate(pos, 5 + LTS.position:distance(pos)/20) end
	end}
end

local function LightCollision(e) if e.collision and e.sourceInstance.caster == p then -- Фонарь (504)
local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	local L	= tes3.getObject("4nm_light")	local pos = e.collision.point:copy()	pos.z = pos.z + 5	local col = Rcol(cfg.col)
L.color[1] = col[1]		L.color[2] = col[2]		L.color[3] = col[3]		L.radius = math.random(ef.min, ef.max) * Cpower(mp, 11, 11)
local LTR = tes3.createReference{object = "4nm_light", scale = math.min(1+L.radius/1000, 9), position = pos, cell = p.cell}	LTR.modified = false	LTRef[LTR] = true
timer.start{duration = ef.duration, callback = function() LTR:disable()		LTR.modified = false	LTRef[LTR] = nil end}
if msg then tes3.messageBox("Light active! Radius = %d  Time = %d	Total = %d", L.radius, ef.duration, table.size(LTRef)) end
end end

local DC = {}	DC.f = function() DC.ref = {}	for r in tes3.iterate(p.cell.actors) do if r.mobile and not r.mobile.isDead then table.insert(DC.ref, r) end end
if #DC.ref < 5 and not p.cell.isInterior then for c, _ in pairs(Acells) do for r in tes3.iterate(c.actors) do if r.mobile and not r.mobile.isDead then table.insert(DC.ref, r) end end end end return #DC.ref end

local DA, PRM, QS, si, ENcost
local function onSpellResist(e)	local c, resist, Tarmor, Tbonus, Cbonus, Cstam, Cfocus, CritC, CritD, Emp		local sn = e.sourceInstance.serialNumber
local t = e.target	local m = e.target.mobile	local ef = e.effect	local eid = ef.id	local Dbonus = DurKF[eid] and ef.duration > 4 and DurKF[eid] * (ef.duration - 4)^0.5 or 0		local MKF = 1
if e.caster then if e.source.objectType == tes3.objectType.alchemy then if e.source.weight == 0 then if ef.rangeType == 0 then if e.resistAttribute == 28 then c = e.caster.mobile else c = mp end else c = e.caster.mobile end end else c = e.caster.mobile end
elseif SID[e.source.id] then if t == p then e.resistedPercent = 100 return elseif m.inCombat == false then mwscript.startCombat{reference = t, target = p} end c = mp end
if c then Cstam = 50*(1 - math.min(c.fatigue.normalized,1))		Emp = EMP[eid] and tes3.getEffectMagnitude{reference = c.reference, effect = EMP[eid]} or 0
	Cbonus = c.willpower.current/5 + (e.source.objectType == tes3.objectType.enchantment and (c:getSkillValue(9)/5 + c:getSkillValue(School[ef.object.school])/10) or (c:getSkillValue(School[ef.object.school])/5 + c:getSkillValue(ResAtr[e.resistAttribute] or 14)/10))
	Cfocus = (c.spellReadied and c.magicka.current/(25 + c.magicka.current/40) or 0) + (SI[sn] and SI[sn] * c.willpower.current/5 or 0)
	CritC = (c.luck.current + c.agility.current)/20 + c.attackBonus/5 + (c == mp and 0 or c.object.level + 20) + Cfocus/2 -
	(e.resistAttribute == 28 and 10 or (math.min(m.fatigue.normalized,1)*10 + (m.spellReadied and 10 or 0) + (m.willpower.current + m.endurance.current + m.luck.current)/20))
	CritD = CritC - math.random(100)	if CritD < 0 then CritD = 0 else CritD = CritD + 30 end
else	Cbonus = 0	Cstam = 0	Cfocus = 0	CritC = 0	CritD = 0 	Emp = 0 end -- Обычные зелья, обычные яды, алтари, ловушки и прочие кастующие активаторы
if e.caster == p then if e.source.objectType == tes3.objectType.spell and e.source.castType == 0 then -- Отменяем стаки с быстрой бутылочной магией
	if BS[t.id][e.source.id] then si = tes3.getMagicSourceInstanceBySerial{serialNumber = BS[t.id][e.source.id]}	if si then si.state = 6 end		BS[t.id][e.source.id] = nil end		SS[t.id][e.source.id] = sn
elseif e.source.name == "4b_Q" then if SS[t.id][QS.id] and SS[t.id][QS.id] ~= sn then si = tes3.getMagicSourceInstanceBySerial{serialNumber = SS[t.id][QS.id]}	if si then si.state = 6 end end
	SS[t.id][QS.id] = sn	BS[t.id][QS.id] = sn
elseif ((e.source.objectType == tes3.objectType.enchantment and (e.source.castType == 1 or e.source.castType == 2) and ENcost > 0) or e.source.icon == "s\\b_chargeFrost.tga") and ENPC.normalized < 0.5 then
	MKF = math.max(0.05, 2*ENPC.normalized, 1-ENcost/(ENPC.max/100))
end end

if e.resistAttribute == 28 then -- Магия с позитивными эффектами
	if e.source.objectType == tes3.objectType.spell then -- Не влияет  на пост.эффекты, powers(5), всегда успешные
		if e.source.castType == 0 and e.source.flags ~= 4 then e.resistedPercent = Cstam - Cbonus - Cfocus - CritD - Dbonus
		if msg1 then tes3.messageBox("%s  %.1f%% spell power (+ %.1f bonus + %.1f focus + %.1f crit (%.1f%%) + %.1f dur - %.1f stam)", e.source.name, (100 - e.resistedPercent), Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam) end end
	elseif e.source.objectType == tes3.objectType.alchemy then
		if e.source.weight == 0 then
			if e.source.name == "4b_Q" and QS.flags ~= 4 then e.resistedPercent = Cstam - Cbonus - Cfocus - CritD - Dbonus
				if msg1 then tes3.messageBox("%s  %.1f%% Q spell power (+ %.1f bonus + %.1f focus + %.1f crit (%.1f%%) + %.1f dur - %.1f stam)", QS.name, (100 - e.resistedPercent), Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam) end
			elseif e.source.icon == "" then e.resistedPercent = 75	if msg1 then tes3.messageBox("%s  ingred power = %.1f for %d seconds", e.source.name, ef.max/4, ef.duration) end end
		else e.resistedPercent = 0 - e.caster.mobile.willpower.current/10 - e.caster.mobile:getSkillValue(16)/5		if msg1 then tes3.messageBox("%s  %.1f%% alchemy power", e.source.name, (100 - e.resistedPercent)) end end
	elseif e.source.objectType == tes3.objectType.enchantment then -- Сила зачарований castType 0=castOnce, 1=onStrike, 2=onUse, 3=constant
		if e.source.castType ~= 3 then	e.resistedPercent = Cstam - Cbonus - Cfocus - CritD - Dbonus		if MKF < 1 then e.resistedPercent = 100 - (100 - e.resistedPercent) * MKF end
			if msg1 then tes3.messageBox("%s  %.1f%% enchant power (+ %.1f bonus + %.1f focus + %.1f crit (%.1f%%) + %.1f dur - %.1f stam) x%.2f mult", e.source.id, (100 - e.resistedPercent), Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam, MKF) end
		elseif t == p then ConstEnLim()	if cfg.enchlim then 
			if D.ENconst > (5000 + mp.enchant.base*30) then e.resistedPercent = 100	tes3.messageBox("Enchant limit exceeded! %d / %d", D.ENconst, (5000 + mp.enchant.base*30))	tes3.playSound{sound = "Spell Failure Conjuration"}
			else tes3.messageBox("Summ enchant volume = %d / %d", D.ENconst, (5000 + mp.enchant.base*30))	if ef.min ~= ef.max then e.resistedPercent = 50		tes3.messageBox("Anti-exploit! Enchant power reduced by half!") end end
		end end
	end
	if ef.object.school == 1 then D.conjpower = 1 - e.resistedPercent/200		D.conjagr = t ~= p and m.fight > 80 or nil end -- Устанавливаем коэффициент силы призванных существ
	if eid < 500 then
		if eid == tes3.effect.restoreHealth then P = math.random(ef.min, ef.max) * ef.duration * (1 - e.resistedPercent/100)
			if AF[t].vital and AF[t].vital > 0 then AF[t].vital = AF[t].vital - P		P = - AF[t].vital end
			if P > 0 then AF[t].heal = (AF[t].heal or 0) + P	if not T.Heal.timeLeft then local stat = {"endurance", "strength", "agility", "speed", "intelligence", "willpower", "personality", "fatigue"}
				T.Heal = timer.start{duration = 3, iterations = -1, callback = function()	local fin = true
					for r, a in pairs(AF) do if a.heal and a.heal > 0 then fin = nil	a.heal = a.heal - a.heal^0.5*3	if a.heal < 3 then a.heal = nil
						else for i, s in ipairs(stat) do if i ~= 8 and r.mobile[s].current < r.mobile[s].base then tes3.modStatistic{reference = r, name = s, current = a.heal^0.5/2}
							if r.mobile[s].current > r.mobile[s].base then tes3.setStatistic{reference = r, name = s, current = r.mobile[s].base} end break end
							if i == 8 and r.mobile.fatigue.normalized <= 1 then tes3.modStatistic{reference = r, name = "fatigue", current = a.heal^0.5*3} end
						end	if msg2 then tes3.messageBox("%s Healing = %d (+%d stat)", r, a.heal, a.heal^0.5/2) end end
					else a.heal = nil end end	if fin then	T.Heal:cancel() end
				end}
			end end
		elseif CME[eid] and AF[t][CME[eid]] then AF[t][CME[eid]] = AF[t][CME[eid]] - (ef.object.hasNoMagnitude and 100 or math.random(ef.min, ef.max) * ef.duration) * (1 - e.resistedPercent/100)
		elseif eid == tes3.effect.levitate and ef.rangeType ~= 0 then resist = e.resistedPercent + m.resistMagicka + m.willpower.current/2
			if msg then tes3.messageBox("%s  %.1f%% levitation resist (%.1f start + %.1f magic + %.1f willpower)", (e.source.name or e.source.id), resist, e.resistedPercent, m.resistMagicka, m.willpower.current/2) end
			if resist >= math.random(100) then e.resistedPercent = 100 end
		elseif eid == 118 or eid == 119 then e.resistedPercent = e.resistedPercent + m.resistMagicka + m.willpower.current/2 -- Приказы
			if msg then tes3.messageBox("%s  %.1f%% mind control resist (%.1f magic + %.1f willpower)", (e.source.name or e.source.id), e.resistedPercent, m.resistMagicka, m.willpower.current/2) end
		elseif eid == 83 and ef.skill == 9 and t == p and (mp.enchant.current + ef.max * (1 - e.resistedPercent/100)) > 200 then -- Предел баффа зачарования 200
			e.resistedPercent = (1 - (200 - mp.enchant.current) / ef.max) * 100		tes3.messageBox("Max enchant skill!")
		elseif eid == 60 and t == p then local mmax = 1 + mp.willpower.base/100 + mp.intelligence.base/50 + mp.alteration.base/50 + mp.mysticism.base/25 -- Пометка
			local mtab = {}		for i = 1, 10 do if mmax >= i then mtab[i] = i.." - "..(DM["mark"..i] and DM["mark"..i].id or "empty") end end
			tes3.messageBox{message = "Which slot to remember the mark?", buttons = mtab, callback = function(e) DM["mark"..(e.button+1)] = {id = p.cell.id, x = p.position.x, y = p.position.y, z = p.position.z} end}
		end
	elseif eid == 501 and AF[t].T501 == nil then -- Перезарядка зачарованного (501)
		AF[t].T501 = timer.start{duration = 1, iterations = -1, callback = function() M = tes3.getEffectMagnitude{reference = t, effect = 501}	if M == 0 then AF[t].T501:cancel()	AF[t].T501 = nil else
			K = Cpower(m, 14, 14)/100	P = M * K	W = m.readiedWeapon
			if W and W.object.enchantment and W.variables.charge < W.object.enchantment.maxCharge then W.variables.charge = math.min(W.variables.charge + P, W.object.enchantment.maxCharge)
				if msg then tes3.messageBox("Pow = %.1f (x%.2f)  %s charges = %d/%d", P, K, W.object.name, W.variables.charge, W.object.enchantment.maxCharge) end
			else for _, st in pairs(t.object.equipment) do if st.object.enchantment and st.variables and st.variables.charge and st.variables.charge < st.object.enchantment.maxCharge then
				st.variables.charge = math.min(st.variables.charge + P, st.object.enchantment.maxCharge)
				if msg then tes3.messageBox("Pow = %.1f (x%.2f)  %s charges = %d/%d", P, K, st.object.name, st.variables.charge, st.object.enchantment.maxCharge) end break
			end end end		
		end end}
	elseif eid == 502 and AF[t].T502 == nil then -- Починка оружия (502)
		AF[t].T502 = timer.start{duration = 1, iterations = -1, callback = function() M = tes3.getEffectMagnitude{reference = t, effect = 502}	if M == 0 then AF[t].T502:cancel()	AF[t].T502 = nil else
			K = Cpower(m, 11, 11)/100	P = M * K	W = m.readiedWeapon
			if W and W.object.type ~= 11 and W.variables.condition < W.object.maxCondition then W.variables.condition = math.min(W.variables.condition + P, W.object.maxCondition)
				if msg then tes3.messageBox("Pow = %.1f (x%.2f)  %s condition = %d/%d", P, K, W.object.name, W.variables.condition, W.object.maxCondition) end
			end
		end end}
	elseif eid == 503 and AF[t].T503 == nil then -- Починка брони (503)
		AF[t].T503 = timer.start{duration = 1, iterations = -1, callback = function() M = tes3.getEffectMagnitude{reference = t, effect = 503}	if M == 0 then AF[t].T503:cancel()	AF[t].T503 = nil else
			K = Cpower(m, 11, 11)/100	P = M * K
			for _, st in pairs(t.object.equipment) do if st.object.objectType == tes3.objectType.armor and st.variables and st.variables.condition < st.object.maxCondition then
				st.variables.condition = math.min(st.variables.condition + P, st.object.maxCondition)
				if msg then tes3.messageBox("Pow = %.1f (x%.2f)  %s condition = %d/%d", P, K, st.object.name, st.variables.condition, st.object.maxCondition) end	break
			end end
		end end}
	elseif MEF[eid] == "reflect" and t.data.reflect == nil then t.data.reflect = 0
	elseif eid == 507 and t.data.refspell == nil then t.data.refspell = 0
	elseif MEF[eid] == "charge" then t.data.CW = true	-- Зарядить оружие. Эффекты 511, 512, 513, 514, 515
	elseif MEF[eid] == "aura" and t == p then n = nil -- Дамажные ауры. Эффекты 516, 517, 518, 519, 520
		for i, t in ipairs(DA) do if t.s and t.s == e.source.id and t.b.effects[1].id == MID[eid%5] then n = i break end end
		if n == nil then for i, t in ipairs(DA) do if t.tim == nil then n = i break end end end
		if n == nil then md = DA[1].tim		n = 1 for i, t in ipairs(DA) do if t.tim < md then md = t.tim	n = i end end end
		DA[n].s = e.source.id	DA[n].r = ef.radius	DA[n].tim = ef.duration	DA[n].b.effects[1].id = MID[eid%5]	DA[n].b.effects[1].duration = 3
		DA[n].b.effects[1].min = ef.min*(100+Dbonus)/100	DA[n].b.effects[1].max = ef.max*(100+Dbonus)/100	DA[n].b.effects[1].radius = ef.radius
		if not T.DA.timeLeft then local dur = math.max(3 - m:getSkillValue(11)/200, 2.5) 	T.DA = timer.start{duration = dur, iterations = -1, callback = function() local fin = true
			for i, t in ipairs(DA) do if t.tim then t.tim = t.tim - dur	if t.tim <= 0 then t.tim = nil	t.s = nil	t.r = nil	t.b.effects[1].id = -1 else fin = nil end end end
			if fin then T.DA:cancel()	if msg then tes3.messageBox("All auras are over") end
			else	if msg then tes3.messageBox("Aura tick = %.2f  Time = %s %s %s %s %s", dur, DA[1].tim, DA[2].tim, DA[3].tim, DA[4].tim, DA[5].tim) end
				if cfg.agr then for ref in tes3.iterate(p.cell.actors) do for i, t in ipairs(DA) do if t.r and not ref.mobile.isDead and p.position:distance(ref.position) < 25*t.r then
					mwscript.equip{reference = ref, item = t.b}	if ref.mobile.inCombat == false then mwscript.startCombat{reference = ref, target = p} end end end end
				else for mob in tes3.iterate(mp.hostileActors) do for i, t in ipairs(DA) do if t.r and p.position:distance(mob.position) < 25*t.r then mwscript.equip{reference = mob.reference, item = t.b} end end end end
			end
		end} end
	elseif MEF[eid] == "prok" and t == p and not T.Prok.timeLeft then	-- Проки. Эффекты 531, 532, 533, 534, 535
		T.Prok = timer.start{duration = math.max(3 - m:getSkillValue(11)/100, 2), iterations = -1, callback = function()	PRM = {tes3.getEffectMagnitude{reference = t, effect = 531}, tes3.getEffectMagnitude{reference = t, effect = 532},
			tes3.getEffectMagnitude{reference = t, effect = 533}, tes3.getEffectMagnitude{reference = t, effect = 534}, tes3.getEffectMagnitude{reference = t, effect = 535}}
			mc = (PRM[1]*0.3 + PRM[2]*0.3 + PRM[3]*0.4 + PRM[4]*0.5 + PRM[5]*0.4) * 1.5
			if mc == 0 then T.Prok:cancel() elseif m.magicka.current > mc then	local PRrad = m:getSkillValue(11)/20
				for i, M in ipairs(PRM) do if M > 0 then B.PR.effects[i].id = MID[i]  B.PR.effects[i].min = M   B.PR.effects[i].max = M		B.PR.effects[i].radius = M^0.5 + PRrad	B.PR.effects[i].duration = 1	B.PR.effects[i].rangeType = 2
				else B.PR.effects[i].id = -1 end end	mwscript.equip{reference = t, item = B.PR}		tes3.modStatistic{reference = t, name = "magicka", current = -mc}
				if msg then tes3.messageBox("Prok = %d + %d + %d + %d + %d   Manacost = %.1f", PRM[1], PRM[2], PRM[3], PRM[4], PRM[5], mc) end
			end
		end}
	elseif MEF[eid] == "discharge" and t == p and sn ~= DC.sn and not (e.source.objectType == tes3.objectType.enchantment and e.source.castType == 3) then -- Разряд. Эффекты 541, 542, 543, 544, 545
		DC.sn = sn	local bc = 0	n = 0	for i, eff in ipairs(S.DC.effects) do eff.id = -1 end
		for i, eff in ipairs(e.source.effects) do if MEF[eff.id] == "discharge" and eff.duration == ef.duration then n = n + 1	S.DC.effects[n].id = MID[eff.id%5]	S.DC.effects[n].duration = 1 	S.DC.effects[n].rangeType = 2
		S.DC.effects[n].min = durbonus(eff.min, eff.duration - 1, 10)	S.DC.effects[n].max = durbonus(eff.max, eff.duration - 1, 10)	S.DC.effects[n].radius = eff.radius end end
		local balls = DC.f()	if balls > 0 then if T.DC.timeLeft then T.DC:cancel() else DC.R = tes3.createReference{object = "4nm_prok", position = p.position, cell = p.cell}	DC.R.modified = false end
			T.DC = timer.start{duration = 0.1, iterations = ef.duration * 10, callback = function() DC.R.position = p.position + tes3vector3.new(0, 0, mp.height + 50)	bc = bc + 1
				tes3.cast{reference = DC.R, target = DC.ref[bc].mobile and not DC.ref[bc].mobile.isDead and DC.ref[bc] or p, spell = S.DC}
				if T.DC.iterations == 1 then DC.R:disable()	DC.R.modified = false	DC.R = nil elseif bc >= balls then balls = DC.f()	bc = 0	if balls == 0 then T.DC:cancel() end end
			end}
		end
	elseif eid == 601 and t == p and cfg.autoammo and m.magicka.current > 15 then		if m.readiedWeapon then BAM.am = BAM[m.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
		if mwscript.getItemCount{reference = t, item = BAM.am} == 0 then tes3.addItem{reference = t, item = BAM.am, count = 1, playSound = false}	mwscript.equip{reference = t, item = BAM.am}
			tes3.modStatistic{reference = t, name = "magicka", current = - Kcost(15,3,mp,13,14)}
		end
	elseif eid == 510 and t == p and not T.TS.timeLeft then event.register("simulate", SIMTS)	-- Замедление времени (510)
		T.TS = timer.start{duration = 0.5, iterations = -1, callback = function()	P = tes3.getEffectMagnitude{reference = p, effect = 510} * Cpower(mp, 12, 14)/100
			if P == 0 then T.TS:cancel()	event.unregister("simulate", SIMTS)	TSK = 1		tes3.playSound{reference = p, sound = "illusion cast"} else TSK = math.max(1 - P/(P + 40), 0.1) end
		end}
	elseif eid == 504 and t == p then		local col = Rcol(cfg.col)
		L.color[1] = col[1]		L.color[2] = col[2]		L.color[3] = col[3]		L.radius = 100 * math.random(ef.min, ef.max) * (1 - e.resistedPercent/100)
		if LTS then	LTRef[LTS]:cancel()		LTS:disable()	LTS.modified = false	LTRef[LTS] = nil end		LTnew(20*ef.duration-1, p.position)
		if msg then tes3.messageBox("Light active! Radius = %d  Time = %d	Total = %d", L.radius, ef.duration, table.size(LTRef)) end
	elseif eid == 505 and t == p and wc.flagTeleportingDisabled == false then -- Телепорт в город (505) 32 максимум, 22 щас
		local TPP = {{-23000, -15200, 700}, {-14300, 52400, 2300}, {30000, -77600, 2000}, {150300, 31800, 900}, {17800, -101900, 500}, {-11200, 20000, 1500}, {53800, -51000, 400}, {-86800, 92300, 1200},
		{1900, -56800, 1700}, {125000, -105200, 1000}, {125200, 45200, 1800}, {109500, 116000, 600}, {-21600, 103200, 2200}, {109300, -62000, 2200}, {60200, 183300, 500}, {-11100, -71000, 500},
		{-46600, -38100, 400}, {-60100, 26700, 400}, {-68400, 140400, 400}, {-85400, 125600, 1200}, {94600, 115800, 1800}, {87500, 118100, 3700}}
		tes3.messageBox{message = "Where to go?", buttons = {"Nothing", "Balmora", "Ald-ruhn", "Vivec", "Sadrith Mora", "Ebonheart", "Caldera", "Suran", "Gnisis",
		"Pelagiad", "Tel Branora", "Tel Aruhn", "Tel Mora", "Maar Gan", "Molag Mar", "Dagon Fel", "Seyda Neen", "Hla Oad", "Gnaar Mok", "Khuul", "Ald Velothi", "Vos", "Tel Vos"},
		callback = function(e) if e.button ~= 0 then tes3.positionCell{reference = p, position = TPP[e.button], cell = tes3.getCell{x = 0, y = 0}} end end}
	end
elseif ef.rangeType ~= 0 or e.source.objectType == tes3.objectType.alchemy then -- Любые негативные эффекты с дальностью касание и удаленная цель ИЛИ пвсевдоалхимия ИЛИ обычные яды ИЛИ ингредиенты
	if e.caster == t then
		if ef.rangeType ~= 0 then Cfocus = math.max(Cfocus - 50 - m.willpower.current/2, -100) -- Отражение или эксплод спелл будут ослаблены
		elseif e.source.name == "4b_Q" then e.resistedPercent = 0	return -- Быстрая негативная магия на себя всегда на 100% силы
		elseif not EMP[eid] and (e.source.weight > 0 or ef.radius == 1) then -- Обычные яды и ингредиенты используют резист к яду по упрощенной формуле
			resist = m.resistPoison + m.willpower.current*0.2 + m.endurance.current*0.3
			if resist > 200 then e.resistedPercent = 100 elseif resist > 0 then e.resistedPercent = resist/(1 + resist/200) else e.resistedPercent = resist end
			if msg1 then tes3.messageBox("%s  %.1f poison resist (%.1f = %.1f norm + %.1f target)", e.source.name, e.resistedPercent, resist, m.resistPoison, m.willpower.current*0.2 + m.endurance.current*0.3) end	return
		end
	end
	if t.data.refspell then -- новое отражение (507)
		if t.data.refspell > 0 then Cfocus = math.max(Cfocus - t.data.refspell, -100) elseif t.data.refspell < 0 then e.resistedPercent = 100	return
		else	local RFSM = tes3.getEffectMagnitude{reference = t, effect = 507} * Cpower(m, 14, 14)/100
			if RFSM == 0 then t.data.refspell = nil else	local RFSpow = 0
				for _, eff in ipairs(e.source.effects) do if eff.rangeType ~= 0 then RFSpow = RFSpow + (eff.min + eff.max) * eff.object.baseMagickaCost * eff.duration/20 end end	RFSpow = RFSpow * (100 + Cbonus + Cfocus + CritD - Cstam)/100
				if DM.refl then
					if RFSM > RFSpow then mc = Kcost(RFSpow*1.5,3,m,11,14)
						if m.magicka.current > mc then -- пересчитываем бутылку и запускаем шар
							local RFrad = Curve((m.willpower.current + m:getSkillValue(11)), 0.075, 400)
							for i, eff in ipairs(e.source.effects) do if eff.rangeType ~= 0 then	if RFrad > eff.radius then B.RFS.effects[i].radius = eff.radius else B.RFS.effects[i].radius = RFrad end
								B.RFS.effects[i].id = eff.id	B.RFS.effects[i].min = eff.min		B.RFS.effects[i].max = eff.max		B.RFS.effects[i].duration = eff.duration
								B.RFS.effects[i].rangeType = eff.rangeType		B.RFS.effects[i].attribute = eff.attribute		B.RFS.effects[i].skill = eff.skill
							else B.RFS.effects[i].id = -1 end end
							mwscript.equip{reference = t, item = B.RFS}		tes3.modStatistic{reference = t, name = "magicka", current = -mc}
							t.data.refspell = -1		timer.start{duration = 0.1, callback = function() t.data.refspell = 0 end}		e.resistedPercent = 100
							if msg then tes3.messageBox("Reflect = %.1f  Power = %.1f  Cost = %.1f  Radius = %.1f", RFSM, RFSpow, mc, RFrad) end	return
						end
					else if msg then tes3.messageBox("Fail! Reflect = %.1f  Power = %.1f", RFSM, RFSpow) end end
				else	local RFSkoef = math.min(RFSM/RFSpow,1)		mc = Kcost(RFSkoef * RFSpow,2,m,11,14)
					if m.magicka.current > mc then	tes3.modStatistic{reference = t, name = "magicka", current = -mc}
						t.data.refspell = 100 * RFSkoef		Cfocus = math.max(Cfocus - t.data.refspell, -100)
						timer.start{duration = 0.1, callback = function() t.data.refspell = 0 end}
						if msg then tes3.messageBox("Manashield = %.1f  Power = %.1f  Koef = %.2f  Cost = %.1f", RFSM, RFSpow, RFSkoef, mc) end
					end
				end
			end
		end
	end
	if t.data.reflect then -- особые отражения 561-565
		if t.data.reflect > 0 then Cfocus = math.max(Cfocus - t.data.reflect, -150) -- таймер ещё действует - все остальные эффекты вредоносного спелла будут ослаблены
		else local RFM = {tes3.getEffectMagnitude{reference = t, effect = 561}, tes3.getEffectMagnitude{reference = t, effect = 562}, tes3.getEffectMagnitude{reference = t, effect = 563},
		tes3.getEffectMagnitude{reference = t, effect = 564}, tes3.getEffectMagnitude{reference = t, effect = 565}}		local RFtar = Cpower(m, 14, 11)/100
		for i, mag in ipairs(RFM) do if mag ~= 0 then RFM[i] = RFM[i] * RFtar end end	local RFMS = RFM[1] + RFM[2] + RFM[3] + RFM[4] + RFM[5]
		if RFMS == 0 then t.data.reflect = nil else	local RFpow = 0		local RFcas = (100 + Cbonus + Cfocus + CritD - Cstam)/100
			for _, eff in ipairs(e.source.effects) do if eff.rangeType ~= 0 then RFpow = RFpow + (eff.min + eff.max) * eff.duration * eff.object.baseMagickaCost/20 end end		local RFpow2 = RFpow * RFcas
			local RFkoef = math.min(RFMS/RFpow2,1)		mc = Kcost(RFkoef*RFpow2*1.5,3,m,11,14)
				if m.magicka.current > mc then -- пересчитываем бутылку и запускаем шар
					local RFrad = Curve((m.willpower.current + m:getSkillValue(11)), 0.075, 400)
					for i, mag in ipairs(RFM) do if mag ~= 0 then M = RFpow * RFkoef * mag/RFMS * 10 / tes3.getMagicEffect(MID[i]).baseMagickaCost
						B.RF.effects[i].id = MID[i]		B.RF.effects[i].min = M*0.8		B.RF.effects[i].max = M*1.2		B.RF.effects[i].radius = RFrad		B.RF.effects[i].duration = 1	B.RF.effects[i].rangeType = 2
					else B.RF.effects[i].id = -1 end end
					mwscript.equip{reference = t, item = B.RF}		tes3.modStatistic{reference = t, name = "magicka", current = -mc}
					t.data.reflect = 100 * RFkoef	Cfocus = math.max(Cfocus - t.data.reflect, -150)
					timer.start{duration = 0.1, callback = function() t.data.reflect = 0 end}
					if msg then tes3.messageBox("SummMag = %.1f (x%.2f)  Power = %.1f (x%.2f)  Koef = %.1f  Cost = %.1f  Radius = %.1f", RFMS, RFtar, RFpow2, RFcas, RFkoef, mc, RFrad) end
				end
			end
		end
	end
	if eid == 14 then	local frostbonus	local burst = AF[t].fire and AF[t].fire^0.5*2 or 0		Tarmor = Armor(m)		Tbonus = m.endurance.current/4 + m.willpower.current/4	-- Огонь
		if AF[t].frost and AF[t].frost > 0 then frostbonus = AF[t].frost^0.5*5		AF[t].frost = AF[t].frost - math.random(ef.min, ef.max) * ef.duration else frostbonus = 0 end
		resist = m.resistFire + Tarmor + Tbonus - Cbonus - Cfocus - CritD - Dbonus + Cstam - Emp - burst + frostbonus
		if resist > 300 and m.health.normalized < 1 then e.resistedPercent = resist - 200 elseif resist > 200 then e.resistedPercent = 100 elseif resist > 0 then e.resistedPercent = resist/(1 + resist/200) else e.resistedPercent = resist end
		if MKF < 1 then e.resistedPercent = 100 - (100 - e.resistedPercent) * MKF end
		if msg1 then tes3.messageBox("%s  %.1f%% fire resist (%.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f focus - %.1f crit (%.1f%%) - %.1f dur + %.1f stam - %.1f emp - %.1f burst + %.1f frost) x%.2f mult",
		(e.source.name or e.source.id), e.resistedPercent, resist, m.resistFire, Tbonus, Tarmor, Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam, Emp, burst, frostbonus, MKF) end
		if e.resistedPercent < 100 then AF[t].fire = (AF[t].fire or 0) + math.random(ef.min, ef.max) * ef.duration * (1 - e.resistedPercent/100)
			if not T.Fire.timeLeft then T.Fire = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.fire and a.fire > 0 then fin = nil
					a.fire = a.fire - a.fire^0.5	if a.fire < 3 then a.fire = nil elseif msg2 then tes3.messageBox("%s Fire = %d (%d%% burst)", r, a.fire, a.fire^0.5*2) end
				else a.fire = nil end end	if fin then	T.Fire:cancel() end
			end} end
		end
	elseif eid == 16 then	local firebonus		Tarmor = Armor(m)	Tbonus = m.endurance.current/4 + m.willpower.current/4	-- Мороз
		if AF[t].fire and AF[t].fire > 0 then firebonus = AF[t].fire^0.5*5		AF[t].fire = AF[t].fire - math.random(ef.min, ef.max) * ef.duration else firebonus = 0 end
		resist = m.resistFrost + Tarmor + Tbonus - Cbonus - Cfocus - CritD - Dbonus + Cstam - Emp + firebonus
		if resist > 300 and m.health.normalized < 1 then e.resistedPercent = resist - 200 elseif resist > 200 then e.resistedPercent = 100 elseif resist > 0 then e.resistedPercent = resist/(1 + resist/200) else e.resistedPercent = resist end
		if MKF < 1 then e.resistedPercent = 100 - (100 - e.resistedPercent) * MKF end
		if msg1 then tes3.messageBox("%s  %.1f%% frost resist (%.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f focus - %.1f crit (%.1f%%) - %.1f dur + %.1f stam - %.1f emp + %.1f fire) x%.2f mult",
		(e.source.name or e.source.id), e.resistedPercent, resist, m.resistFrost, Tbonus, Tarmor, Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam, Emp, firebonus, MKF) end
		if e.resistedPercent < 100 then AF[t].frost = (AF[t].frost or 0) + math.random(ef.min, ef.max) * ef.duration * (1 - e.resistedPercent/100)
			if not T.Frost.timeLeft then event.register("calcMoveSpeed", CMSFrost)	T.Frost = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.frost and a.frost > 0 then fin = nil		a.frost = a.frost - a.frost^0.5	
					if a.frost < 3 then a.frost = nil else a.frkf = math.max(1 - a.frost^0.5*0.03, 0.1)		if msg2 then tes3.messageBox("%s Frost = %d (%d%% frozen speed)", r, a.frost, a.frkf*100) end end
				else a.frost = nil end end	if fin then event.unregister("calcMoveSpeed", CMSFrost)	T.Frost:cancel() end
			end} end
		end
	elseif eid == 15 then	Tarmor = Armor(m)	Tbonus = m.endurance.current/4 + m.willpower.current/4 -- Молния
		resist = m.resistShock + Tarmor + Tbonus - Cbonus - Cfocus - CritD - Dbonus + Cstam - Emp
		if resist > 300 and m.health.normalized < 1 then e.resistedPercent = resist - 200 elseif resist > 200 then e.resistedPercent = 100 elseif resist > 0 then e.resistedPercent = resist/(1 + resist/200) else e.resistedPercent = resist end
		if MKF < 1 then e.resistedPercent = 100 - (100 - e.resistedPercent) * MKF end
		if msg1 then tes3.messageBox("%s  %.1f%% lightning resist (%.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f focus - %.1f crit (%.1f%%) - %.1f dur + %.1f stam - %.1f emp) x%.2f mult",
		(e.source.name or e.source.id), e.resistedPercent, resist, m.resistShock, Tbonus, Tarmor, Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam, Emp, MKF) end
		if e.resistedPercent < 100 then AF[t].shock = (AF[t].shock or 0) + math.random(ef.min, ef.max) * ef.duration * (1 - e.resistedPercent/100)
			if not T.Shock.timeLeft then T.Shock = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.shock and a.shock > 0 then fin = nil	a.shock = a.shock - a.shock^0.5	if a.shock < 3 then a.shock = nil
					else tes3.modStatistic{reference = r, name = "magicka", current = -0.5*a.shock^0.5}		if msg2 then tes3.messageBox("%s Shock = %d (-%d mana  %d%% tremor)", r, a.shock, a.shock^0.5/2, a.shock^0.5*5) end
					if a.shock^0.5*5 >= math.random(100) and r.mobile.paralyze == 0 and a.tremor == nil then r.mobile.paralyze = 1
						a.tremor = timer.start{duration = (0.3 + a.shock^0.5/100), callback = function() if r.mobile.paralyze > 0 then r.mobile.paralyze = 0 end a.tremor = nil end}
					end end
				else a.shock = nil end end	if fin then	T.Shock:cancel() end
			end} end
		end
	elseif eid == 27 then Tbonus = m.endurance.current * 0.3 + m.willpower.current * 0.2 -- Яд
		resist = m.resistPoison + Tbonus - Cbonus - Cfocus - CritD - Dbonus + Cstam - Emp
		if resist > 300 and m.health.normalized < 1 then e.resistedPercent = resist - 200 elseif resist > 200 then e.resistedPercent = 100 elseif resist > 0 then e.resistedPercent = resist/(1 + resist/200) else e.resistedPercent = resist end
		if MKF < 1 then e.resistedPercent = 100 - (100 - e.resistedPercent) * MKF end
		if msg1 then tes3.messageBox("%s  %.1f%% poison resist (%.1f = %.1f norm + %.1f target - %.1f caster - %.1f focus - %.1f crit (%.1f%%) - %.1f dur + %.1f stam - %.1f emp) x%.2f mult",
		(e.source.name or e.source.id), e.resistedPercent, resist, m.resistPoison, Tbonus, Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam, Emp, MKF) end	
		if e.resistedPercent < 100 then AF[t].poison = (AF[t].poison or 0) + math.random(ef.min, ef.max) * ef.duration * (1 - e.resistedPercent/100)
			if not T.Poison.timeLeft then T.Poison = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
				for r, a in pairs(AF) do if a.poison and a.poison > 0 then fin = nil	a.poison = a.poison - a.poison^0.5	if a.poison < 3 then a.poison = nil 
					else tes3.modStatistic{reference = r, name = "fatigue", current = - a.poison^0.5}	if msg2 then tes3.messageBox("%s Poison = %d (-%d stamina)", r, a.poison, a.poison^0.5) end end
				else a.poison = nil end end	if fin then	T.Poison:cancel() end
			end} end
		end
	else	Tbonus = m.endurance.current * 0.2 + m.willpower.current * 0.3
		if eid == 45 or eid == 46 then resist = m.resistMagicka + m.resistParalysis + Tbonus - Cbonus - Cfocus - CritD + Cstam	-- Паралич и молчание считаем отдельно
			if resist > 0 then e.resistedPercent = resist/(1 + (resist/200)) else e.resistedPercent = resist end	if MKF < 1 then e.resistedPercent = 100 - (100 - e.resistedPercent) * MKF end
			if msg1 then tes3.messageBox("%s  %.1f%% paralysis resist chance (%.1f = %.1f paral + %.1f magic + %.1f target - %.1f caster - %.1f focus - %.1f crit (%.1f%%) + %.1f stam) x%.2f mult",
			(e.source.name or e.source.id), e.resistedPercent, resist, m.resistParalysis, m.resistMagicka, Tbonus, Cbonus, Cfocus, CritD, CritC, Cstam, MKF) end
			if e.resistedPercent >= math.random(100) then e.resistedPercent = 100 end
		else resist = m.resistMagicka + Tbonus - Cbonus - Cfocus - CritD - Dbonus + Cstam - Emp	-- Всё остальное негативное кроме паралича
			if resist > 200 then e.resistedPercent = 100 elseif resist > 0 then e.resistedPercent = resist/(1 + resist/200) else e.resistedPercent = resist end		if MKF < 1 then e.resistedPercent = 100 - (100 - e.resistedPercent) * MKF end
			if msg1 then tes3.messageBox("%s  %.1f%% magic resist (%.1f = %.1f norm + %.1f target - %.1f caster - %.1f focus - %.1f crit (%.1f%%) - %.1f dur + %.1f stam - %.1f emp) x%.2f mult",
			(e.source.name or e.source.id), e.resistedPercent, resist, m.resistMagicka, Tbonus, Cbonus, Cfocus, CritD, CritC, Dbonus, Cstam, Emp, MKF) end
			if eid == 23 and e.resistedPercent < 100 then AF[t].vital = (AF[t].vital or 0) + math.random(ef.min, ef.max) * ef.duration * (1 - e.resistedPercent/100)
				if not T.Vital.timeLeft then local ttype = {"strength", "endurance", "agility", "speed", "intelligence"}	T.Vital = timer.start{duration = 1, iterations = -1, callback = function()	local fin = true
					for r, a in pairs(AF) do if a.vital and a.vital > 0 then fin = nil	a.vital = a.vital - a.vital^0.5
						if a.vital < 3 then a.vital = nil else
						if a.vital^0.5*5 > math.random(100) then tes3.modStatistic{reference = r, name = ttype[math.random(5)], current = -0.5*a.vital^0.5}	if msg then tes3.messageBox("%s  %.1f trauma damage!", r, a.vital^0.5*0.5) end end
						if msg2 then tes3.messageBox("%s Trauma = %d (%d%% chance)", r, a.vital, a.vital^0.5*5) end end
					else a.vital = nil end end	if fin then	T.Vital:cancel() end
				end} end
			end
		end
	end
else e.resistedPercent = 0	end -- Любые негативные эффекты с дальностью на себя, включая постоянные и баффо-дебаффы и болезни, будут действовать на 100% силы.
end


local AOE = {}	local RUN = {}	local Tot = {}	-- АОЕ (521-525)	РУНЫ (526-530)		ТОТЕМЫ (551-555)
local function AOEcol(e) if e.sourceInstance.caster == p then
n = nil		local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	tes3.getObject(AoEmod[ef.id%5]).radius = ef.radius * 40 -- AOE[n].r.object.radius
for i, t in ipairs(AOE) do if t.tim == nil then n = i break end end
if n == nil then n = 1	md = AOE[1].tim		for i, t in ipairs(AOE) do if t.tim < md then md = t.tim	n = i end end end 
if AOE[n].r then AOE[n].r:disable()		AOE[n].r.modified = false end
AOE[n].r = tes3.createReference{object = AoEmod[ef.id%5], position = e.collision.point + tes3vector3.new(0,0,10), cell = p.cell, scale = (ef.radius * 0.15)}	AOE[n].r.modified = false	AOE[n].tim = ef.duration
AOE[n].b.effects[1].id = MID[ef.id%5]	AOE[n].b.effects[1].min = durbonus(ef.min, ef.duration - 4, 5)	AOE[n].b.effects[1].max = durbonus(ef.max, ef.duration - 4, 5)	AOE[n].b.effects[1].duration = 2	AOE[n].b.effects[1].radius = ef.radius
if not AOE.Tim.timeLeft then local dur = 2 - math.min(mp:getSkillValue(11),100)/400	AOE.Tim = timer.start{duration = dur, iterations = -1, callback = function() local fin = true
	for i, t in ipairs(AOE) do if t.tim then t.tim = t.tim - dur	if t.tim <= 0 then t.tim = nil	t.r:disable()	t.r.modified = false	t.r = nil	t.b.effects[1].id = -1	else fin = nil end end end
	if fin then AOE.Tim:cancel()		if msg then tes3.messageBox("All AoE ends") end
	else	if msg then tes3.messageBox("AoE tick = %.2f  Time = %s %s %s %s %s", dur, AOE[1].tim, AOE[2].tim, AOE[3].tim, AOE[4].tim, AOE[5].tim) end	
		for i, t in ipairs(AOE) do if t.tim then for r in tes3.iterate(t.r.cell.actors) do if not r.mobile.isDead and t.r.position:distance(r.position) < 110 * t.r.scale then
			mwscript.equip{reference = r, item = t.b}		if not r.mobile.inCombat then mwscript.startCombat{reference = r, target = p} end
		end end end end
	end
end} end
end end

local function RUNcol(e) if RUN.num ~= e.sourceInstance.serialNumber then	n = nil		local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	RUN.num = e.sourceInstance.serialNumber
for i, t in ipairs(RUN) do if t.r == nil then n = i	break end end
if n == nil then n = 1	md = RUN[1].tim		for i, t in ipairs(RUN) do if t.tim < md then md = t.tim	n = i end end
	for i, eff in ipairs(RUN[n].s.effects) do RUN.exp.effects[i].id = eff.id	RUN.exp.effects[i].min = eff.min	RUN.exp.effects[i].max = eff.max	RUN.exp.effects[i].radius = eff.radius
	RUN.exp.effects[i].duration = eff.duration		RUN.exp.effects[i].rangeType = 1 end
	mwscript.explodeSpell{reference = RUN[n].r, spell = RUN.exp}	RUN[n].r:deleteDynamicLightAttachment() 	RUN[n].r:disable()		RUN[n].r.modified = false
end
RUN[n].r = tes3.createReference{object = "4nm_rune", position = e.collision.point + tes3vector3.new(0,0,5), cell = p.cell, scale = ef.radius * 0.18}
local light = niPointLight.new()	light:setAttenuationForRadius(ef.radius/2)	light.diffuse = tes3vector3.new(LID[ef.id%5][1], LID[ef.id%5][2], LID[ef.id%5][3])
RUN[n].r.sceneNode:attachChild(light)		light:propagatePositionChange()		RUN[n].r:getOrCreateAttachedDynamicLight(light, 0)		RUN[n].r.modified = false
RUN[n].tim = math.floor((mp.intelligence.current + mp:getSkillValue(11) + mp:getSkillValue(14))/10 + 20)
for i, eff in ipairs(RUN[n].s.effects) do eff.id = -1 end -- очищаем спелл
for i, eff in ipairs(e.sourceInstance.source.effects) do if MEF[eff.id] == "rune" and eff.radius == ef.radius then -- заполняем спелл
	RUN[n].s.effects[i].id = MID[eff.id%5]	RUN[n].s.effects[i].min = eff.min	RUN[n].s.effects[i].max = eff.max	RUN[n].s.effects[i].duration = eff.duration		RUN[n].s.effects[i].radius = eff.radius		RUN[n].s.effects[i].rangeType = 1
end end
if not RUN.Tim.timeLeft then RUN.Tim = timer.start{duration = 1, iterations = -1, callback = function() local fin = true
	for i, t in ipairs(RUN) do	if t.r then fin = false		t.tim = t.tim - 1	if t.tim < 1 then mwscript.explodeSpell{reference = t.r, spell = t.s}	t.r:deleteDynamicLightAttachment() 	t.r:disable()	t.r.modified = false	t.r = nil
	else	for r in tes3.iterate(t.r.cell.actors) do if t.r and not r.mobile.isDead and t.r.position:distance(r.position) < 80 * t.r.scale then
		mwscript.explodeSpell{reference = t.r, spell = t.s}	t.r:deleteDynamicLightAttachment() 	t.r:disable()	t.r.modified = false	t.r = nil	t.tim = 0
	end end end end end		if fin then RUN.Tim:cancel()	if msg then tes3.messageBox("All runes ends") end end
end} end
if msg then tes3.messageBox("Rune %s active. Scale = %.2f  Time: %s, %s, %s, %s, %s", n, RUN[n].r.scale, RUN[1].tim, RUN[2].tim, RUN[3].tim, RUN[4].tim, RUN[5].tim) end
end end

local function TOTcol(e) if Tot.num ~= e.sourceInstance.serialNumber then	n = nil		local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	Tot.num = e.sourceInstance.serialNumber
for i, t in ipairs(Tot) do if t.r == nil then n = i	break end end
if n == nil then n = 1	md = Tot[1].tim		for i, t in ipairs(Tot) do if t.tim < md then md = t.tim	n = i end end
	if Tot[n].dur > 9 then for i, eff in ipairs(Tot[n].s.effects) do Tot.exp.effects[i].id = eff.id		Tot.exp.effects[i].min = eff.min	Tot.exp.effects[i].max = eff.max	Tot.exp.effects[i].radius = eff.radius
	Tot.exp.effects[i].duration = 1		Tot.exp.effects[i].rangeType = 1 end	mwscript.explodeSpell{reference = Tot[n].r, spell = Tot.exp} end
	Tot[n].r:deleteDynamicLightAttachment() 	Tot[n].r:disable()		Tot[n].r.modified = false
end
Tot[n].r = tes3.createReference{object = "4nm_totem", position = e.collision.point + tes3vector3.new(0,0,60*(1 + ef.radius/50)), cell = p.cell, scale = 1 + ef.radius/50}	Tot[n].c = 0	Tot[n].tim = ef.duration	Tot[n].dur = ef.duration
local light = niPointLight.new()	light:setAttenuationForRadius((1 + ef.radius/50)*3)		light.diffuse = tes3vector3.new(LID[ef.id%5][1], LID[ef.id%5][2], LID[ef.id%5][3])
Tot[n].r.sceneNode:attachChild(light)		light:propagatePositionChange()		Tot[n].r:getOrCreateAttachedDynamicLight(light, 0)		Tot[n].r.modified = false
for i, eff in ipairs(Tot[n].s.effects) do eff.id = -1 end -- очищаем спелл шара
for i, eff in ipairs(e.sourceInstance.source.effects) do if MEF[eff.id] == "totem" and eff.duration == ef.duration then -- заполняем спелл шара для тотема
	Tot[n].s.effects[i].id = MID[eff.id%5]	Tot[n].s.effects[i].min = eff.min	Tot[n].s.effects[i].max = eff.max	Tot[n].s.effects[i].radius = eff.radius		Tot[n].s.effects[i].duration = 1	Tot[n].s.effects[i].rangeType = 2
	Tot[n].c = Tot[n].c + (Tot[n].s.effects[i].min + Tot[n].s.effects[i].max) * Tot[n].s.effects[i].object.baseMagickaCost * 0.05 * (1 + Tot[n].s.effects[i].radius^2/(6 * Tot[n].s.effects[i].radius + 200))
end end
if msg then tes3.messageBox("Totem %s active. Scale = %.2f   Cost = %.1f   Time: %s, %s, %s, %s, %s", n, Tot[n].r.scale, Tot[1].c, Tot[1].tim, Tot[2].tim, Tot[3].tim, Tot[4].tim, Tot[5].tim) end
if not Tot.Tim.timeLeft then local dur = 2 - math.min(mp:getSkillValue(11),100)/200		Tot.Tim = timer.start{duration = dur, iterations = -1, callback = function() local fin = true	local tref, mindist
	for i, t in ipairs(Tot) do if t.r then fin = false	t.tim = t.tim - dur		if t.tim > 0 then
		if Acells[t.r.cell] and mp.magicka.current > t.c then tref = nil	mindist = 2000 + (mp.intelligence.current + mp:getSkillValue(11) + mp:getSkillValue(14))*10
			if cfg.agr then for c, _ in pairs(Acells) do for r in tes3.iterate(c.actors) do if r.mobile and not r.mobile.isDead and mindist > t.r.position:distance(r.position) then mindist = t.r.position:distance(r.position)	tref = r end end end
			else for mob in tes3.iterate(mp.hostileActors) do if not mob.isDead and mindist > t.r.position:distance(mob.position) then mindist = t.r.position:distance(mob.position)	tref = mob.reference end end end
			if tref then tes3.cast{reference = t.r, spell = t.s, target = tref}		mp.magicka.current = mp.magicka.current - t.c	if msg then tes3.messageBox("Totem %s   Target = %s   Manacost = %.1f", i, tref, t.c) end
			elseif msg then tes3.messageBox("Totem %s   No target", i) end
		end
	else if t.dur > 9 then for _, eff in ipairs(t.s.effects) do eff.rangeType = 1 end	mwscript.explodeSpell{reference = t.r, spell = t.s} end		t.r:deleteDynamicLightAttachment()	t.r:disable()	t.r.modified = false	t.r = nil	t.tim = 0
	end end end
	if fin then Tot.Tim:cancel()	if msg then tes3.messageBox("All totems ends") end end
end} end
end end


local KSR = {}	local KST, fr
local function CMSblast(e)	if KSR[e.reference] then e.mobile.impulseVelocity = KSR[e.reference] end
	if wc.lastFrameTime ~= fr then fr = wc.lastFrameTime	KST = KST + 1	if KST == 10 then event.unregister("calcMoveSpeed", CMSblast)	KST = nil	KSR = {} end end
end

local function KSCollision(e) if e.collision then	local dist, pos1, dam
local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	local pos = e.collision.point	K = Cpower(mp, 11, 10)
local rad = (ef.radius + math.random(ef.min, ef.max)/5) * K/5
for c, _ in pairs(Acells) do for ref in tes3.iterate(c.actors) do if ref.mobile and not ref.mobile.isDead then dist = pos:distance(ref.position)	if dist < rad then pos1 = ref.position:copy()		pos1.z = pos1.z + 70
	KSR[ref] = (pos1 - pos):normalized() * (rad - dist)*2
	dam = math.random(ef.min, ef.max) * (K/100 - ref.mobile.endurance.current/400 - ref.mobile.willpower.current/400 - Armor(ref.mobile)/100) * (rad - dist)/rad
	if dam > 0 then tes3.modStatistic{reference = ref, name = "health", current = - dam} end	if not ref.mobile.inCombat and ref.mobile.health.current > 0 then ref.mobile:startCombat(mp) end
	if msg then tes3.messageBox("Kinetic strike! %s   %.1f damage, acsel = %d (%d - %d)", ref, dam, (rad - dist)*2, rad, dist) end
end end end end
if table.size(KSR) > 0 and KST == nil then KST = 0	fr = wc.lastFrameTime		event.register("calcMoveSpeed", CMSblast) end
end end


local function Drobash(spell)	-- Дробовик. Эффекты 536 - 540
	for i, eff in ipairs(spell.effects) do if MEF[eff.id] == "shotgun" then
		B.SG.effects[i].id = MID[eff.id%5]	B.SG.effects[i].min = eff.min	B.SG.effects[i].max = eff.max	B.SG.effects[i].radius = eff.radius		B.SG.effects[i].duration = eff.duration		B.SG.effects[i].rangeType = 2
	else B.SG.effects[i].id = -1 end end	B.SG.icon = spell.name == "4b_ES" and spell.icon == "s\\b_chargeFrost.tga" and "s\\b_chargeFrost.tga" or "s\\b_shotgunFire.tga"
	local iter = 3 + math.floor(mp:getSkillValue(11)/100 + mp.intelligence.current/200 + mp:getSkillValue(14)/200)		local count = 1		mwscript.equip{reference = p, item = B.SG}
	local function Shot() timer.delayOneFrame(function() mwscript.equip{reference = p, item = B.SG}		count = count + 1	if iter > count then Shot() end end) end	Shot()
end


local RAYTim = timer	-- Луч. Эффекты 546 - 550
local function RayAllah(spell)	if RAYTim.timeLeft then RAYTim:cancel() end
	for i, eff in ipairs(spell.effects) do if MEF[eff.id] == "ray" and eff.duration == spell.effects[1].duration then -- время всех последующих эффектов должно быть равно времени первого!
		B.RAY.effects[i].id = MID[eff.id%5]		B.RAY.effects[i].min = durbonus(eff.min, eff.duration - 1, 10)		B.RAY.effects[i].max = durbonus(eff.max, eff.duration - 1, 10)
		B.RAY.effects[i].radius = eff.radius	B.RAY.effects[i].duration = 1	B.RAY.effects[i].rangeType = 2
	else B.RAY.effects[i].id = -1 end end	B.RAY.icon = spell.name == "4b_ES" and spell.icon == "s\\b_chargeFrost.tga" and "s\\b_chargeFrost.tga" or "s\\b_rayFire.tga"
	RAYTim = timer.start{duration = 0.1, iterations = (spell.effects[1].duration * 10), callback = function() mwscript.equip{reference = p, item = B.RAY} end}
end


local TPpos, TPproj		local TPmod = 1
local function runTeleport() local TPdist = p.position:distance(TPpos)	local TPmdist = 40*Cpower(mp, 11, 14)	if TPdist > 200 then
	if TPdist > TPmdist then  TPpos = p.position:interpolate(TPpos, TPmdist)		TPdist = TPmdist end	mc = Kcost(20+TPdist/50,2,mp,11,14)
	if mc < mp.magicka.current then mp.isSwimming = true	tes3.playSound{sound="Spell Failure Destruction"}	tes3.positionCell{reference = p, position = TPpos, cell = p.cell}
		tes3.modStatistic{reference = p, name = "magicka", current = -mc}	if msg then tes3.messageBox("Distance = %d  Manacost = %.1f", TPdist, mc) end
	end
end end
local function TeleportCollision(e) if e.collision and e.sourceInstance.caster == p and TPmod == 1 then	TPpos = e.collision.point:copy()	runTeleport() end end
local Dfr, V	local function CMSdash(e) if e.reference == p then mp.impulseVelocity = V*(1/30/wc.deltaTime)	Dfr = Dfr + 1	if Dfr >= 7 then event.unregister("calcMoveSpeed", CMSdash)		Dfr = nil end end end

local TER, TEP, TEmod, TEcost, TEdmg		--local TEList = {[tes3.objectType.weapon] = true, }
local function SIMTEL(e)
	if TEmod == 1 then TER.position = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*150 + tes3vector3.new(0,0,-30)		TER.orientation = p.orientation
	elseif TEmod == 2 then TER.position = TEP.position		TER.orientation = p.orientation
	elseif TEmod == 3 then TER.position = TER.position:interpolate(p.position, 1000*wc.deltaTime)	if p.position:distance(TER.position) < 150 then TEmod = 1	tes3.playSound{sound = "enchant fail"} end end
end

local function TELdrop() event.unregister("simulate", SIMTEL)	local hit = tes3.rayTest{position = TER.position, direction = tes3vector3.new(0,0,-1)}	if hit then TER.position = hit.intersection + tes3vector3.new(0,0,5) end
if msg then tes3.messageBox("%s no longer under control", TER.object.name) end		TEmod = nil		TER = nil	TEP = nil end
local function TELnew(r)	if TEmod then TELdrop() end		if tes3.isAffectedBy{reference = p, effect = 506} then TEcost = 5 + r.object.weight		TER = r		TEmod = 1	event.register("simulate", SIMTEL)
	if not tes3.hasOwnershipAccess{target = r} then tes3.triggerCrime{value = r.object.value, type = 5, victim = r.attachments.variables.owner} end
	TEdmg = (r.object.objectType == tes3.objectType.weapon and (r.object.type < 9 or r.object.type > 10) or r.object.objectType == tes3.objectType.ammunition) and
	math.max(r.object.slashMax, r.object.chopMax, r.object.thrustMax, r.object.weight) or 1 + r.object.weight
	if msg then tes3.messageBox("%s under control!  weight = %.1f  dmg = %d", r.object.name, r.object.weight, TEdmg) end
end end


local MCT, MCB, arm1, arm2
local function MCStart(e) if e.button == 0 then MCB.current = 0 	MCT:cancel()	MCT = nil	arm1.appCulled = true	arm2.appCulled = true	event.unregister("mouseButtonUp", MCStart) end
if cfg.mcs then tes3.removeSound{sound = "destruction bolt", reference = p} end end
local function onMouseButtonDown(e) if not tes3ui.menuMode() and e.button == 0 and not MCT and mp.spellReadied then
	arm1.appCulled = false	arm2.appCulled = false	local MCK = 2 + mp.willpower.current/200 + mp.agility.current/200	if cfg.mcs then tes3.playSound{sound = "destruction bolt", reference = p, loop = true} end
	MCT = timer.start{duration = 0.1, iterations = -1, callback = function() MCB.current = MCB.current + MCK end}	event.register("mouseButtonUp", MCStart)
end end


local DEO	local DER = {}
local function DEDEL() for r, ot in pairs(DER) do if r.sceneNode then r.sceneNode:detachChild(r.sceneNode:getObjectByName("detect"))	r.sceneNode:update()	r.sceneNode:updateNodeEffects() end end		DER = {} end
local QST = timer	local Qicon, QB
local QK = {[cfg.q0.keyCode] = "0", [cfg.q1.keyCode] = "1", [cfg.q2.keyCode] = "2", [cfg.q3.keyCode] = "3", [cfg.q4.keyCode] = "4", [cfg.q5.keyCode] = "5", [cfg.q6.keyCode] = "6", [cfg.q7.keyCode] = "7", [cfg.q8.keyCode] = "8", [cfg.q9.keyCode] = "9"}
local function onKey(e) if not tes3ui.menuMode() then local k = e.keyCode
if k == cfg.magkey.keyCode then -- Быстрый каст
	if D.QSP["0"] == nil then if QS ~= mp.currentSpell then if mp.currentSpell and mp.currentSpell.objectType == tes3.objectType.spell and mp.currentSpell.castType == 0 then QS = mp.currentSpell
		for i, eff in ipairs(QS.effects) do B.Q.effects[i].id = eff.id		B.Q.effects[i].min = eff.min	B.Q.effects[i].max = eff.max	B.Q.effects[i].duration = eff.duration
			B.Q.effects[i].radius = eff.radius		B.Q.effects[i].rangeType = eff.rangeType		B.Q.effects[i].attribute = eff.attribute		B.Q.effects[i].skill = eff.skill
		end		Qicon.contentPath = "icons/s/b_" .. QS.effects[1].object.icon:sub(3)
	end end end
	if QS then mc = QS.magickaCost * (math.max(3 - mp.agility.current/100, 2) + math.max(0.5 - mp.intelligence.current/500, 0.3) * math.max(10 - QB.current, 0))
		if mp.magicka.current > mc and mp.fatigue.current > QS.magickaCost then mwscript.equip{reference = p, item = B.Q}		MCB.current = 0
			tes3.modStatistic{reference = p, name = "magicka", current = -mc}		tes3.modStatistic{reference = p, name = "fatigue", current = - QS.magickaCost*(0.5 + 0.5*mp.encumbrance.normalized)}
			if msg then tes3.messageBox("%s qick casted! Cost = %.1f (%s%%)", QS.name, mc, mc*100/QS.magickaCost) end	QB.current = math.max(QB.current - 2, 0)
			if not QST.timeLeft then QST = timer.start{duration = math.max(1 - mp.speed.current/200, 0.5), iterations = -1, callback = function()
			QB.current = QB.current + 1		if QB.current == 20 then QST:cancel() end end} end 
		end
	end
elseif QK[k] then -- Выбор быстрого каста
	if QK[k] ~= "0" then
		if e.isShiftDown then if mp.currentSpell and mp.currentSpell.objectType == tes3.objectType.spell and mp.currentSpell.castType == 0 then D.QSP[QK[k]] = mp.currentSpell.id
			tes3.messageBox("%s remembered for %s quick cast slot", D.QSP[QK[k]], QK[k])
		end end
		if D.QSP[QK[k]] then D.QSP["0"] = QK[k]		QS = tes3.getObject(D.QSP[D.QSP["0"]])		Qicon.contentPath = "icons/s/b_" .. QS.effects[1].object.icon:sub(3)
			for i, eff in ipairs(QS.effects) do B.Q.effects[i].id = eff.id		B.Q.effects[i].min = eff.min	B.Q.effects[i].max = eff.max	B.Q.effects[i].duration = eff.duration
				B.Q.effects[i].radius = eff.radius		B.Q.effects[i].rangeType = eff.rangeType		B.Q.effects[i].attribute = eff.attribute		B.Q.effects[i].skill = eff.skill
			end		if msg then tes3.messageBox("%s prepared for quick cast - slot %s  %s", QS.name, D.QSP["0"], QS.flags == 4 and "No power bonuses" or "") end
		end
	else D.QSP["0"] = nil end
elseif k == cfg.tpkey.keyCode then local DMag = tes3.getEffectMagnitude{reference = p, effect = 600}	-- Телепорт и дэши
	if e.isControlDown then if DM.sectp then DM.sectp = false tes3.messageBox("Secondary TP mode disabled") else DM.sectp = true tes3.messageBox("Secondary TP mode enabled") end
	elseif e.isAltDown then tes3.runLegacyScript{command = "ToggleLoadFade"}   tes3.messageBox("Load fader state is turned")
	elseif TPproj then TPpos = TPproj.position		runTeleport()	if not DM.sectp then TPmod = 0 end
	elseif DMag > 0 then	V = tes3.getPlayerEyeVector()	local pik	local DD = DMag * Cpower(mp, 11, 14)*3		mc = 10 + Kcost(DMag*2,2,mp,11,14)
		if mp.isMovingForward then if mp.isMovingLeft then pik = 7 elseif mp.isMovingRight then pik = 1 else pik = 0 end
		elseif mp.isMovingBack then if mp.isMovingLeft then pik = 1 elseif mp.isMovingRight then pik = 7 else pik = 0 end
		elseif mp.isMovingLeft then pik = 6 elseif mp.isMovingRight then pik = 2 else pik = 0 end
		Matr:toRotationZ(math.rad(pik*45))	V = Matr * V
		if mp.isMovingBack then V.x = -V.x	V.y = -V.y	V.z = -V.z elseif pik == 2 or pik == 6 then V.x = V.x/(1 - V.z^2)^0.5		V.y = V.y/(1 - V.z^2)^0.5	V.z = 0 end
		local dhit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = V}	if dhit then dhit = dhit.intersection:distance(p.position)/(DD*7/30)	if dhit < 1 then DD = DD * dhit		mc = mc * dhit end end
		if Dfr == nil and mc < mp.magicka.current then V = V*DD		Dfr = 0		event.register("calcMoveSpeed", CMSdash)	tes3.playSound{sound="Spell Failure Destruction"}
		tes3.modStatistic{reference = p, name = "magicka", current = -mc}	if msg then tes3.messageBox("Dist = %d  Cost = %d", DD, mc) end end
	end
elseif k == cfg.telkey.keyCode then -- Телекинез
	if not TEmod then	local ref = tes3.getPlayerTarget()	if ref and ref.object.weight then TELnew(ref) end
	elseif TEmod == 1 then p:activate(TER)		event.unregister("simulate", SIMTEL)	TER = nil	TEP = nil	TEmod = nil
	elseif TEmod == 2 then TEmod = 3	TEP = nil
	elseif TEmod == 3 and mp.magicka.current > 2*TEcost then	mc = Kcost(TEcost,2,mp,11,14) * math.min(1 + p.position:distance(TER.position)/5000, 2)
		tes3.modStatistic{reference = p, name = "magicka", current = -mc}	TEmod = 1	tes3.playSound{sound = "enchant fail"}	if msg then tes3.messageBox("Extra teleport, manacost = %.1f (%.1f base)", mc, TEcost) end
	end
elseif k == cfg.cwkey.keyCode then -- Заряженное оружие
	if e.isAltDown then		if DM.cw then DM.cw = false tes3.messageBox("Charged weapon: on hit") else DM.cw = true tes3.messageBox("Charged weapon: on attack") end
	elseif D.CW and TER then	mc = CWMag(p, 1)	if mc == 0 then D.CW = nil else
		if mp.magicka.current > mc*2 then CWR = mp:getSkillValue(11)/20	n = 0		for i, eff in ipairs(S.CWT.effects) do eff.id = -1 end
			for i, m in ipairs(CWM) do if m > 0 then n = n + 1		S.CWT.effects[n].id = MID[i]	S.CWT.effects[n].rangeType = MB[1] == 128 and 2 or 1
			S.CWT.effects[n].min = m   S.CWT.effects[n].max = m		S.CWT.effects[n].duration = 1	S.CWT.effects[n].radius = m^0.5 + CWR end end
			if MB[1] == 128 then mc = mc*2	local tar	local mindist = 8000
				if cfg.agr then for r in tes3.iterate(TER.cell.actors) do if not r.mobile.isDead and mindist > TER.position:distance(r.position) then mindist = TER.position:distance(r.position)	tar = r end end
				else for mob in tes3.iterate(mp.hostileActors) do if mindist > TER.position:distance(mob.position) then mindist = TER.position:distance(mob.position)	tar = mob.reference end end end
				if tar then tes3.cast{reference = TER, target = tar, spell = S.CWT}		tes3.modStatistic{reference = p, name = "magicka", current = -mc} end
			else mc = mc*1.5	mwscript.explodeSpell{reference = TER, spell = S.CWT}	tes3.modStatistic{reference = p, name = "magicka", current = -mc} end
			if msg then tes3.messageBox("CWT = %d + %d + %d + %d + %d   Manacost = %.1f", CWM[1], CWM[2], CWM[3], CWM[4], CWM[5], mc) end	
		end
	end end
elseif k == cfg.detkey.keyCode then local mag = Cpower(mp, 14, 12)/5  -- Обнаружение
	local node, nod		local dist = {tes3.getEffectMagnitude{reference = p, effect = 64}*mag, tes3.getEffectMagnitude{reference = p, effect = 65}*mag, tes3.getEffectMagnitude{reference = p, effect = 66}*mag}	DEDEL()
	for c, _ in pairs(Acells) do for r in c:iterateReferences() do local ot
		if r.object.objectType == tes3.objectType.container and not r.object.organic then ot = "cont" elseif r.object.objectType == tes3.objectType.door then ot = "door" elseif r.mobile and not r.mobile.isDead then
		if r.object.objectType == tes3.objectType.npc or r.object.type == 3 then ot = "npc" elseif r.object.type == 1 then ot = "dae" elseif r.object.type == 2 then ot = "und" elseif r.object.blood == 2 then ot = "robo" else ot = "ani" end
		elseif r.object.enchantment or r.object.isSoulGem then ot = "en" elseif r.object.isKey then ot = "key" end
		if ot and r.sceneNode then node = r.sceneNode:getObjectByName("detect") if node then r.sceneNode:detachChild(node) 	r.sceneNode:update()	r.sceneNode:updateNodeEffects() end
			if p.position:distance(r.position) < dist[DEO[ot].s] then nod = DEO[ot].m:clone()	if r.mobile then nod.translation.z = nod.translation.z + r.mobile.height/2 end
		r.sceneNode:attachChild(nod, true)	r.sceneNode:update()	r.sceneNode:updateNodeEffects()		DER[r] = ot end end
	end end		if table.size(DER) > 0 then tes3.playSound{reference = p, sound = "illusion hit"}	if T.DET.timeLeft then T.DET:reset() else T.DET = timer.start{duration = 10, callback = DEDEL} end end
elseif k == cfg.cpkey.keyCode then -- Контроль снарядов
	if e.isAltDown then if DM.cpt then DM.cpt = false tes3.messageBox("Free flight") else DM.cpt = true tes3.messageBox("Smart mode") end
	elseif ic:isKeyDown(ic.inputMaps[1].code) then DM.cp = 3 tes3.messageBox("Teleport projectiles") elseif ic:isKeyDown(ic.inputMaps[2].code) then DM.cp = 1 tes3.messageBox("Homing projectiles")
	elseif ic:isKeyDown(ic.inputMaps[3].code) then DM.cp = 2 tes3.messageBox("Spin projectiles") else DM.cp = 0 tes3.messageBox("Target projectiles") end
elseif k == cfg.reflkey.keyCode then -- Отражение
	if DM.refl then DM.refl = false tes3.messageBox("Reflect spell mode: manashield") else DM.refl = true tes3.messageBox("Reflect spell mode: reflect") end
elseif k == cfg.markkey.keyCode then	local mtab = {}		for i = 1, 10 do mtab[i] = i.." - "..(DM["mark"..i] and DM["mark"..i].id or "empty") end -- Пометки
	tes3.messageBox{message = "Select a mark for recall", buttons = mtab, callback = function(e) local v = "mark"..(e.button+1)		if DM[v] then
		mp.markLocation.cell = tes3.getCell{id = DM[v].id}		mp.markLocation.position = tes3vector3.new(DM[v].x, DM[v].y, DM[v].z)
	end end}
elseif k == cfg.ammokey.keyCode then -- Пополнение призванных патронов
	if e.isAltDown and mp.actionData.animationAttackState == 10 then mp.actionData.animationAttackState = 0	-- застрявшая анимация каста
	elseif tes3.isAffectedBy{reference = p, effect = 601} and mp.magicka.current > 15 then	if mp.readiedWeapon then BAM.am = BAM[mp.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
		if mwscript.getItemCount{reference = p, item = BAM.am} == 0 then tes3.addItem{reference = p, item = BAM.am, count = 1, playSound = false}
			tes3.modStatistic{reference = p, name = "magicka", current = - Kcost(15,3,mp,13,14)}
		end mp:equip{item = BAM.am}
	end
end end end


local ENTim = timer		local Bar4
local function EnchantCast(cost)	ENcost = cost - ENPC.max/100
	if ENcost > 0 then ENPC.current = math.max(ENPC.current - ENcost, 0)		Bar4.visible = true		D.ENvol = ENPC.current
		if not ENTim.timeLeft then ENTim = timer.start{duration = 3, iterations = -1, callback = function()
			ENPC.current = ENPC.current + ENPC.max*(tes3.getEffectMagnitude{reference = p, effect = 76}*0.003 + (mp.spellReadied and 0.03 or 0.02))
			if ENPC.normalized > 1 then ENPC.current = ENPC.max	ENTim:cancel()	D.ENvol = nil	Bar4.visible = false else D.ENvol = ENPC.current end end}
		end
	end		if msg then tes3.messageBox("Potencial chagre cost = %s(%s)  Limit = %s/%s", ENcost, cost, ENPC.current, ENPC.max) end		
end

local function onMagicCasted(e) if e.caster == p then
	if e.source.objectType == tes3.objectType.spell and e.source.castType == 0 then if mp.actionData.animationAttackState == 11 and cfg.acscast and mp.agility.current > 80 then mp.actionData.animationAttackState = 0 end	
		if MCB.normalized > 0 then SI[e.sourceInstance.serialNumber] = math.min(MCB.normalized,1)	MCB.current = 0 end
	elseif e.source.objectType == tes3.objectType.enchantment and (e.source.castType == 1 or e.source.castType == 2) then EnchantCast(e.source.chargeCost) end
	if MEF[e.source.effects[1].id] == "shotgun" then Drobash(e.source) elseif MEF[e.source.effects[1].id] == "ray" then RayAllah(e.source) elseif MEF[e.source.effects[1].id] == "discharge" then end
end end


local function onEquipped(e) if e.reference == p and e.item.objectType == tes3.objectType.weapon then
	if e.item.enchantment and e.item.type < 11 and e.item.enchantment.castType == 1 then
		timer.delayOneFrame(function() EW.ob = mp.readiedWeapon.object		EW.v = mp.readiedWeapon.variables	EW.en = EW.ob.enchantment	EW.BAR.visible = true	EW.bar.max = EW.en.maxCharge end)
		for i, eff in ipairs(e.item.enchantment.effects) do if eff.rangeType == 2 or MEF[eff.id] == "shotgun" or MEF[eff.id] == "ray" then
			B.ES.effects[i].id = eff.id		B.ES.effects[i].min = eff.min	B.ES.effects[i].max = eff.max	B.ES.effects[i].duration = eff.duration		B.ES.effects[i].radius = eff.radius
			B.ES.effects[i].rangeType = eff.rangeType	B.ES.effects[i].attribute = eff.attribute	B.ES.effects[i].skill = eff.skill
		else B.ES.effects[i].id = -1 end end
		if B.ES.effects[1].id ~= -1 then D.ESWID = e.item.id		if msg then tes3.messageBox("%s Equipped. Charge cost = %.1f", D.ESWID, e.item.enchantment.chargeCost) end
		B.ES.icon = e.item.enchantment.chargeCost > ENPC.max/100 and "s\\b_chargeFrost.tga" or "s\\b_chargeShock.tga" end
	end
end end

local function onUnequipped(e) if e.reference == p then if e.item == EW.ob then EW.ob = nil	EW.BAR.visible = false end
	if e.item.id == D.ESWID then D.ESWID = nil elseif e.item.enchantment and e.item.enchantment.castType == 3 then ConstEnLim() end
end end

local function onItemDropped(e) if BAM[e.reference.object.id] then e.reference:disable()	mwscript.setDelete{reference = e.reference}		if msg then tes3.messageBox("Ammo unbound") end
elseif wc.inputController:isKeyDown(cfg.telkey.keyCode) then TELnew(e.reference) end end

--local function onActivate(e) if e.activator == p and wc.inputController:isKeyDown(cfg.telkey.keyCode) and e.target ~= TER then TELnew(e.target)	return false end end


local function onAttack(e)
if e.reference == p and mp.readiedWeapon then W = mp.readiedWeapon
	if W.object.id == D.ESWID and W.variables.charge > W.object.enchantment.chargeCost then
		W.variables.charge = W.variables.charge - W.object.enchantment.chargeCost * (1 - mp:getSkillValue(9)/250)	EnchantCast(W.object.enchantment.chargeCost)	mwscript.equip{reference = p, item = B.ES}
	end
	if W.object.type > 8 and mp.readiedAmmo and BAM[mp.readiedAmmo.object.id] then BAM.am = mp.readiedAmmo.object.id
		if tes3.isAffectedBy{reference = p, effect = 601} then BAM.en.effects[1].id = MID[math.random(3)]
			BAM.en.effects[1].min = math.random(5) + mp:getSkillValue(10)/20	BAM.en.effects[1].max = BAM.en.effects[1].min*2		BAM.en.effects[1].radius = math.random(5) + mp:getSkillValue(11)/20
			if cfg.autoammo and mp.magicka.current > 15 then	mp.readiedAmmoCount = 2		tes3.addItem{reference = p, item = BAM.am, count = 1, playSound = false}
				tes3.modStatistic{reference = p, name = "magicka", current = - Kcost(15,3,mp,13,14)}
			end
		end
	end
end

if e.reference.data.CW and (e.reference ~= p or (DM.cw and not (cfg.smartcw and mp.readiedWeapon and mp.readiedWeapon.object.type > 8))) then timer.delayOneFrame(function() mc = CWMag(e.reference, e.reference == p and 1.5 or 0.5)
	if mc == 0 then e.reference.data.CW = nil elseif e.mobile.magicka.current > mc then CWR = e.mobile:getSkillValue(11)/20
		for i, m in ipairs(CWM) do if m > 0 then B.DC.effects[i].id = MID[i]  B.DC.effects[i].min = m   B.DC.effects[i].max = m		B.DC.effects[i].radius = m^0.5 + CWR	B.DC.effects[i].duration = 1	B.DC.effects[i].rangeType = 2
		else B.DC.effects[i].id = -1 end end	mwscript.equip{reference = e.reference, item = B.DC}		tes3.modStatistic{reference = e.reference, name = "magicka", current = -mc}
		if msg then tes3.messageBox("DC = %d + %d + %d + %d + %d   Manacost = %.1f", CWM[1], CWM[2], CWM[3], CWM[4], CWM[5], mc) end
	end
end) end
end


local function onHit(e) if e.attacker == p and e.attacker.data.CW and (not DM.cw or (cfg.smartcw and mp.readiedWeapon and mp.readiedWeapon.object.type > 8)) then mc = CWMag(e.attacker, 1)
	if mc == 0 then e.attacker.data.CW = nil elseif e.attackerMobile.magicka.current > mc then
		for i, m in ipairs(CWM) do if m > 0 then B.CW.effects[i].id = MID[i]  B.CW.effects[i].min = m   B.CW.effects[i].max = m   B.CW.effects[i].duration = 1 else B.CW.effects[i].id = -1 end end
		mwscript.equip{reference = e.target, item = B.CW}		tes3.modStatistic{reference = e.attacker, name = "magicka", current = -mc}
		if msg then tes3.messageBox("CW = %d + %d + %d + %d + %d   Manacost = %.1f", CWM[1], CWM[2], CWM[3], CWM[4], CWM[5], mc) end
	end
end end


local function onProjectileExpire(e) if TEP and TEP == e.mobile.reference then	local dist, dmg, tcell		local p1 = e.mobile.position + e.mobile.velocity * 0.7 * wc.deltaTime
	for c, _ in pairs(Acells) do if c.gridX == math.floor(p1.x/8192) and c.gridY == math.floor(p1.y/8192) then tcell = c	break end end		if not tcell then tcell = p.cell end
	for ref in tes3.iterate(tcell.actors) do dist = p1:distance(ref.position + tes3vector3.new(0, 0, ref.mobile.height/2))		if ref.mobile and not ref.mobile.isDead and dist < 30 + ref.mobile.height*0.7 then
		dmg = TEdmg * Cpower(mp, 11, 11)/100	dmg = dmg * dmg / (dmg + Armor(ref.mobile, 0.5))	ref.mobile:applyHealthDamage(dmg)	if dmg > 5 then tes3.playSound{reference = ref, sound = "critical damage"} end
		if ref.mobile.inCombat == false then mwscript.startCombat{reference = ref, target = p} end		if msg then tes3.messageBox("DAMAG = %.1f (%.1f)   dist = %d", dmg, TEdmg, dist) end
	end end		TEP = nil	TEmod = 3
end end

local CPR = {}		local CPRS = {}		local CPS = {0,0,0,0,0,0,0,0,0,0}
local function onObjectInvalidated(e)
	if CPR[e.object] then CPR[e.object] = nil elseif CPRS[e.object] then CPS[CPRS[e.object].n] = 0	CPRS[e.object] = nil end
	if e.object == TPproj then TPproj = nil end
	if e.object == TER then if msg then tes3.messageBox("Telekinesis: Extra Stop") end	event.unregister("simulate", SIMTEL)	TER = nil	TEP = nil	TEmod = nil end
	if DER[e.object] then DER[e.object] = nil tes3.messageBox("INVALID") end
end


local CPfr, CPScd, hit, CPV, CPE, hpos, ppos		local CPG = 0
local function SimulateCP(e)	dt = wc.deltaTime	CPfr = CPfr + 1		CPE = tes3.getPlayerEyePosition()	CPV = tes3.getPlayerEyeVector()		hit = tes3.rayTest{position = CPE, direction = CPV}
	if hit then hpos = hit.intersection		hpos.z = hpos.z - 15	else hpos = CPE + CPV * 4800 end
	for r, t in pairs(CPR) do t.tim = t.tim - dt
		if t.tim < 0 then CPR[r] = nil
		elseif t.mod == 1 then t.pos = t.pos:interpolate(hpos, 1500*dt)	r.position = t.pos
		elseif t.mod == 0 then t.pos = t.pos + CPV*1500*dt		r.position = t.pos		if CPfr == 100 then r.orientation = p.orientation	CPfr = 0 end
		elseif t.mod == 2 then t.post = t.tar.position:copy()	t.post.z = t.post.z + 100	t.pos = t.pos:interpolate(t.post, 1000*dt)	r.position = t.pos end
	end		if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	CPfr = nil end
end

local function SimulateCPS(e)	ppos = p.position:copy()	dt = wc.deltaTime		CPG = CPG + 4*dt
	for r, t in pairs(CPRS) do CPS[t.n] = CPS[t.n] - dt
		if CPS[t.n] < 0 then CPS[t.n] = 0	CPRS[r] = nil	else r.position = {ppos.x + math.cos(CPG + t.n*math.pi/5) * t.rad, ppos.y + math.sin(CPG + t.n*math.pi/5) * t.rad, ppos.z + 100} end
	end		if table.size(CPRS) == 0 then event.unregister("simulate", SimulateCPS)		CPScd = nil		CPG = 0		if msg then tes3.messageBox("Spin-timer end!") end end
end

local function onMobileActivated(e) if e.mobile and e.mobile.firingMobile and e.mobile.firingMobile == mp then -- только e.mobile.flags есть
if tes3.isAffectedBy{reference = p, effect = 506} and mp.magicka.current > 10 then	local live = 8 * mp.fatigue.normalized + (mp.willpower.current + mp.intelligence.current + mp:getSkillValue(11))/25		mc = 4
	if e.mobile.spellInstance then
		if DM.cp == 3 then mc = 8		timer.delayOneFrame(function() e.reference.position = hitp() end)
		elseif DM.cp == 2 then	if CPScd == nil then event.register("simulate", SimulateCPS)	CPScd = true end	local num = 1	md = CPS[1]		for i, tim in ipairs(CPS) do if tim < md then num = i	md = tim end end 
			CPS[num] = live*1.5		for r, t in pairs(CPRS) do if t.n == num then CPRS[r] = nil	break end end		CPRS[e.reference] = {n = num, rad = 200 + e.mobile.spellInstance.source.effects[1].radius * 6}
			if msg then tes3.messageBox("Ball %s  Time = %d  Rad = %d  Balls = %s   Live = %d %d %d %d %d %d %d %d %d %d", num, CPS[num], CPRS[e.reference].rad, table.size(CPRS), CPS[1], CPS[2], CPS[3], CPS[4], CPS[5], CPS[6], CPS[7], CPS[8], CPS[9], CPS[10]) end
		else	if e.mobile.spellInstance.source.name and (e.mobile.spellInstance.source.name == "4b_RAY" or e.mobile.spellInstance.source.name == "4b_SG") then return end		local tar
			if DM.cp == 1 then local mindist = 8000
				if cfg.agr then for r in tes3.iterate(p.cell.actors) do if r.mobile.isDead == false and mindist > p.position:distance(r.position) then mindist = p.position:distance(r.position)	tar = r end end
				else for mob in tes3.iterate(mp.hostileActors) do if mindist > p.position:distance(mob.position) then mindist = p.position:distance(mob.position)	tar = mob end end end
			end		if CPfr == nil then event.register("simulate", SimulateCP)	CPfr = 0 end	
			if tar then mc = 10	CPR[e.reference] = {mod = 2, tim = live, pos = tes3.getPlayerEyePosition(), tar = tar}
			elseif DM.cpt then mc = 6		CPR[e.reference] = {mod = 1, tim = live, pos = tes3.getPlayerEyePosition()}
			else	CPR[e.reference] = {mod = 0, tim = live, pos = tes3.getPlayerEyePosition()} end
		end
	else if CPfr == nil then event.register("simulate", SimulateCP)	CPfr = 0 end	mc = 6	CPR[e.reference] = {mod = 0, tim = live, pos = e.reference.position:copy()} end
	tes3.modStatistic{reference = p, name = "magicka", current = - Kcost(mc,2,mp,11,14)}
	if TEmod == 1 and mp.magicka.current > TEcost then mc = Kcost(TEcost,2,mp,11,14)		tes3.modStatistic{reference = p, name = "magicka", current = -mc}
		TEP = e.reference	TEmod = 2	tes3.playSound{reference = ref, sound = "enchant success"}
		if msg then tes3.messageBox("Telekinetic throw! Cost = %.1f (%.1f base)", mc, TEcost) end
	end
end
if e.mobile.spellInstance and e.mobile.spellInstance.source.effects[1].id == 500 then TPproj = e.reference		TPmod = 1 end
end end


local function onDeactDeath(e)
	if AF[e.reference].tremor then AF[e.reference].tremor:cancel()	if e.reference.mobile and e.reference.mobile.paralyze > 0 then e.reference.mobile.paralyze = 0 end end		AF[e.reference] = nil 
end

local function onLoad(e)
	if AOE.Tim and AOE.Tim.timeLeft then for i, t in ipairs(AOE) do if t.r then t.r:disable()	t.r.modified = false end end end
	if RUN.Tim and RUN.Tim.timeLeft then for i, t in ipairs(RUN) do if t.r then t.r:deleteDynamicLightAttachment()	t.r:disable()	t.r.modified = false end end end
	if Tot.Tim and Tot.Tim.timeLeft then for i, t in ipairs(Tot) do if t.r then t.r:deleteDynamicLightAttachment()	t.r:disable()	t.r.modified = false end end end
	if table.size(LTRef) ~= 0 then	for ref, _ in pairs(LTRef) do ref:disable()	ref.modified = false end  LTRef = {}	LTS = nil end
	if T.TS.timeLeft then event.unregister("simulate", SIMTS)	TSK = 1 end
	if T.Frost.timeLeft then event.unregister("calcMoveSpeed", CMSFrost) end
	if TEmod then event.unregister("simulate", SIMTEL)	TER = nil	TEP = nil	TEmod = nil end
	if T.DET.timeLeft then DEDEL() end
end

local BlackAmmo = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true}		local MStat
local function onFilterInventory(e) if BlackAmmo[e.item.id] and MStat and MStat.visible == false then return false end end

local function onCellChanged(e) Acells = {}		for _, cell in pairs(tes3.getActiveCells()) do Acells[cell] = true end
	if TEmod and e.previousCell and (e.cell.isInterior or e.previousCell.isInterior) then p:activate(TER)	event.unregister("simulate", SIMTEL)	TER = nil	TEP = nil	TEmod = nil end
end

local function onLoaded(e) -- BN(var, range, eff, min, max, rad, dur, icon)			SN(var, range, eff, min, max, rad, dur, cost, name)
AF = setmetatable({}, MT)		p = tes3.player		mp = tes3.mobilePlayer		D = tes3.player.data		if not D.Mmod then D.Mmod = {} end	DM = D.Mmod		SI = {}

BREG("Q","CW","DC","ES","RF","RFS","RAY","SG","PR","aura1","aura2","aura3","aura4","aura5","aoe1","aoe2","aoe3","aoe4","aoe5")
SREG("DC","CWT","rune1","rune2","rune3","rune4","rune5","rune0","totem1","totem2","totem3","totem4","totem5","totem0")
DA = {{b = B.aura1}, {b = B.aura2}, {b = B.aura3}, {b = B.aura4}, {b = B.aura5}}	AOE = {{b = B.aoe1}, {b = B.aoe2}, {b = B.aoe3}, {b = B.aoe4}, {b = B.aoe5}, Tim = timer}
RUN = {{s = S.rune1}, {s = S.rune2}, {s = S.rune3}, {s = S.rune4}, {s = S.rune5}, exp = S.rune0, Tim = timer}	Tot = {{s = S.totem1}, {s = S.totem2}, {s = S.totem3}, {s = S.totem4}, {s = S.totem5}, exp = S.totem0, Tim = timer}
local MU = tes3ui.findMenu(-526)	MStat = tes3ui.findMenu(-855)
QIC = MU:findChild(-539).parent:createThinBorder{}
QIC.visible = true	QIC.autoHeight = true	QIC.autoWidth = true	QIC.paddingAllSides = 2		QIC.borderAllSides = 2		QIC.flowDirection = "top_to_bottom"		Qicon = QIC:createImage{path = "icons/k/magicka.dds"}
Qicon:register("help", function() if QS then local qtt = tes3ui.createTooltipMenu():createBlock{}	qtt.autoHeight = true	qtt.autoWidth = true	qtt:createLabel{text = QS.name .. "  (" .. QS.magickaCost .. ")"} end end)
local Qbar = QIC:createFillBar{current = 20, max = 20}	Qbar.width = 32		Qbar.height = 6		QB = Qbar.widget	QB.showText = false		QB.fillColor = {0,255,0}
MU:findChild(-573).parent.flowDirection = "top_to_bottom"
Bar4 = MU:findChild(-573).parent:createFillBar{current = 0, max = (mp.willpower.base*10 + mp.enchant.base*10) * (1 - (D.ENconst or 0)/(5000 + mp.enchant.base*30)/2)}	ENPC = Bar4.widget
Bar4.visible = false	Bar4.widget.showText = false	Bar4.width = 65		Bar4.height = 12	ENPC.fillColor = {128,0,255}	if D.ENvol then ENPC.current = D.ENvol	EnchantCast(21) else ENPC.current = ENPC.max end

if not D.QSP then D.QSP = {} end
QS = D.QSP["0"] and tes3.getObject(D.QSP[D.QSP["0"]]) or (mp.currentSpell and mp.currentSpell.objectType == tes3.objectType.spell and mp.currentSpell.castType == 0 and mp.currentSpell)
if QS then for i, eff in ipairs(QS.effects) do B.Q.effects[i].id = eff.id		B.Q.effects[i].min = eff.min	B.Q.effects[i].max = eff.max
	B.Q.effects[i].duration = eff.duration		B.Q.effects[i].radius = eff.radius		B.Q.effects[i].rangeType = eff.rangeType		B.Q.effects[i].attribute = eff.attribute		B.Q.effects[i].skill = eff.skill
end		Qicon.contentPath = "icons/s/b_" .. QS.effects[1].object.icon:sub(3) end

EW = {}		EW.BAR = MU:findChild(-547):createFillBar{current = 10, max = 10}	EW.BAR.width = 36	EW.BAR.height = 7	EW.bar = EW.BAR.widget	EW.bar.showText = false	EW.bar.fillColor = {0,255,255}	EW.BAR.visible = false
EW.tim = timer.start{duration = 1, iterations = -1, callback = function() if EW.ob then EW.bar.current = EW.v.charge end end}
if mp.readiedWeapon and mp.readiedWeapon.object.enchantment and mp.readiedWeapon.object.enchantment.castType == 1 and mp.readiedWeapon.object.type < 11 then
EW.ob = mp.readiedWeapon.object		EW.v = mp.readiedWeapon.variables	EW.en = EW.ob.enchantment	EW.BAR.visible = true	EW.bar.max = EW.en.maxCharge end

local MCbar = MU:findChild(-548):createFillBar{current = 0, max = 100}	MCbar.width = 36	MCbar.height = 7	MCB = MCbar.widget	MCB.showText = false	MCB.fillColor = {0,255,128}	--MCbar.visible = false
M = tes3.loadMesh("e\\magef.nif")
arm1 = mp.firstPersonReference.sceneNode:getObjectByName("Bip01 R Finger2")	arm1:attachChild(M:clone(), true)	arm1 = arm1:getObjectByName("magef")	arm1.appCulled = true
arm2 = mp.firstPersonReference.sceneNode:getObjectByName("Bip01 L Finger2")	arm2:attachChild(M:clone(), true)	arm2 = arm2:getObjectByName("magef")	arm2.appCulled = true

if cfg.Arch then	local LV = cfg.Lvol	local MM = tes3ui.findMenu(-434)	local PL = MM:findChild(-441)	PL.flowDirection = "left_to_right"		local SL = MM:findChild(-444)	local ML = math.ceil(#SL.children/LV)
	MM:findChild(-1155).children[1].visible = false		MM:findChild(-1155).children[4].visible = false		MM:findChild(-442).visible = false		MM:findChild(-445).visible = false		MM:findChild(-446).visible = false
	for i, s in ipairs(PL.children) do s:createImage{path = "icons/s/b_" .. s:getPropertyObject("MagicMenu_Spell").effects[1].object.icon:sub(3)}	s.minHeight = 32	s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil end
	SL.minWidth = 32*(LV+1)		SL.maxWidth = SL.minWidth	SL.minHeight = 32*(ML+1)	SL.maxHeight = SL.minHeight		SL.autoHeight = true	SL.autoWidth = true
	for i, s in ipairs(SL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil	s:createImage{path = "icons/s/b_" .. s:getPropertyObject("MagicMenu_Spell").effects[1].object.icon:sub(3)}	
	s.absolutePosAlignX = 1/LV * ((i%LV > 0 and i%LV or LV)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/LV)-1) end
end

if tes3.getObject("4s_602") == nil or tes3.getObject("4s_541").effects[1].radius ~= 5 then tes3.messageBox("New effects and spells updated")	SN(600,0,600,10,20,0,10,10,"Dash")		SN(500,2,500,0,0,0,0,10,"Teleport")
SN(501,0,501,5,10,0,5,30,"Recharge")		SN(502,0,502,10,20,0,5,30,"Repair weapon")	SN(503,0,503,20,30,0,5,30,"Repair armor")		SN(504,2,504,4,6,0,60,3,"Lantern")				SN(505,0,505,0,0,0,0,100,"Town teleport")
SN(506,0,506,0,0,0,60,5,"Magic control")	SN(507,0,507,10,20,0,30,20,"Reflect spells") SN(508,0,508,5,10,0,30,20,"Kinetic shield")	SN(509,0,509,20,30,0,20,20,"Life leech")		SN(510,0,510,20,30,0,10,20,"Time shift")
SN(601,0,601,0,0,0,60,5,"Bound ammo")		SN(602,2,602,20,30,30,0,10,"Kinetic strike") SN("504a",0,504,8,10,0,60,5,"Lantern magic")
SN(511,0,511,5,15,0,30,10,"Charge fire")	SN(512,0,512,5,15,0,30,10,"Charge frost")	SN(513,0,513,5,15,0,30,10,"Charge lightning")	SN(514,0,514,5,15,0,30,10,"Charge poison")		SN(515,0,515,5,15,0,30,10,"Charge magic")
SN(516,0,516,5,10,20,15,30,"Aura fire")		SN(517,0,517,5,10,20,15,30,"Aura frost")	SN(518,0,518,5,10,20,15,40,"Aura lightning")	SN(519,0,519,5,10,20,15,50,"Aura poison")		SN(520,0,520,5,10,20,15,40,"Aura magic")
SN(521,2,521,5,15,20,10,30,"AoE fire")		SN(522,2,522,5,15,20,10,30,"AoE frost")		SN(523,2,523,5,15,20,10,40,"AoE lightning")		SN(524,2,524,5,15,20,10,50,"AoE poison")		SN(525,2,525,5,15,20,10,40,"AoE magic")
SN(526,2,526,30,70,15,1,15,"Rune fire")		SN(527,2,527,30,70,15,1,15,"Rune frost")	SN(528,2,528,30,70,15,1,20,"Rune lightning")	SN(529,2,529,30,70,15,1,25,"Rune poison")		SN(530,2,530,30,70,15,1,20,"Rune magic")
SN(531,0,531,10,20,0,20,10,"Prok fire")		SN(532,0,532,10,20,0,20,10,"Prok frost")	SN(533,0,533,10,20,0,20,10,"Prok lightning")	SN(534,0,534,10,20,0,20,10,"Prok poison")		SN(535,0,535,10,20,0,20,10,"Prok magic")
SN(536,1,536,10,30,10,1,30,"Spread fire")	SN(537,1,537,10,30,10,1,30,"Spread frost")	SN(538,1,538,10,30,10,1,40,"Spread lightning")	SN(539,1,539,10,30,10,1,50,"Spread poison")		SN(540,1,540,10,30,10,1,40,"Spread magic")
SN(541,0,541,10,30,5,3,30,"Discharge fire")	SN(542,0,542,10,30,5,3,30,"Discharge frost") SN(543,0,543,10,30,5,3,40,"Discharge lightning") SN(544,0,544,10,30,5,3,50,"Discharge poison")	SN(545,0,545,10,30,5,3,40,"Discharge magic")
SN(546,1,546,5,15,5,1,30,"Ray fire")		SN(547,1,547,5,15,5,1,30,"Ray frost")		SN(548,1,548,5,15,5,1,40,"Ray lightning")		SN(549,1,549,5,15,5,1,50,"Ray poison")			SN(550,1,550,5,15,5,1,40,"Ray magic")
SN(551,2,551,10,20,5,20,10,"Totem fire")	SN(552,2,552,10,20,5,20,10,"Totem frost")	SN(553,2,553,10,20,5,20,10,"Totem lightning")	SN(554,2,554,10,20,5,20,10,"Totem poison")		SN(555,2,555,10,20,5,20,10,"Totem magic")
SN(556,0,556,10,20,0,30,30,"Empower fire")	SN(557,0,557,10,20,0,30,30,"Empower frost")	SN(558,0,558,10,20,0,30,30,"Empower lightning")	SN(559,0,559,10,20,0,30,30,"Empower poison")	SN(560,0,560,10,20,0,30,30,"Empower magic")
SN(561,0,561,10,20,0,30,20,"Reflect fire")	SN(562,0,562,10,20,0,30,20,"Reflect frost")	SN(563,0,563,10,20,0,30,20,"Reflect lightning")	SN(564,0,564,10,20,0,30,20,"Reflect poison")	SN(565,0,565,10,20,0,30,20,"Reflect magic")
end

local SFS = {500,501,502,503,504,"504a",505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,
551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,600,601,602}
if p.cell.id == "Balmora, Guild of Mages" then for _, num in ipairs(SFS) do mwscript.addSpell{reference = "marayn dren", spell = "4s_"..num} end end
if cfg.testmod then for _, num in ipairs(SFS) do mwscript.addSpell{reference = p, spell = "4s_"..num} end	tes3.messageBox("All new spells received")	cfg.testmod = false end
msg = cfg.msg	msg1 = cfg.msg1		msg2 = cfg.msg2
tes3.findGMST("fMagicItemRechargePerSecond").value = 0.05 + mp.enchant.base/2000
end


local MVSME = {["tx_s_water_breath"] = 30,["tx_s_swiftswim"] = 10,["tx_s_water_walk"] = 10,["tx_s_jump"] = 5,["tx_s_levitate"] = 5,["tx_s_slowfall"] = 10,["tx_s_chameleon"] = 10,["tx_s_charm"] = 10,["tx_s_soultrap"] = 10,
["tx_s_drain_attrib"] = 10,["tx_s_drain_fati"] = 10,["tx_s_drain_health"] = 10,["tx_s_drain_magic"] = 10,["tx_s_drain_skill"] = 10,["tx_s_cmd_crture"] = 10,["tx_s_cmd_hunoid"] = 10,["tx_s_turn_undead"] = 10,
["tx_s_sanctuary"] = 10,["tx_s_detect_animal"] = 10,["tx_s_detect_enchtmt"] = 10,["tx_s_detect_key"] = 10,
["tx_s_wknstofire"] = 10,["tx_s_wknstofrost"] = 10,["tx_s_wknstoshock"] = 10,["tx_s_wknstopoison"] = 10,["tx_s_wknstomagic"] = 10,["tx_s_wknstonmlwpns"] = 10,["tx_s_wknstoblghtdise"] = 10,["tx_s_wknstocomdise"] = 10,["tx_s_wknstocpsdise"] = 10,
["tx_s_rst_fire"] = 10,["tx_s_rst_frost"] = 10,["tx_s_rst_shock"] = 10,["tx_s_rst_poison"] = 10,["tx_s_rst_magic"] = 10,["tx_s_rst_nmlwpn"] = 10,["tx_s_rst_bghtdise"] = 10,["tx_s_rst_comdise"] = 10,["tx_s_rst_cpsdise"] = 10,
["tx_s_cm_crture"] = 10,["tx_s_cm_hunoid"] = 10,["tx_s_demorl_crture"] = 10,["tx_s_demorl_hunoid"] = 10,["tx_s_frzy_crture"] = 10,["tx_s_frzy_hunoid"] = 10,["tx_s_rlly_crture"] = 10,["tx_s_rlly_hunoid"] = 10,
["tx_s_ftfy_attack"] = 10,["tx_s_ftfy_attrib"] = 10,["tx_s_ftfy_fati"] = 10,["tx_s_ftfy_health"] = 10,["tx_s_ftfy_magic"] = 10,["tx_s_ftfy_mgcmtplr"] = 10,["tx_s_ftfy_skill"] = 10,["tx_s_ab_attrib"] = 10,["tx_s_ab_skill"] = 10,
["tx_s_smmn_anctlght"] = 20,["tx_s_smmn_bear"] = 20,["tx_s_smmn_bnlord"] = 20,["tx_s_smmn_bonewolf"] = 20,["tx_s_smmn_clnfear"] = 20,["tx_s_smmn_daedth"] = 20,["tx_s_smmn_drmora"] = 20,["tx_s_smmn_fabrict"] = 20,
["tx_s_smmn_flmatrnh"] = 20,["tx_s_smmn_frstatrnh"] = 20,["tx_s_smmn_gldsaint"] = 20,["tx_s_smmn_grtrbnwlkr"] = 20,["tx_s_smmn_hunger"] = 20,["tx_s_smmn_lstbnwlkr"] = 20,["tx_s_smmn_scamp"] = 20,["tx_s_smmn_skltlmnn"] = 20,
["tx_s_smmn_stmatnh"] = 20,["tx_s_smmn_wngtwlght"] = 20,["tx_s_smmn_wolf"] = 20,
["sum_lich"] = 20,["sum_mazken"] = 20,["sum_ogrim"] = 20,["sum_skaafin"] = 20,["sum_skeleton_mage"] = 20,["sum_xivkyn"] = 20,["lifeleech"] = 10,["recharge"] = 10,["repairarmor"] = 10,["repairweapon"] = 10}
local MSVI, MSVD	local MSVB = {[-782] = "MenuSetValues_Cancelbutton", [-783] = "MenuSetValues_OkButton", [-784] = "MenuSetValues_Deletebutton", [4294934581] = "click"}
local function MSVOK(e)
	if e.block.id == -783 and MSVB[e.property] then if MSVD.widget.current < (MVSME[MSVI.contentPath:sub(9,-5):lower()] or 0) then tes3.messageBox("Minimum duration = %s", MVSME[MSVI.contentPath:sub(9,-5):lower()]) return false end end
	if MSVB[e.block.id] and MSVB[e.property] then event.unregister("uiPreEvent", MSVOK) end
end
local function onMenuSetValues(e) MSVD = e.element:findChild(-789)	if MSVD then MSVI = e.element:findChild(-32588) event.register("uiPreEvent", MSVOK) end end
local function SpellTooltip(e) local tt = e.tooltip:findChild(tes3ui.registerID("helptext"))	tt.text = tt.text .. " (" .. e.spell.magickaCost .. ")" end
--local function onSimulate() fr0 = fr0 + 1 end
--local function TICRecharge(e)if wc.lastFrameTime - lt > 1000 then tes3.messageBox("tick id = %s    si = %s   delta = %s ", e.effectId, e.sourceInstance.serialNumber, e.deltaTime) end end

local function registerModConfig()		local template = mwse.mcm.createTemplate("4NM_MAGIC_8!")	template:saveOnClose("4NM_MAGIC_8!", cfg)		template:register()		local page = template:createPage()
page:createYesNoButton{label = "Show messages. Requires loading save", variable = mwse.mcm.createTableVariable{id = "msg", table = cfg}}
page:createYesNoButton{label = "Show power messages", variable = mwse.mcm.createTableVariable{id = "msg1", table = cfg}}
page:createYesNoButton{label = "Show affect messages", variable = mwse.mcm.createTableVariable{id = "msg2", table = cfg}}
page:createYesNoButton{label = "Allow accelerated spell cast if your agility is above 80", variable = mwse.mcm.createTableVariable{id = "acscast", table = cfg}}
page:createYesNoButton{label = "Agressive mode for your auras, totems and homing projectiles", variable = mwse.mcm.createTableVariable{id = "agr", table = cfg}}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "tpkey", table = cfg}, label = "Quick teleport key. Press with Control to switch secondary teleportation mode. Press with Alt to turn off/on the dimming of the screen when teleporting"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "cpkey", table = cfg}, label = "Projectile control mode key. Press with move buttons to switch modes. Press with Alt to turn off/on the Smart target mode"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "reflkey", table = cfg}, label = "Reflect mode key. Press this key to turn reflect/manashield mode for your reflect spells"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "telkey", table = cfg}, label = "Telekinetic Throw key. Hold while activating or dropping weapons. Press to return weapon"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "cwkey", table = cfg}, label = "Charge weapon key. Press with Alt to turn effect mode."}
page:createYesNoButton{label = "Charged weapon: smart mode for range weapons", variable = mwse.mcm.createTableVariable{id = "smartcw", table = cfg}}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "detkey", table = cfg}, label = "Use magic vision for detection"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "markkey", table = cfg}, label = "Key for select mark for recall"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "ammokey", table = cfg}, label = "Key for replenishment of bound ammo. Press with Alt if you have a bug with cast animation"}
page:createYesNoButton{label = "Automatic replenishment of bound ammo", variable = mwse.mcm.createTableVariable{id = "autoammo", table = cfg}}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "magkey", table = cfg}, label = "Key for quick cast. Press slot key with Shift to assign the current spell to this quick cast slot"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q1", table = cfg}, label = "Quick cast slot #1"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q2", table = cfg}, label = "Quick cast slot #2"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q3", table = cfg}, label = "Quick cast slot #3"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q4", table = cfg}, label = "Quick cast slot #4"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q5", table = cfg}, label = "Quick cast slot #5"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q6", table = cfg}, label = "Quick cast slot #6"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q7", table = cfg}, label = "Quick cast slot #7"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q8", table = cfg}, label = "Quick cast slot #8"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q9", table = cfg}, label = "Quick cast slot #9"}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "q0", table = cfg}, label = "Universal quick cast slot. If selected, the current spell will always be prepared for a quick cast"}
page:createSlider{label = "Set color saturation of magic lights (0 = maximum colorfulness, 255 = full white)", min = 0, max = 255, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "col", table = cfg}}
page:createYesNoButton{label = "Enable constant enchantments limit", variable = mwse.mcm.createTableVariable{id = "enchlim", table = cfg}}
page:createYesNoButton{label = "Enable minimum duration for homemade spells. Requires game restart", variable = mwse.mcm.createTableVariable{id = "durlim", table = cfg}}
page:createYesNoButton{label = "Enable ArchMage's menu. Requires loading save", variable = mwse.mcm.createTableVariable{id = "Arch", table = cfg}}
page:createSlider{label = "Set number of icons on 1 line in the ArchMage's menu", min = 10, max = 50, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "Lvol", table = cfg}}
page:createYesNoButton{label = "Play sound of magic concentration (hold Left Mouse Button for concentrate power)", variable = mwse.mcm.createTableVariable{id = "mcs", table = cfg}}
page:createYesNoButton{label = "Replace scroll icons with beautiful ones. Requires game restart", variable = mwse.mcm.createTableVariable{id = "scroll", table = cfg}}
page:createYesNoButton{label = "Get all new spells on next save load. Otherwise, you must load the save in the Balmora Mages Guild so that new spells appear on sale at Marain Dren", variable = mwse.mcm.createTableVariable{id = "testmod", table = cfg}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)
tes3.findGMST("fNPCbaseMagickaMult").value = 3			tes3.findGMST("iAutoSpellTimesCanCast").value = 5		tes3.findGMST("iAutoSpellConjurationMax").value = 3		tes3.findGMST("iAutoSpellDestructionMax").value = 15
tes3.findGMST("fTargetSpellMaxSpeed").value = 2000		tes3.findGMST("fMagicCreatureCastDelay").value = 0
tes3.findGMST("fFatigueSpellBase").value = 0.5			tes3.findGMST("fFatigueSpellMult").value = 0.5			tes3.findGMST("fElementalShieldMult").value = 1
event.register("spellResist", onSpellResist)
event.register("magicCasted", onMagicCasted)
event.register("attack", onAttack)
event.register("calcHitChance", onHit)
event.register("equipped", onEquipped)
event.register("unequipped", onUnequipped)
event.register("itemDropped", onItemDropped)
--event.register("activate", onActivate)
event.register("filterInventory", onFilterInventory)
event.register("mobileActivated", onMobileActivated)
event.register("projectileExpire", onProjectileExpire)
event.register("mobileDeactivated", onDeactDeath)
event.register("death", onDeactDeath)
event.register("objectInvalidated", onObjectInvalidated)
event.register("cellChanged", onCellChanged)
event.register("loaded", onLoaded)
event.register("load", onLoad)
event.register("keyDown", onKey)
event.register("mouseButtonDown", onMouseButtonDown)
--event.register("simulate", onSimulate)
if cfg.durlim then event.register("uiActivated", onMenuSetValues, {filter = "MenuSetValues"}) end
event.register("uiSpellTooltip", SpellTooltip)

wc = tes3.worldController	ic = wc.inputController		MB = wc.inputController.mouseState.buttons
BAM.en = tes3.getObject("4nm_e_boundammo")		L = tes3.getObject("4nm_light")
DEO = {["door"] = {m = tes3.loadMesh("e\\detect_door.nif"), s = 3}, ["cont"] = {m = tes3.loadMesh("e\\detect_cont.nif"), s = 3}, ["npc"] = {m = tes3.loadMesh("e\\detect_npc.nif"), s = 1},
["ani"] = {m = tes3.loadMesh("e\\detect_animal.nif"), s = 1}, ["dae"] = {m = tes3.loadMesh("e\\detect_daedra.nif"), s = 1}, ["und"] = {m = tes3.loadMesh("e\\detect_undead.nif"), s = 1},
["robo"] = {m = tes3.loadMesh("e\\detect_robo.nif"), s = 1}, ["key"] = {m = tes3.loadMesh("e\\detect_key.nif"), s = 2}, ["en"] = {m = tes3.loadMesh("e\\detect_ench.nif"), s = 2}}

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
local MEN = {{600, "dash", "Dash", 1, s=4, "Quick teleport to selected direction", c1=0, c2=0}, {601, "boundAmmo", "Bound ammo", 1, s=1, "Bounds arrows, bolts or throwing stars from Oblivion", c1=0, c2=0},
{602, "kineticStrike", "Kinetic strike", 2, s=0, "A burst of power knocks back enemies and deals damage", c0=0, c1=0, nod=1, h=1, snd=2, col = KSCollision},
{500, "teleport", "Teleport", 10, s=4, "Teleports caster to the point, indicated by him", c0=0, c1=0, nod=1, nom=1, sp=2, col = TeleportCollision},	{510, "timeShift", "Time shift", 1, s=3, "Slows perception of time"},
{501, "recharge", "Recharge", 10, s=4, "Restores charges of equipped magic items", ale=0}, {505, "teleportToTown", "Teleport to town", 1000, s=4, "Teleports the caster to the town", c1=0, c2=0, nod=1, nom=1},
{502, "repairWeapon", "Repair weapon", 5, s=0, "Repairing equipped weapon"}, {503, "repairArmor", "Repair armor", 3, s=0, "Repairing equipped armor"},
{504, "lightTarget", "Light on target", 0.1, s=0, "Creates a light, following a caster or attached to hit point", snd=3, vfx=3, col = LightCollision},
{506, "projectileControl", "Projectile control", 1, s=0, "Allows to control projectile flight", c1=0, c2=0, nom=1}, {507, "reflectSpell", "Reflect Spell", 0.5, s=4, "Reflects enemy spells"},
{508, "kineticShield", "Kinetic shield", 1, s=0, "Absorbs physical damage, spending mana", con=1, vfh="VFX_ShieldHit", vfc="VFX_ShieldCast"}, {509, "lifeLeech", "Life leech", 0.5, s=4, "Heals for a portion of your physical damage"},
{511, "chargeFire", "Charge fire", 0.5, s=4, ss=6, "Adds fire damage to attacks", snd=4}, {512, "chargeFrost", "Charge frost", 0.5, s=4, ss=7, "Adds frost damage to attacks", snd=4},
{513, "chargeShock", "Charge shock", 0.5, s=4, ss=8, "Adds shock damage to attacks", snd=4}, {514, "chargePoison", "Charge poison", 0.5, s=4, ss=9, "Adds poison damage to attacks", snd=4},
{515, "chargeVitality", "Charge vitality", 0.5, s=4, ss=10, "Adds vitality damage to attacks", snd=4},
{516, "auraFire", "Aura fire", 3, s=2, ss=6, "Deals fire damage to all enemies around you", con=1, vfh="VFX_FireShield"}, {517, "auraFrost", "Aura frost", 3, s=2, ss=7, "Deals frost damage to all enemies around you", con=1, vfh="VFX_FrostShield"},
{518, "auraShock", "Aura shock", 4, s=2, ss=8, "Deals shock damage to all enemies around you", con=1, vfh="VFX_LightningShield"}, {519, "auraPoison", "Aura poison", 5, s=2, ss=9, "Deals poison damage to all enemies around you", con=1},
{520, "auraVitality", "Aura vitality", 4, s=2, ss=10, "Deals vitality damage to all enemies around you", con=1, vfh="VFX_DefaultHit"},
{521, "aoeFire", "AoE fire", 3, s=2, ss=6, "Deals fire damage to an area", c0=0, c1=0, h=1, col = AOEcol}, {522, "aoeFrost", "AoE frost", 3, s=2, ss=7, "Deals frost damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{523, "aoeShock", "AoE shock", 4, s=2, ss=8, "Deals shock damage to an area", c0=0, c1=0, h=1, col = AOEcol}, {524, "aoePoison", "AoE poison", 5, s=2, ss=9, "Deals poison damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{525, "aoeVitality", "AoE vitality", 4, s=2, ss=10, "Deals vitality damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{526, "runeFire", "Rune fire", 3, s=2, ss=6, "Creates fire rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol}, {527, "runeFrost", "Rune frost", 3, s=2, ss=7, "Creates frost rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{528, "runeShock", "Rune shock", 4, s=2, ss=8, "Creates shock rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol}, {529, "runePoison", "Rune poison", 5, s=2, ss=9, "Creates poison rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{530, "runeVitality", "Rune vitality", 4, s=2, ss=10, "Creates vitality rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{531, "prokFire", "Prok fire", 0.5, s=4, ss=6, "Launch fire ball at regular intervals", c1=0, c2=0, snd=4}, {532, "prokFrost", "Prok frost", 0.5, s=4, ss=7, "Launch frost ball at regular intervals", c1=0, c2=0, snd=4},
{533, "prokShock", "Prok shock", 0.5, s=4, ss=8, "Launch shock ball at regular intervals", c1=0, c2=0, snd=4}, {534, "prokPoison", "Prok poison", 0.5, s=4, ss=9, "Launch poison ball at regular intervals", c1=0, c2=0, snd=4},
{535, "prokVitality", "Prok vitality", 0.5, s=4, ss=10, "Launch vitality ball at regular intervals", c1=0, c2=0, snd=4},
{536, "shotgunFire", "Spread fire", 15, s=2, ss=6, "Shoots a group of fire balls", c0=0, c2=0}, {537, "shotgunFrost", "Spread frost", 15, s=2, ss=7, "Shoots a group of frost balls", c0=0, c2=0},
{538, "shotgunShock", "Spread shock", 20, s=2, ss=8, "Shoots a group of shock balls", c0=0, c2=0}, {539, "shotgunPoison", "Spread poison", 25, s=2, ss=9, "Shoots a group of poison balls", c0=0, c2=0},
{540, "shotgunVitality", "Spread vitality", 20, s=2, ss=10, "Shoots a group of vitality balls", c0=0, c2=0},
{541, "dischargeFire", "Discharge fire", 6, s=2, ss=6, "Attacks everyone around with many fire balls", c2=0}, {542, "dischargeFrost", "Discharge frost", 6, s=2, ss=7, "Attacks everyone around with many frost balls", c2=0},
{543, "dischargeShock", "Discharge shock", 8, s=2, ss=8, "Attacks everyone around with many shock balls", c2=0}, {544, "dischargePoison", "Discharge poison", 10, s=2, ss=9, "Attacks everyone around with many poison balls", c2=0},
{545, "dischargeVitality", "Discharge vitality", 8, s=2, ss=10, "Attacks everyone around with many vitality balls", c2=0},
{546, "rayFire", "Ray fire", 30, s=2, ss=6, "Fires a ray of fire", c0=0, c2=0}, {547, "rayFrost", "Ray frost", 30, s=2, ss=7, "Fires a ray of frost", c0=0, c2=0},
{548, "rayShock", "Ray shock", 40, s=2, ss=8, "Fires a ray of lightning", c0=0, c2=0}, {549, "rayPoison", "Ray poison", 50, s=2, ss=9, "Fires a ray of poison", c0=0, c2=0},
{550, "rayVitality", "Ray vitality", 40, s=2, ss=10, "Fires a ray of vitality magic", c0=0, c2=0},
{551, "totemFire", "Totem fire", 0.5, s=4, ss=6, "Creates a totem that shoots fire at your enemies", c0=0, c1=0, h=1, col = TOTcol}, {552, "totemFrost", "Totem frost", 0.5, s=4, ss=7, "Creates a totem that shoots frost at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{553, "totemShock", "Totem shock", 0.5, s=4, ss=8, "Creates a totem that shoots lightning at your enemies", c0=0, c1=0, h=1, col = TOTcol}, {554, "totemPoison", "Totem poison", 0.5, s=4, ss=9, "Creates a totem that shoots poison at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{555, "totemVitality", "Totem vitality", 0.5, s=4, ss=10, "Creates a totem that shoots magic at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{556, "empowerFire", "Empower fire", 1, s=4, ss=6, "Empower your fire spells", snd=4}, {557, "empowerFrost", "Empower frost", 1, s=4, ss=7, "Empower your frost spells", snd=4},
{558, "empowerShock", "Empower shock", 1, s=4, ss=8, "Empower your shock spells", snd=4}, {559, "empowerPoison", "Empower poison", 1, s=4, ss=9, "Empower your poison spells", snd=4},
{560, "empowerVitality", "Empower vitality", 1, s=4, ss=10, "Empower your vitality spells", snd=4},
{561, "reflectFire", "Reflect fire", 0.5, s=4, ss=6, "Converts enemy spells energy into fire and reflects it", snd=4}, {562, "reflectFrost", "Reflect frost", 0.5, s=4, ss=7, "Converts enemy spells energy into frost and reflects it", snd=4},
{563, "reflectShock", "Reflect shock", 0.5, s=4, ss=8, "Converts enemy spells energy into lightning and reflects it", snd=4}, {564, "reflectPoison", "Reflect poison", 0.5, s=4, ss=9, "Converts enemy spells energy into poison and reflects it", snd=4},
{565, "reflectVitality", "Reflect vitality", 0.5, s=4, ss=10, "Converts enemy spells energy into magic and reflects it", snd=4}}
for _,e in ipairs(MEN) do tes3.claimSpellEffectId(e[2], e[1])	tes3.addMagicEffect{id = e[1], name = e[3], baseCost = e[4], school = e.s, description = e[5] or e[3],
allowEnchanting = not e.ale, allowSpellmaking = not e.als, canCastSelf = not e.c0, canCastTarget = not e.c1, canCastTouch = not e.c2, isHarmful = not not e.h, hasNoDuration = not not e.nod, hasNoMagnitude = not not e.nom,
nonRecastable = not not e.nor, hasContinuousVFX = not not e.con, appliesOnce = false, casterLinked = false, illegalDaedra = false, targetsAttributes = false, targetsSkills = false, unreflectable = false, usesNegativeLighting = false,
castSound = S[e.snd or e.ss or e.s].sc, boltSound = S[e.snd or e.ss or e.s].sb, hitSound = S[e.snd or e.ss or e.s].sh, areaSound = S[e.snd or e.ss or e.s].sa,
castVFX = e.vfc or S[e.vfx or e.ss or e.s].vc, boltVFX = e.vfb or S[e.vfx or e.ss or e.s].vb, hitVFX = e.vfh or S[e.vfx or e.ss or e.s].vh, areaVFX = e.vfa or S[e.vfx or e.ss or e.s].va,
particleTexture = e.p or S[e.ss or e.s].p, icon = "s\\"..e[2]..".tga", speed = e.sp or 1, size = 1, sizeCap = 50, lighting = S[e.ss or e.s].l, onCollision = e.col or nil} end

if cfg.scroll then for b in tes3.iterateObjects(tes3.objectType.book) do if b.type == 1 and b.enchantment then b.icon = "scrolls\\tx_scroll_" .. b.enchantment.effects[1].id .. ".dds" end end end
end		event.register("initialized", initialized)