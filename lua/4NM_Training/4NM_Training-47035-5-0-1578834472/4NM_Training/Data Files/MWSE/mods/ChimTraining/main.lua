local config = mwse.loadConfig("4NM_TRAINING") or {messages = false, skillpointsmode = true, levelingmode = true, chim = false, restmode = false}
local msg	local koefmag = 1	local koefench = 1	local koefweapon = 1	local koefarmor = 1		local koefsec = 1	local koefcraft		local koefsocial	local L

local weaponSkills = {[4] = true, [5] = true, [6] = true, [7] = true, [22] = true, [23] = true, [26] = true}	
local armorSkills = {[0] = true, [2] = true, [3] = true, [17] = true, [21] = true}
local magSkills = {[10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true}
local menuSkills = {[1] = true, [8] = true, [16] = true, [24] = true, [25] = true}
local attr = {[0] = "strength", [1] = "intelligence", [2] = "willpower", [3] = "agility", [4] = "speed", [5] = "endurance", [6] = "personality", [7] = "luck"}

local realtimer = timer		local hourtimer = timer		local resttimer = timer
local function onRest()
	if hourtimer.state == timer.active then hourtimer:cancel() end		if realtimer.state == timer.active then realtimer:cancel() end
	realtimer = timer.start({duration = 1, callback = function() hourtimer:cancel() end})
	hourtimer = timer.start({type = timer.game, duration = 0.01, callback = function()
		if msg then tes3.messageBox("You need to put your mind in order after rest") end
		if resttimer.state == timer.active then resttimer:cancel() end
		resttimer = timer.start({type = timer.game, duration = 0.5, callback = function() end})
	end})
end

local function onDamaged(e) if e.source == "attack" then
if e.attackerReference == tes3.player then koefweapon = (((e.reference.object.level * 5) - e.attackerReference.object.level) / (e.reference.object.level + 20)) * (e.damage / 50)	if koefweapon < 0 then koefweapon = 0 end
elseif e.reference == tes3.player then koefarmor = (((e.attackerReference.object.level * 5) - e.reference.object.level) / (e.attackerReference.object.level + 20)) * (e.damage / 20)	if koefarmor < 0 then koefarmor = 0 end end
end end

local function onMagicCasted(e) if e.caster == tes3.player then
	if e.source.objectType == tes3.objectType.spell then koefmag = (e.source.magickaCost * 5) / (e.source.magickaCost + 80)
	elseif e.source.objectType == tes3.objectType.enchantment then koefench = (e.source.chargeCost * 5) / (e.source.chargeCost + 80) end
	if resttimer.state == timer.active then koefmag = koefmag * 0.2		koefench = koefench * 0.2 end
end end

local function onLockPick(e) koefsec = e.lockData.level / 100 end
local function onTrapDisarm(e) if e.lockData and e.lockData.trap then koefsec = (e.lockData.trap.magickaCost * 5) / (e.lockData.trap.magickaCost + 80) end end


local function onExerciseSkill(e)
	if e.skill == 8 then	e.progress = e.progress * (1 + (tes3.mobilePlayer.encumbrance.current / tes3.mobilePlayer.encumbrance.base)) -- ????????
	elseif weaponSkills[e.skill] then	e.progress = e.progress * koefweapon	if msg then tes3.messageBox("Weapon exp: %.2f", koefweapon) end
	elseif armorSkills[e.skill] then	e.progress = e.progress * koefarmor		if msg then tes3.messageBox("Armor exp: %.2f", koefarmor) end
	elseif magSkills[e.skill] then		e.progress = e.progress * koefmag		if msg then tes3.messageBox("Magic exp: %.2f", koefmag) end
	elseif e.skill == 9 then	if e.progress < 3 then e.progress = e.progress * koefench end		if msg then tes3.messageBox("Enchant exp: %.3f  Koef: %.2f", e.progress, koefench) end
	elseif e.skill == 18 then	e.progress = e.progress * koefsec		if msg then tes3.messageBox("Security exp: %.2f  Koef: %.2f", e.progress, koefsec) end		
	elseif e.skill == 16 or e.skill == 1 then	if tes3.player.data.expcraft == nil then tes3.player.data.expcraft = 0 end -- ??????? ? ??????
		koefcraft = 1 - tes3.player.data.expcraft / (tes3.player.data.expcraft + 50)		if koefcraft < 0.05 then koefcraft = 0 end		e.progress = e.progress * koefcraft
		if tes3.player.data.expcraft < 1000 then tes3.player.data.expcraft = tes3.player.data.expcraft + 10 end
		if msg then tes3.messageBox("Craft exp: %.2f  Fatigue: %.1f", koefcraft, tes3.player.data.expcraft) end
	elseif e.skill == 24 or e.skill == 25 then	if tes3.player.data.expsocial == nil then tes3.player.data.expsocial = 0 end -- ??????????? ? ????????
		koefsocial = 1 - tes3.player.data.expsocial / (tes3.player.data.expsocial + 50)		if koefsocial < 0.05 then koefsocial = 0 end	e.progress = e.progress * koefsocial
		if tes3.player.data.expsocial < 1000 then tes3.player.data.expsocial = tes3.player.data.expsocial + 10 end
		if msg then tes3.messageBox("Social exp: %.2f  Koef: %.2f  Fatigue: %.2f", e.progress, koefsocial, tes3.player.data.expsocial) end
	end
	if menuSkills[e.skill] ~= true then
		if tes3.player.data.expcraft and tes3.player.data.expcraft > 0 then tes3.player.data.expcraft = tes3.player.data.expcraft - e.progress else tes3.player.data.expcraft = nil end
		if tes3.player.data.expsocial and tes3.player.data.expsocial > 0 then tes3.player.data.expsocial = tes3.player.data.expsocial - e.progress else tes3.player.data.expsocial = nil end
		if msg and (tes3.player.data.expsocial or tes3.player.data.expcraft) then tes3.messageBox("Craft: %s  Social: %s", tes3.player.data.expcraft, tes3.player.data.expsocial) end
	end
end


local function onSkillRaised(e)
if config.levelingmode then		local up = 3	local lup = 0.25
	for _, s in pairs(tes3.player.object.class.majorSkills) do if s == e.skill then up = 5	lup = 1 end end		for _, s in pairs(tes3.player.object.class.minorSkills) do if s == e.skill then up = 5	lup = 1 end end
	local A = tes3.getSkill(e.skill).attribute		local Aname = attr[A]		L[Aname] = L[Aname] + up	L.levelup = L.levelup + lup
	if L[Aname] >= 10 then L[Aname] = L[Aname] - 10	if tes3.mobilePlayer[Aname].base < 100 then tes3.modStatistic{reference = tes3.player, attribute = A, value = 1}	tes3.messageBox("!!! %s +1 !!!", Aname) end end
	if L.levelup >= 10 then		L.levelup = L.levelup - 10		if tes3.player.object.level < 100 then
		tes3.messageBox("!!! LEVEL UP !!!")		tes3.streamMusic{path="Special/MW_Triumph.mp3"}		local lvl = (tes3.player.object.level + 1)
		if tes3.mobilePlayer.luck.base < 100 then tes3.modStatistic{reference = tes3.player, attribute = 7, value = 1}
		elseif tes3.mobilePlayer.personality.base < 100 then tes3.modStatistic{reference = tes3.player, attribute = 6, value = 1} end
		mwscript.setLevel{reference = tes3.player, level = lvl}
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))		menu:findChild(tes3ui.registerID("MenuStat_level")).text = tostring(lvl)	menu:updateLayout()
		if (lvl * 5) > tes3.findGlobal("4nm_lessons").value and tes3.findGlobal("4nm_stoptraining").value == 1 then tes3.findGlobal("4nm_stoptraining").value = 0 end
	end end
	tes3.mobilePlayer.levelUpProgress = math.floor(L.levelup)
	if msg then tes3.messageBox("Attribute = %s   Spec = %s   up = %s   lup = %s   STAT = %s %s   %s %s   %s %s   %s   Progr = %s / %s", Aname, tes3.getSkill(e.skill).specialization, up, lup,
	L.strength, L.endurance, L.intelligence, L.willpower, L.speed, L.agility, L.personality, L.levelup, tes3.mobilePlayer.levelUpProgress) end
end
if config.skillpointsmode and e.source == "training" then -- progress, book, training
	tes3.findGlobal("4nm_lessons").value = tes3.findGlobal("4nm_lessons").value + 1
	tes3.messageBox("Trained already %s times. %s left", tes3.findGlobal("4nm_lessons").value, (tes3.player.baseObject.level * 5 - tes3.findGlobal("4nm_lessons").value))
	if (tes3.player.baseObject.level * 5) <= tes3.findGlobal("4nm_lessons").value then	tes3.findGlobal("4nm_stoptraining").value = 1		tes3.messageBox("It's time to put the acquired knowledge into practice") end
end
end


local function onLoaded(e)	msg = config.messages
L = tes3.player.data.leveling	if L == nil then tes3.player.data.leveling = {strength = 0, endurance = 0, intelligence = 0, willpower = 0, speed = 0, agility = 0, personality = 0, levelup = 0}	L = tes3.player.data.leveling end
if (tes3.player.baseObject.level * 5) > tes3.findGlobal("4nm_lessons").value and tes3.findGlobal("4nm_stoptraining").value == 1 then tes3.findGlobal("4nm_stoptraining").value = 0 end
if config.levelingmode and config.chim then	local SkillsHP = {"unarmored", "lightArmor", "mediumArmor", "heavyArmor", "athletics"}
	local basehp = tes3.mobilePlayer.endurance.base/2 + tes3.mobilePlayer.strength.base/4 + tes3.mobilePlayer.willpower.base/4		local perk = 0
	for _, skill in pairs(SkillsHP) do if tes3.mobilePlayer[skill].base >= 100 then perk = perk + 10 elseif tes3.mobilePlayer[skill].base >= 75 then perk = perk + 6 elseif tes3.mobilePlayer[skill].base >= 50 then perk = perk + 3 end end
	if tes3.mobilePlayer.health.base == tes3.mobilePlayer.health.current then
		tes3.setStatistic{reference = tes3.player, name = "health", value = (basehp + perk + tes3.getEffectMagnitude{reference = tes3.player, effect = 80})}
		if msg then tes3.messageBox("HP = %s  Stats = %s  Perks = %s  Buff = %s", tes3.mobilePlayer.health.base, basehp, perk, tes3.getEffectMagnitude{reference = tes3.player, effect = 80}) end
	end
end
end


local function registerModConfig()
	local template = mwse.mcm.createTemplate("4NM_TRAINING")	template:saveOnClose("4NM_TRAINING", config)	local page = template:createPage()
	page:createYesNoButton{label = "Show messages", variable = mwse.mcm.createTableVariable{id = "messages", table = config}, defaultSetting = false}
	page:createYesNoButton{label = "5 skill points per level", variable = mwse.mcm.createTableVariable{id = "skillpointsmode", table = config}, defaultSetting = true}
	page:createYesNoButton{label = "New leveling system", variable = mwse.mcm.createTableVariable{id = "levelingmode", table = config}, defaultSetting = true}
	page:createYesNoButton{label = "New max health formula. Choose NO if you are using a 4NM_GMST mod", variable = mwse.mcm.createTableVariable{id = "chim", table = config}, defaultSetting = false}
	page:createYesNoButton{label = "Short-term penalty to magical experience after rest. Requires restarting the game.", variable = mwse.mcm.createTableVariable{id = "restmode", table = config}, defaultSetting = false}
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)

local function initialized(e)
	event.register("damaged", onDamaged)
	event.register("magicCasted", onMagicCasted)
	event.register("exerciseSkill", onExerciseSkill)
	event.register("lockPick", onLockPick)
	event.register("trapDisarm", onTrapDisarm)
	event.register("skillRaised", onSkillRaised)
	event.register("loaded", onLoaded)
	if config.restmode then event.register("uiShowRestMenu", onRest) end
end
event.register("initialized", initialized)