local spellMap = {
	-- spellId = {cursed, tooltip, spellEffect, attributeMods}
	x0 = {false, "", nil, {}}, -- Broken _
	x1 = {false, "Highly enchantable", nil, {}}, -- Enchantable _
	x2 = {false, "", nil, {}}, -- Old _
	x3 = {false, "", nil, {}}, -- Useless _
	x4 = {false, "", nil, {}}, -- Valuable _
	x5 = {false, "", nil, {}}, -- _ of Value
	x6 = {false, "Highly enchantable", nil, {}}, -- _ of Enchantment
	antidot = {false, "Resist Poison and Paralysis", "antidot", {}},
	gantidot = {false, "Cure Poison and Paralysis", "gantidot", {}},
	argo = {false, "Fortify Spear\nFortify Unarmored", "argo", {}},
	gargo = {false, "Fortify Spear\nFortify Unarmored", "gargo", {}},
	brglr = {false, "Open (spell)", "brglr", {}},
	gbrglr = {false, "Open (spell)", "gbrglr", {}},
	dunmer = {false, "Fortify Agility\nFortify Short blade", "dunmer", {}},
	gdunmer = {false, "Fortify Agility\nFortify Short blade", "gdunmer", {}},
	diplo = {false, "Charm (Spell)", "diplo", {}},
	gdiplo = {false, "Charm (Spell)", "gdiplo", {}},
	elem = {false, "Resist fire\nResist frost\nResist shock", "elem", {}},
	gelem = {false, "Resist fire\nResist frost\nResist shock", "gelem", {}},
	enchant = {false, "Soultrap (Spell)", "enchant", {}},
	genchant = {false, "Fortify Enchant", "genchant", {}},
	fight = {false, "Fortify Attack", "fight", {}},
	gfight = {false, "Fortify Attack", "gfight", {}},
	flama = {false, "Fire shield", "flama", {}},
	gflama = {false, "Fire shield", "gflama", {}},
	frosta = {false, "Frost shield", "frosta", {}},
	gfrosta = {false, "Frost shield", "gfrosta", {}},
	healer = {false, "Fortify Restoration", "healer", {}},
	ghealer = {false, "Fortify Restoration", "ghealer", {}},
	imper = {false, "Fortify Mercantile\nFortify Speechcraft", "imper", {}},
	gimper = {false, "Fortify Mercantile\nFortify Speechcraft", "gimper", {}},
	kagouti = {false, "Fortify Athletics", "kagouti", {}},
	gkagouti = {false, "Fortify Athletics", "gkagouti", {}},
	keye = {false, "Night Eye", "keye", {}},
	gkeye = {false, "Night Eye", "gkeye", {}},
	negate = {false, "Dispell (Spell)", "negate", {}},
	gnegate = {false, "Dispell (Spell)", "gnegate", {}},
	orc = {false, "Fortify Armorer\nFortify Heavy armor", "orc", {}},
	gorc = {false, "Fortify Armorer\nFortify Heavy armor", "gorc", {}},
	psiji = {false, "Resist magicka", "psiji", {}},
	gpsiji = {false, "Reflect", "gpsiji", {}},
	pugil = {false, "Fortify Hand-to-hand", "pugil", {}},
	gpugil = {false, "Fortify Hand-to-hand", "gpugil", {}},
	quick = {false, "Fortify Speed", "quick", {}},
	gquick = {false, "Fortify Speed", "gquick", {}},
	sanctu = {false, "Sanctuary", "sanctu", {}},
	gsanctu = {false, "Sanctuary", "gsanctu", {}},
	shield = {false, "Shield", "shield", {}},
	gshield = {false, "Shield", "gshield", {}},
	steadf = {false, "Fortify Endurance\nResist normal weapons", "steadf", {}},
	gsteadf = {false, "Fortify Endurance\nResist normal weapons", "gsteadf", {}},
	storma = {false, "Lightning shield", "storma", {}},
	gstorma = {false, "Lightning shield", "gstorma", {}},
	transm = {false, "Fortify Alchemy", "transm", {}},
	gtransm = {false, "Fortify Alchemy", "gtransm", {}},
	willf = {false, "Fortify Willpower", "willf", {}},
	gwillf = {false, "Fortify Willpower", "gwillf", {}},
	conj = {false, "Fortify Conjuration", "conj", {}},
	gconj = {false, "Fortify Conjuration", "gconj", {}},
	cliff = {false, "Levitate (Spell)", "cliff", {}},
	gcliff = {false, "Levitate (Spell)", "gcliff", {}},
	beoth = {false, "Summon Hunger (Spell)", "beoth", {}},
	gbeoth = {false, "Bound Cuirass (Spell)", "gbeoth", {}},
	molag = {false, "Summon Daedroth (Spell)", "molag", {}},
	gmolag = {false, "Bound Mace (Spell)", "gmolag", {}},
	merhun = {false, "Summon Clannfear (Spell)", "merhun", {}},
	gmerhun = {false, "Bound Battle Axe (Spell)", "gmerhun", {}},
	sang = {false, "Summon Scamp (Spell)", "sang", {}},
	gsang = {false, "Bound Boots (Spell)", "gsang", {}},
	vivec = {false, "Fortify Willpower and Levitate (Spell)", "vivec", {}},
	gvivec = {false, "Fortify Willpower and Levitate (Spell)", "gvivec", {}},
	necro = {false, "Summon Ancestral Ghost (Spell)\nSummon Skeletal Minion (Spell)", "necro", {}},
	gnecro = {false, "Summon Bonewalker (Spell)\nSummon Greater Bonewalker (Spell)", "gnecro", {}},
	sorc = {false, "Summon Atronachs (Spell)", "sorc", {}},
	gsorc = {false, "Summon Atronachs (Spell)", "gsorc", {}},
	alma = {false, "Absorb Health, Weakness to Fire, and Fire Damage (Spell)", "alma", {}},
	galma = {false, "Absorb Health, Weakness to Fire, and Fire Damage (Spell)", "galma", {}},
	dagoth = {false, "Damage Health and Attributes (Spell)", "dagoth", {}},
	gdagoth = {false, "Damage Health and Attributes (Spell)", "gdagoth", {}},
	glow = {false, "Light", "glow", {}},
	gglow = {false, "Light", "gglow", {}},
	luck = {false, "Fortify Luck", "luck", {}},
	gluck = {false, "Fortify Luck", "gluck", {}},
	hirci = {false, "Bound Spear (Spell)", "hirci", {}},
	sheo = {false, "Summon Golden Saint (Spell)", "sheo", {}},
	peryit = {false, "Bound Shield (Spell)", "peryit", {}},
	vaerm = {false, "Bound Gloves (Spell)", "vaerm", {}},
	malac = {false, "Bound Longsword (Spell)", "malac", {}},
	mepha = {false, "Bound Dagger (Spell)", "mepha", {}},
	lsmith = {false, "Lock (Spell)", "lsmith", {}},
	x7 = {true, "Damage Agility", nil, {agility = -5}}, -- Clumsy _
	x8 = {true, "Damage Magicka", nil, {magicka = -20}}, -- Depleting _
	x9 = {true, "Damage Personality", nil, {personality = -5}}, -- Dirty _
	x10 = {true, "Damage Endurance", nil, {endurance = -5}}, -- Exhausting _
	foul = {true, "Weakness to Diseases", "foul", {}},
	heavy = {true, "Burden", "heavy", {}},
	x11 = {true, "Damage Speed", nil, {speed = -5}}, -- Hindering _
	x12 = {true, "Damage Luck", nil, {luck = -5}}, -- Jinxed _
	photo = {true, "Sun Damage", "photo", {}},
	x13 = {true, "Damage Willpower", nil, {willpower = -5}}, -- Soul-crushing _
	x14 = {true, "Damage Luck\nDamage Personality\nDamage Willpower", nil, {luck = -3, willpower = -3, personality = -3}}, -- Tainted _
	x15 = {true, "Damage Fatigue", nil, {fatigue = -20}}, -- Tiring _
	x16 = {true, "Damage Strength", nil, {strength = -5}}, -- Frail _
	altmer = {false, "Fortify Alteration\nFortify Destruction", "altmer", {}},
	galtmer = {false, "Fortify Alteration\nFortify Destruction", "galtmer", {}},
	asserti = {false, "Fortify Personality", "asserti", {}},
	gasserti = {false, "Fortify Personality", "gasserti", {}},
	block = {false, "Fortify Block", "block", {}},
	gblock = {false, "Fortify Block", "gblock", {}},
	breton = {false, "Fortify Illusion\nFortify Mysticism", "breton", {}},
	gbreton = {false, "Fortify Illusion\nFortify Mysticism", "gbreton", {}},
	bosmer = {false, "Fortify Marskman", "bosmer", {}},
	gbosmer = {false, "Bound Longbow", "gbosmer", {}},
	fish = {false, "Swift Swim", "fish", {}},
	gfish = {false, "Swift Swim", "gfish", {}},
	grass = {false, "Jump", "grass", {}},
	ggrass = {false, "Jump", "ggrass", {}},
	guar = {false, "Feather", "guar", {}},
	gguar = {false, "Feather", "gguar", {}},
	health = {false, "Restore Health over time", "health", {}},
	ghealth = {false, "Restore Health over time", "ghealth", {}},
	khajiit = {false, "Fortify Security", "khajiit", {}},
	gkhajiit = {false, "Fortify Security", "gkhajiit", {}},
	leaf = {false, "Slowfall", "leaf", {}},
	gleaf = {false, "Slowfall", "gleaf", {}},
	nord = {false, "Fortify Axe\nFortify Medium Armor", "nord", {}},
	gnord = {false, "Fortify Axe\nFortify Medium Armor", "gnord", {}},
	rest = {false, "Restore Fatigue over time", "rest", {}},
	grest = {false, "Restore Fatigue over time", "grest", {}},
	seer = {false, "Detect Enchantments\nDetect Keys", "seer", {}},
	gseer = {false, "Detect Enchantments\nDetect Keys", "gseer", {}},
	smart = {false, "Fortify Intelligence", "smart", {}},
	gsmart = {false, "Fortify Intelligence", "gsmart", {}},
	strong = {false, "Fortify Strength", "strong", {}},
	gstrong = {false, "Fortify Strength", "gstrong", {}},
	thief = {false, "Fortify Sneak\nTelekinesis", "thief", {}},
	gthief = {false, "Fortify Sneak\nTelekinesis", "gthief", {}},
	track = {false, "Detect Animals", "track", {}},
	gtrack = {false, "Detect Animals", "gtrack", {}},
	merida = {false, "Turn Undead", "merida", {}},
	gmerida = {false, "Turn Undead", "gmerida", {}},
	rang = {false, "Call Wolf", "rang", {}},
	grang = {false, "Call Bear", "grang", {}},
	remedy = {false, "Resist Diseases", "remedy", {}},
	gremedy = {false, "Cure Diseases", "gremedy", {}},
	sprig = {false, "Restore Health (Spell)", "sprig", {}},
	gsprig = {false, "Restore Health (Spell)", "gsprig", {}},
	paral = {false, "Paralyze (Spell)", "paral", {}},
	gparal = {false, "Paralyze (Spell)", "gparal", {}},
	syagi = {false, "Absorb Agility (Spell)", "syagi", {}},
	gsyagi = {false, "Absorb Agility (Spell)", "gsyagi", {}},
	syint = {false, "Absorb Intelligence (Spell)", "syint", {}},
	gsyint = {false, "Absorb Intelligence (Spell)", "gsyint", {}},
	syluck = {false, "Absorb Luck (Spell)", "syluck", {}},
	gsyluck = {false, "Absorb Luck (Spell)", "gsyluck", {}},
	symag = {false, "Absorb Magicka (Spell)", "symag", {}},
	gsymag = {false, "Absorb Magicka (Spell)", "gsymag", {}},
	sysp = {false, "Absorb Speed (Spell)", "sysp", {}},
	gsysp = {false, "Absorb Speed (Spell)", "gsysp", {}},
	systam = {false, "Absorb Fatigue (Spell)", "systam", {}},
	gsystam = {false, "Absorb Fatigue (Spell)", "gsystam", {}},
	systr = {false, "Absorb Strength (Spell)", "systr", {}},
	gsystr = {false, "Absorb Strength (Spell)", "gsystr", {}},
	imperf = {false, "Weakness to Shock and Shock Damage (Spell)", "imperf", {}},
	gimperf = {false, "Weakness to Shock and Shock Damage (Spell)", "gimperf", {}},
	syheal = {false, "Absorb Health (Spell)", "syheal", {}},
	gsyheal = {false, "Absorb Health (Spell)", "gsyheal", {}},
	dreugh = {false, "Water breathing", "dreugh", {}},
	draugr = {false, "Summon Bonewolf", "draugr", {}},
	dwemer = {false, "Summon Centurion Sphere (Spell)", "dwemer", {}},
	wstrider = {false, "Water walking", "wstrider", {}},
	blind = {true, "Blind", "blind", {}},
	atronach = {true, "Stunted Magicka", "atronach", {}},
	x17 = {true, "Damage Intelligence", nil, {intelligence = -5}}, -- _ of Confusion
	x18 = {true, "Damage All Attributes", nil, {agility = -3, endurance = -3, intelligence = -3, luck = -3, personality = -3, speed = -3, strength = -3, willpower = -3}}, -- _ of Curses
	firew = {true, "Weakness to Fire", "firew", {}},
	frostw = {true, "Weakness to Frost", "frostw", {}},
	magw = {true, "Weakness to Magicka", "magw", {}},
	x19 = {true, "Damage Health", nil, {health = -20}}, -- _ of Pain
	poisonw = {true, "Weakness to Fire", "poisonw", {}},
	shockw = {true, "Weakness to Shock", "shockw", {}},
	steelw = {true, "Weakness to Normal Weapons", "steelw", {}},
	silent = {true, "Silence", "silent", {}},
	sound = {true, "Sounds", "sound", {}},
}
local setData = {
	-- setSpell = {obtained, name, spells}
	aa_id_tamrielset = {false, "Tamriel", {"altmer", "galtmer", "argo", "gargo", "bosmer", "breton", "gbreton", "dunmer", "gdunmer", "imper", "gimper", "nord", "gnord", "orc", "gorc", "gbosmer"}},
	aa_id_healerset = {false, "Priest", {"antidot", "healer", "ghealer", "remedy", "health", "ghealth", "gremedy", "gantidot"}},
	aa_id_rogueset = {false, "Lovable Rogue", {"asserti", "gasserti", "thief", "gthief", "diplo", "gdiplo", "khajiit", "gkhajiit", "brglr", "gbrglr", "lsmith"}},
	aa_id_elementalset = {false, "Elemental", {"elem", "gelem", "flama", "gflama", "frosta", "gfrosta", "storma", "gstorma", "sorc", "gsorc"}},
	aa_id_mageset = {false, "Wizard", {"enchant", "genchant", "psiji", "gpsiji", "seer", "gseer", "smart", "gsmart", "transm", "gtransm", "willf", "gwillf", "gnegate", "negate"}},
	aa_id_beastset = {false, "Beast", {"dreugh", "fish", "gfish", "grass", "ggrass", "guar", "gguar", "wstrider", "cliff", "gcliff", "rang", "grang", "sprig", "gsprig", "track", "gtrack"}},
	aa_id_adventurerset = {false, "Adventurer", {"glow", "gglow", "keye", "gkeye", "luck", "gluck", "rest", "quick", "gquick", "grest","mark", "recall"}},
	aa_id_fighterset = {false, "Warrior", {"fight", "gfight", "steadf", "gsteadf", "strong", "gstrong", "shield", "gshield", "block", "gblock", "kagouti", "gkagouti"}},
	aa_id_godlyset = {false, "Godly", {"alma", "sotha", "galma", "dagoth", "gdagoth", "vivec", "gvivec"}},
	aa_id_deathlordset = {false, "Deathlord", {"gmerida", "merida", "gnecro", "gsyheal", "syheal", "conj", "gconj", "necro"}},
	aa_id_daedricset = {false, "Daedric", {"gbeoth", "gmerhun", "gsang", "hirci", "malac", "merhun", "molag", "peryit", "sang", "sheo", "vaerm", "gmolag"}},
	aa_id_tricksterset = {false, "Trickster", {"gparal", "gsyagi", "gsyint", "gsyluck", "gsymag", "gsysp", "gsystam", "gsystr", "paral", "syagi", "syint", "symag", "sysp", "systam", "systr"}},
}
local identifyCost = 50

-- create mapping of spells to sets
local spellSetMap = {}
for setId, set in pairs(setData) do
	for i, spellId in ipairs(set[3]) do
		spellSetMap[spellId] = setId
	end
end

-- helper function to get spells from item
local function tokenise(item)
	local id = item.id:lower() .. "_"
	local ret = {}
	if string.find(id, "aa_id_") == 1 then
		for spellId, _ in pairs(spellMap) do
			if string.find(id, "_" .. spellId .. "_") then
				table.insert(ret, spellId)
			end
		end
	end
	return ret
end

-- add spell effects according to item ID
local function addItem(e)
	local checkSets = {}
	for i, spellId in ipairs(tokenise(e.item)) do
		if spellSetMap[spellId] then
			table.insert(checkSets, spellSetMap[spellId])
		end
		local spellEffect = spellMap[spellId][3]
		if spellEffect then
			mwscript.addSpell{ reference = e.reference, spell = "aa_id_" .. spellEffect }
		end
		for stat, delta in pairs(spellMap[spellId][4]) do
			tes3.modStatistic{ reference = tes3.player, name = stat, value = delta }
		end
	end
	-- add set spell if needed
	for i, checkSet in ipairs(checkSets) do
		if not setData[checkSet][1] then
			local found = 0
			for _, stack in pairs(tes3.player.object.equipment) do
				for j, spellId in ipairs(tokenise(stack.object)) do
					if spellSetMap[spellId] == checkSet then
						found = found + 1
					end
				end
			end
			if found >= 5 then
				setData[checkSet][1] = true
				mwscript.addSpell{ reference = e.reference, spell = checkSet }
				tes3.messageBox("By equipping 5 items from the " .. setData[checkSet][2] .. " set, you have gained a new power.")
			end
		end
	end
end
event.register("equipped", addItem)

-- remove spell effects according to item ID
local function removeItem(e)
	for i, spellId in ipairs(tokenise(e.item)) do
		-- FIXME: this will remove the spell effect even if there are other
		-- items with that spell effect still equipped
		local spellEffect = spellMap[spellId][3]
		if spellEffect then
			mwscript.removeSpell{ reference = e.reference, spell = "aa_id_" .. spellEffect }
		end
		for stat, delta in pairs(spellMap[spellId][4]) do
			tes3.modStatistic{ reference = tes3.player, name = stat, value = -delta }
		end
	end
end
event.register("unequipped", removeItem)

-- map of unidentified items to the identified levelled lists
local IdentT = {
	aa_id_amulet_un = "aa_id_amulets_all",
	aa_id_belt_un = "aa_id_belts_all",
	aa_id_ring_un = "aa_id_rings_all",
	aa_id_robe_un = "aa_id_robes_all",
	aa_id_shirt_un = "aa_id_shirts_all",
	aa_id_pants_un = "aa_id_pants_all",
}

-- remove the given item and replace it with an identified one
local function IdentifyItem(e)
	if e.item then
		if tes3ui.getServiceActor() then
			tes3.removeItem{ reference = tes3.player, item = "Gold_001", count = identifyCost }
		end
		tes3.removeItem{ reference = tes3.player, item = e.item }

		-- follow the levelled lists
		local item = assert(tes3.getObject(IdentT[e.item.id:lower()]))
		while (item and item.objectType == tes3.objectType.leveledItem) do
			item = item:pickFrom()
		end

		if (not item) then
			tes3.messageBox("The item's enchantment has been ruined, and it crumbles to dust.")
			return
		end

		tes3.addItem{ reference = tes3.player, item = item }
	end
end

-- spell IDs that can be used to identify items
local IdentS = {
	Identify = true,
	aa_id_identify_spell = true,
}

-- check that the given item is an unidentified item
local function IdentifyFilt(e)
	return not not IdentT[e.item.id]
end

-- show identify UI when an identify spell is cast
local function onMagicCasted(e)
	if e.caster == tes3.player and IdentS[e.source.id] then
		tes3ui.showInventorySelectMenu{
			title = "Identify items",
			noResultsText = "No items that you can identify",
			filter = IdentifyFilt,
			callback = IdentifyItem
		}
	end
end
event.register("magicCasted", onMagicCasted)

-- set up identify service
local function onMenuEnchantment(e)
	local IS = e.element:findChild("MenuEnchantment_infoContainer"):createImage{ path = "icons/k/magic_enchant.dds" }
	IS:register("help", function()
		local tt = tes3ui.createTooltipMenu():createBlock{}
		tt.autoHeight = true
		tt.autoWidth = true
		tt:createLabel{ text = "Identify Service" }
	end)
	IS:register("mouseClick", function()
		if tes3.getPlayerGold() >= identifyCost then
			tes3ui.showInventorySelectMenu{
				title = "Identify items",
				noResultsText = "No items that you can identify",
				filter = IdentifyFilt,
				callback = IdentifyItem
			}
		else
			tes3.messageBox("You need " .. identifyCost .. " septims for this service.")
		end
	end)
	e.element:updateLayout()
end
event.register("uiActivated", onMenuEnchantment, {filter = "MenuEnchantment"})

-- show "cursed" tooltip on cursed items
local function uiObjectTooltip(e)
	local tt = e.tooltip:findChild("MenuEnchantment_infoContainer")
	for i, spellId in ipairs(tokenise(e.object)) do
		if spellMap[spellId][1] then
			tt.text = ("%s (cursed)"):format(tt.text)
			--tt.color = {43, 226, 0}
			break
		end
	end
	for i, spellId in ipairs(tokenise(e.object)) do
		if spellMap[spellId][2] ~= "" then
			tt.text = ("%s\n%s"):format(tt.text, spellMap[spellId][2])
		end
	end
end
event.register("uiObjectTooltip", uiObjectTooltip)

-- add the default identify spell when the identify spellbook is read
local function onBookGetText(e)
	if e.book.id == "aa_id_spellbook" then
		mwscript.addSpell{reference = tes3.player, spell = "Identify"}
	end
end
event.register("bookGetText", onBookGetText)

-- create a default identify spell
local function onLoaded(e)
	local s = tes3.getObject("Identify") or tes3spell.create("Identify", "Identify")
	s.magickaCost = 15
	s.effects[1].id = 65
end
event.register("loaded", onLoaded)
