
local cf = mwse.loadConfig("Shields Up", {m3 = false})
local p, mp
local WT = {[-1]={s=26},
[0]={s=22},
[1]={s=5},
[2]={s=5},
[3]={s=4},
[4]={s=4},
[5]= {s=4},
[6]={s=7},
[7]={s=6},
[8]={s=6},
[9]={s=23},
[10]={s=23},
[11]={s=23}}

local function damage(e) if e.source == "attack" and e.projectile then		local t = e.mobile		local tsh = t.readiedShield	
if tsh then	local tad = t.actionData	local a = e.attacker	local ang = t:getViewToPoint(e.projectile.position)		if (t ~= mp or tad.animationAttackState == 2) and math.abs(ang) < 45 or (ang > -90 and ang < 0) then
	local bloc = (t:getSkillValue(0) + t.agility.current/5 + t.luck.current/10) * math.min(t.fatigue.normalized,1) * 1.5 * ((t ~= mp or tad.animationAttackState == 2) and 1 or 0.3) - a:getSkillValue(23)/2 - a.agility.current/5
	if cf.m3 then tes3.messageBox("Block projectile chance = %d%%   Ang = %d", bloc, ang) end
	if bloc > math.random(100) then tsh.variables.condition = math.max(tsh.variables.condition - e.damage/2, 0)
		if t == mp then mp:exerciseSkill(0, 1) end		if tsh.variables.condition < 0.1 then t:unequip{item = tsh.object} end
		e.damage = 0		tes3.playSound{reference = e.reference, soundPath = ("Fx\\par\\sh_%s.wav"):format(math.random(4))}		return
	end
end end
end end		event.register("damage", damage)


local function CALCBLOCKCHANCE(e)	local a, t = e.attackerMobile, e.targetMobile		local s = t:getSkillValue(0) 	local activ = t.actionData.animationAttackState == 2
local wt = a.readiedWeapon		wt = wt and wt.object.type or -1
local ang = t:getViewToActor(a)			local max = (ang >= 0 and (activ and 30 or 20) or (activ and -30 or -60)) * 1.5
local Kang = math.clamp((1 - ang/max)*1.5, 0, 1)
local Kstam = math.min(math.lerp(0.5, 1, t.fatigue.normalized), 1)
local Ktar = (t == mp and (activ and 100 or 0) or 100) + (s/2 + t.agility.current/5 + t.luck.current/10) * 1.25
local Katak = (a:getSkillValue(WT[wt].s)/2 + a.agility.current/5 + a.luck.current/10) * (1.25 + (1 - a.actionData.attackSwing))
local bloc = Ktar * Kstam * Kang - Katak		local cost = 0
if bloc > math.random(100) then e.blockChance = 100
	local SH = t.readiedShield		cost = SH.object.weight * math.max(0.5 - s/250, 0.1)		if cost > 0 then t.fatigue.current = math.max(t.fatigue.current - cost, 0) end
else e.blockChance = 0 end
if cf.m3 then tes3.messageBox("%s %d%% = %d tar * %d%% stam * %d%% ang (%d/%d) - %d atk  Stam cost +%d", e.blockChance == 100 and "BLOCK!" or "block", bloc, Ktar, Kstam*100, Kang*100, ang, max, Katak, cost) end
end		event.register("calcBlockChance", CALCBLOCKCHANCE)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer	end		event.register("loaded", loaded)

local function initialized(e)
tes3.findGMST("fFatigueBlockBase").value = 5			tes3.findGMST("fFatigueBlockMult").value = 10		tes3.findGMST("fWeaponFatigueBlockMult").value = 2
tes3.findGMST("fCombatBlockLeftAngle").value = -1		tes3.findGMST("fCombatBlockRightAngle").value = 0.5
end		event.register("initialized", initialized)

local function registerModConfig()		local template = mwse.mcm.createTemplate("Shields Up")	template:saveOnClose("Shields Up", cf)	template:register()		local p0 = template:createPage()
p0:createYesNoButton{label = "Show messages", variable = mwse.mcm.createTableVariable{id = "m3", table = cf}}
end		event.register("modConfigReady", registerModConfig)