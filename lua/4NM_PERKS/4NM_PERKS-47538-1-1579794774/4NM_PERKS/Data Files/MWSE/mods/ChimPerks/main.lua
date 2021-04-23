local config = mwse.loadConfig("4NM_PERKS") or {addspells = false, remspells = false, check = false, reselect = false}
local S = {"armorer", "mediumArmor", "heavyArmor", "bluntWeapon", "longBlade", "axe", "spear", "athletics", "enchant", "destruction", "alteration", "illusion", "conjuration", "mysticism", "restoration",
"alchemy", "unarmored", "security", "sneak", "acrobatics", "lightArmor", "shortBlade", "marksman", "mercantile", "speechcraft", "handToHand", [0] = "block"}
--local mes = {"????????", "??????? ????????", "??????? ????????", "????????? ??????", "??????? ???????", "???????", "?????????? ??????", "????????", "???????????", "??????????", "?????????", "???????", "??????????",
--"??????????", "??????????????", "???????", "????????????? ???", "??????", "??????????", "??????????", "?????? ????????", "???????? ???????", "????????", "????????", "???????????", "??????????? ???", [0] = "??????"}
local mes = {"armorer", "medium armor", "heavy armor", "blunt weapon", "long blade", "axe", "spear", "athletics", "enchant", "destruction", "alteration", "illusion", "conjuration",
"mysticism", "restoration", "alchemy", "unarmored", "security", "sneak", "acrobatics", "light armor", "short blade", "marksman", "mercantile", "speechcraft", "hand to hand", [0] = "block"}

local function onSkillRaised(e) if tes3.mobilePlayer.werewolf == false then local p = "4nm_perk_" .. S[e.skill]
if e.level == 50 and mwscript.getSpellEffects{reference = tes3.player, spell = p.."2"} == false and mwscript.getSpellEffects{reference = tes3.player, spell = p.."3"} == false then
	mwscript.addSpell{reference = tes3.player, spell = p.."1"}		tes3.messageBox("You became a expert of "..mes[e.skill])
	if e.skill ~= 24 and e.skill ~= 25 then mwscript.addSpell{reference = tes3.player, spell = p.."1a"} end
elseif e.level == 75 and mwscript.getSpellEffects{reference = tes3.player, spell = p.."1"} then
	mwscript.addSpell{reference = tes3.player, spell = p.."2"}		tes3.messageBox("You became a master of "..mes[e.skill])
	if e.skill == 24 or e.skill == 25 then
	else mwscript.addSpell{reference = tes3.player, spell = p.."2a"}	mwscript.removeSpell{reference = tes3.player, spell = p.."1"}
		if e.skill < 10 or e.skill > 15 then 	mwscript.removeSpell{reference = tes3.player, spell = p.."1a"} end
	end
elseif e.level == 100 then
	mwscript.addSpell{reference = tes3.player, spell = p.."3"}		tes3.messageBox("You became a grandmaster of "..mes[e.skill])
	if e.skill == 24 or e.skill == 25 then	mwscript.addSpell{reference = tes3.player, spell = p.."4"}
	else mwscript.addSpell{reference = tes3.player, spell = p.."3a"}	mwscript.removeSpell{reference = tes3.player, spell = p.."2"}
		if e.skill < 10 or e.skill > 15 then 	mwscript.removeSpell{reference = tes3.player, spell = p.."2a"} end
	end
end
end end


local function onLoaded()
local SkillsHP = {"unarmored", "lightArmor", "mediumArmor", "heavyArmor", "athletics"}		local SkillsAR = {"unarmored", "lightArmor", "mediumArmor", "heavyArmor", "block"}
if tes3.isAffectedBy{reference = tes3.player, effect = 80} == false and tes3.mobilePlayer.health.base == tes3.mobilePlayer.health.current then	local perk = 0
	local basehp = tes3.mobilePlayer.endurance.base/2 + tes3.mobilePlayer.strength.base/4 + tes3.mobilePlayer.willpower.base/4
	for _, s in pairs(SkillsHP) do if tes3.mobilePlayer[s].base >= 100 then perk = perk + 10 elseif tes3.mobilePlayer[s].base >= 75 then perk = perk + 6 elseif tes3.mobilePlayer[s].base >= 50 then perk = perk + 3 end end
	tes3.setStatistic{reference = tes3.player, name = "health", value = (basehp + perk + tes3.findGlobal("4nm_hpclassbonus").value)}
end
if tes3.isAffectedBy{reference = tes3.player, effect = 3} == false then		local AR = 0
	for _, s in pairs(SkillsAR) do if tes3.mobilePlayer[s].base >= 100 then AR = AR + 4 elseif tes3.mobilePlayer[s].base >= 75 then AR = AR + 2 elseif tes3.mobilePlayer[s].base >= 50 then AR = AR + 1 end end
	tes3.mobilePlayer.shield = AR
end
	
if config.remspells then config.remspells = false	for i, s in pairs(S) do
	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
	if i ~= 24 and i ~= 25 then
		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
	end
end	end

if config.addspells then config.addspells = false	for i, s in pairs(S) do		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
	if i == 24 or i == 25 then mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}	mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}
	elseif i > 9 and i < 16 then mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}
		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}	mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}	mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
	else	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}
		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
	end
end end

if config.check then config.check = false	for i, s in pairs(S) do
	if tes3.mobilePlayer[s].base >= 100 then		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
		if i == 24 or i == 25 then mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}	mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}
		elseif i > 9 and i < 16 then mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}
			mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}	mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}	mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
		else	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}
			mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
		end
	elseif tes3.mobilePlayer[s].base >= 75 then		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}
		if i == 24 or i == 25 then mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
		elseif i > 9 and i < 16 then mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
			mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}	mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
		else	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
			mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
		end
	elseif tes3.mobilePlayer[s].base >= 50 then		mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1"}
		if i == 24 or i == 25 then mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
		elseif i > 9 and i < 16 then mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
			mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
		else	mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3"}
			mwscript.addSpell{reference = tes3.player, spell = "4nm_perk_"..s.."1a"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."2a"}		mwscript.removeSpell{reference = tes3.player, spell = "4nm_perk_"..s.."3a"}
		end
	end
end end

if config.reselect then config.reselect = false		tes3.findGlobal("4nm_hpclassbonus").value = 0	tes3.findGlobal("4nm_class").value = 0
	local classsp = {"01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24"}
	for i, s in ipairs(classsp) do	mwscript.removeSpell{reference = tes3.player, spell = "4nm_class_"..s} end
end
end

local function registerModConfig()		local template = mwse.mcm.createTemplate("4NM_PERKS")	template:saveOnClose("4NM_PERKS", config)	local page = template:createPage()
    page:createYesNoButton{label = "For testers only. Get all perks.", variable = mwse.mcm.createTableVariable{id = "addspells", table = config}}
	page:createYesNoButton{label = "For testers. Delete all perks.", variable = mwse.mcm.createTableVariable{id = "remspells", table = config}}
	page:createYesNoButton{label = "Didn't you get some perk? Click yes - and when loading a save, a check will occur.", variable = mwse.mcm.createTableVariable{id = "check", table = config}}
	page:createYesNoButton{label = "Re-select your class when loading a save", variable = mwse.mcm.createTableVariable{id = "reselect", table = config}}
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)

local function initialized(e)
	event.register("loaded", onLoaded)
	event.register("skillRaised", onSkillRaised)
end
event.register("initialized", initialized)

-- ?????? ??? ????????. ???????? ??? ?????. ??? ????????. ??????? ??? ?????. ?? ?? ???????? ?????-?? ????? ??????? ?? - ? ??? ???????? ????? ?????????? ????????. ??????????? ???? ????? ??? ???????? ?????.
-- For testers only. Get all perks. For testers. Delete all perks. Didn't you get some perk? Click yes - and when loading the save, a check will occur. Re-select your class when loading a save.