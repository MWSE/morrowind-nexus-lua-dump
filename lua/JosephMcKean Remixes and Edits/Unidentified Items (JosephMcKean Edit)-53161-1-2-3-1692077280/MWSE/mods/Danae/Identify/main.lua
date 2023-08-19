local logging = require("logging.logger")

local defaults = { logLevel = "INFO" }
local config = mwse.loadConfig("Unidentified Items", defaults)
local log = logging.new({ name = "Unidentified Items", logLevel = config.logLevel })

local spellMap = {
	-- spellId = {cursed, tooltip, spellEffect, attributeMods}
	x0 = { false, "", nil, {} }, -- Broken _
	x1 = { false, "Highly enchantable", nil, {} }, -- Enchantable _
	x2 = { false, "", nil, {} }, -- Old _
	x3 = { false, "", nil, {} }, -- Useless _
	x4 = { false, "", nil, {} }, -- Valuable _
	x5 = { false, "", nil, {} }, -- _ of Value
	x6 = { false, "Highly enchantable", nil, {} }, -- _ of Enchantment
	antidot = { false, "Resist Poison and Paralysis", "antidot", {} },
	gantidot = { false, "Cure Poison and Paralysis", "gantidot", {} },
	argo = { false, "Fortify Spear\nFortify Unarmored", "argo", {} },
	gargo = { false, "Fortify Spear\nFortify Unarmored", "gargo", {} },
	brglr = { false, "Open (spell)", "brglr", {} },
	gbrglr = { false, "Open (spell)", "gbrglr", {} },
	dunmer = { false, "Fortify Agility\nFortify Short blade", "dunmer", {} },
	gdunmer = { false, "Fortify Agility\nFortify Short blade", "gdunmer", {} },
	diplo = { false, "Charm (Spell)", "diplo", {} },
	gdiplo = { false, "Charm (Spell)", "gdiplo", {} },
	elem = { false, "Resist fire\nResist frost\nResist shock", "elem", {} },
	gelem = { false, "Resist fire\nResist frost\nResist shock", "gelem", {} },
	enchant = { false, "Soultrap (Spell)", "enchant", {} },
	genchant = { false, "Fortify Enchant", "genchant", {} },
	fight = { false, "Fortify Attack", "fight", {} },
	gfight = { false, "Fortify Attack", "gfight", {} },
	flama = { false, "Fire shield", "flama", {} },
	gflama = { false, "Fire shield", "gflama", {} },
	frosta = { false, "Frost shield", "frosta", {} },
	gfrosta = { false, "Frost shield", "gfrosta", {} },
	healer = { false, "Fortify Restoration", "healer", {} },
	ghealer = { false, "Fortify Restoration", "ghealer", {} },
	imper = { false, "Fortify Mercantile\nFortify Speechcraft", "imper", {} },
	gimper = { false, "Fortify Mercantile\nFortify Speechcraft", "gimper", {} },
	kagouti = { false, "Fortify Athletics", "kagouti", {} },
	gkagouti = { false, "Fortify Athletics", "gkagouti", {} },
	keye = { false, "Night Eye", "keye", {} },
	gkeye = { false, "Night Eye", "gkeye", {} },
	negate = { false, "Dispell (Spell)", "negate", {} },
	gnegate = { false, "Dispell (Spell)", "gnegate", {} },
	orc = { false, "Fortify Armorer\nFortify Heavy armor", "orc", {} },
	gorc = { false, "Fortify Armorer\nFortify Heavy armor", "gorc", {} },
	psiji = { false, "Resist magicka", "psiji", {} },
	gpsiji = { false, "Reflect", "gpsiji", {} },
	pugil = { false, "Fortify Hand-to-hand", "pugil", {} },
	gpugil = { false, "Fortify Hand-to-hand", "gpugil", {} },
	quick = { false, "Fortify Speed", "quick", {} },
	gquick = { false, "Fortify Speed", "gquick", {} },
	sanctu = { false, "Sanctuary", "sanctu", {} },
	gsanctu = { false, "Sanctuary", "gsanctu", {} },
	shield = { false, "Shield", "shield", {} },
	gshield = { false, "Shield", "gshield", {} },
	steadf = { false, "Fortify Endurance\nResist normal weapons", "steadf", {} },
	gsteadf = { false, "Fortify Endurance\nResist normal weapons", "gsteadf", {} },
	storma = { false, "Lightning shield", "storma", {} },
	gstorma = { false, "Lightning shield", "gstorma", {} },
	transm = { false, "Fortify Alchemy", "transm", {} },
	gtransm = { false, "Fortify Alchemy", "gtransm", {} },
	willf = { false, "Fortify Willpower", "willf", {} },
	gwillf = { false, "Fortify Willpower", "gwillf", {} },
	conj = { false, "Fortify Conjuration", "conj", {} },
	gconj = { false, "Fortify Conjuration", "gconj", {} },
	cliff = { false, "Levitate (Spell)", "cliff", {} },
	gcliff = { false, "Levitate (Spell)", "gcliff", {} },
	beoth = { false, "Summon Hunger (Spell)", "beoth", {} },
	gbeoth = { false, "Bound Cuirass (Spell)", "gbeoth", {} },
	molag = { false, "Summon Daedroth (Spell)", "molag", {} },
	gmolag = { false, "Bound Mace (Spell)", "gmolag", {} },
	merhun = { false, "Summon Clannfear (Spell)", "merhun", {} },
	gmerhun = { false, "Bound Battle Axe (Spell)", "gmerhun", {} },
	sang = { false, "Summon Scamp (Spell)", "sang", {} },
	gsang = { false, "Bound Boots (Spell)", "gsang", {} },
	vivec = { false, "Fortify Willpower and Levitate (Spell)", "vivec", {} },
	gvivec = { false, "Fortify Willpower and Levitate (Spell)", "gvivec", {} },
	necro = { false, "Summon Ancestral Ghost (Spell)\nSummon Skeletal Minion (Spell)", "necro", {} },
	gnecro = { false, "Summon Bonewalker (Spell)\nSummon Greater Bonewalker (Spell)", "gnecro", {} },
	sorc = { false, "Summon Atronachs (Spell)", "sorc", {} },
	gsorc = { false, "Summon Atronachs (Spell)", "gsorc", {} },
	alma = { false, "Absorb Health, Weakness to Fire, and Fire Damage (Spell)", "alma", {} },
	galma = { false, "Absorb Health, Weakness to Fire, and Fire Damage (Spell)", "galma", {} },
	dagoth = { false, "Damage Health and Attributes (Spell)", "dagoth", {} },
	gdagoth = { false, "Damage Health and Attributes (Spell)", "gdagoth", {} },
	glow = { false, "Light", "glow", {} },
	gglow = { false, "Light", "gglow", {} },
	luck = { false, "Fortify Luck", "luck", {} },
	gluck = { false, "Fortify Luck", "gluck", {} },
	hirci = { false, "Bound Spear (Spell)", "hirci", {} },
	sheo = { false, "Summon Golden Saint (Spell)", "sheo", {} },
	peryit = { false, "Bound Shield (Spell)", "peryit", {} },
	vaerm = { false, "Bound Gloves (Spell)", "vaerm", {} },
	malac = { false, "Bound Longsword (Spell)", "malac", {} },
	mepha = { false, "Bound Dagger (Spell)", "mepha", {} },
	lsmith = { false, "Lock (Spell)", "lsmith", {} },
	x7 = { true, "Damage Agility", nil, { agility = -5 } }, -- Clumsy _
	x8 = { true, "Damage Magicka", nil, { magicka = -20 } }, -- Depleting _
	x9 = { true, "Damage Personality", nil, { personality = -5 } }, -- Dirty _
	x10 = { true, "Damage Endurance", nil, { endurance = -5 } }, -- Exhausting _
	foul = { true, "Weakness to Diseases", "foul", {} },
	heavy = { true, "Burden", "heavy", {} },
	x11 = { true, "Damage Speed", nil, { speed = -5 } }, -- Hindering _
	x12 = { true, "Damage Luck", nil, { luck = -5 } }, -- Jinxed _
	photo = { true, "Sun Damage", "photo", {} },
	x13 = { true, "Damage Willpower", nil, { willpower = -5 } }, -- Soul-crushing _
	x14 = { true, "Damage Luck\nDamage Personality\nDamage Willpower", nil, { luck = -3, willpower = -3, personality = -3 } }, -- Tainted _
	x15 = { true, "Damage Fatigue", nil, { fatigue = -20 } }, -- Tiring _
	x16 = { true, "Damage Strength", nil, { strength = -5 } }, -- Frail _
	altmer = { false, "Fortify Alteration\nFortify Destruction", "altmer", {} },
	galtmer = { false, "Fortify Alteration\nFortify Destruction", "galtmer", {} },
	asserti = { false, "Fortify Personality", "asserti", {} },
	gasserti = { false, "Fortify Personality", "gasserti", {} },
	block = { false, "Fortify Block", "block", {} },
	gblock = { false, "Fortify Block", "gblock", {} },
	breton = { false, "Fortify Illusion\nFortify Mysticism", "breton", {} },
	gbreton = { false, "Fortify Illusion\nFortify Mysticism", "gbreton", {} },
	bosmer = { false, "Fortify Marskman", "bosmer", {} },
	gbosmer = { false, "Bound Longbow", "gbosmer", {} },
	fish = { false, "Swift Swim", "fish", {} },
	gfish = { false, "Swift Swim", "gfish", {} },
	grass = { false, "Jump", "grass", {} },
	ggrass = { false, "Jump", "ggrass", {} },
	guar = { false, "Feather", "guar", {} },
	gguar = { false, "Feather", "gguar", {} },
	health = { false, "Restore Health over time", "health", {} },
	ghealth = { false, "Restore Health over time", "ghealth", {} },
	khajiit = { false, "Fortify Security", "khajiit", {} },
	gkhajiit = { false, "Fortify Security", "gkhajiit", {} },
	leaf = { false, "Slowfall", "leaf", {} },
	gleaf = { false, "Slowfall", "gleaf", {} },
	nord = { false, "Fortify Axe\nFortify Medium Armor", "nord", {} },
	gnord = { false, "Fortify Axe\nFortify Medium Armor", "gnord", {} },
	rest = { false, "Restore Fatigue over time", "rest", {} },
	grest = { false, "Restore Fatigue over time", "grest", {} },
	seer = { false, "Detect Enchantments\nDetect Keys", "seer", {} },
	gseer = { false, "Detect Enchantments\nDetect Keys", "gseer", {} },
	smart = { false, "Fortify Intelligence", "smart", {} },
	gsmart = { false, "Fortify Intelligence", "gsmart", {} },
	strong = { false, "Fortify Strength", "strong", {} },
	gstrong = { false, "Fortify Strength", "gstrong", {} },
	thief = { false, "Fortify Sneak\nTelekinesis", "thief", {} },
	gthief = { false, "Fortify Sneak\nTelekinesis", "gthief", {} },
	track = { false, "Detect Animals", "track", {} },
	gtrack = { false, "Detect Animals", "gtrack", {} },
	merida = { false, "Turn Undead", "merida", {} },
	gmerida = { false, "Turn Undead", "gmerida", {} },
	rang = { false, "Call Wolf", "rang", {} },
	grang = { false, "Call Bear", "grang", {} },
	remedy = { false, "Resist Diseases", "remedy", {} },
	gremedy = { false, "Cure Diseases", "gremedy", {} },
	sprig = { false, "Restore Health (Spell)", "sprig", {} },
	gsprig = { false, "Restore Health (Spell)", "gsprig", {} },
	paral = { false, "Paralyze (Spell)", "paral", {} },
	gparal = { false, "Paralyze (Spell)", "gparal", {} },
	syagi = { false, "Absorb Agility (Spell)", "syagi", {} },
	gsyagi = { false, "Absorb Agility (Spell)", "gsyagi", {} },
	syint = { false, "Absorb Intelligence (Spell)", "syint", {} },
	gsyint = { false, "Absorb Intelligence (Spell)", "gsyint", {} },
	syluck = { false, "Absorb Luck (Spell)", "syluck", {} },
	gsyluck = { false, "Absorb Luck (Spell)", "gsyluck", {} },
	symag = { false, "Absorb Magicka (Spell)", "symag", {} },
	gsymag = { false, "Absorb Magicka (Spell)", "gsymag", {} },
	sysp = { false, "Absorb Speed (Spell)", "sysp", {} },
	gsysp = { false, "Absorb Speed (Spell)", "gsysp", {} },
	systam = { false, "Absorb Fatigue (Spell)", "systam", {} },
	gsystam = { false, "Absorb Fatigue (Spell)", "gsystam", {} },
	systr = { false, "Absorb Strength (Spell)", "systr", {} },
	gsystr = { false, "Absorb Strength (Spell)", "gsystr", {} },
	imperf = { false, "Weakness to Shock and Shock Damage (Spell)", "imperf", {} },
	gimperf = { false, "Weakness to Shock and Shock Damage (Spell)", "gimperf", {} },
	syheal = { false, "Absorb Health (Spell)", "syheal", {} },
	gsyheal = { false, "Absorb Health (Spell)", "gsyheal", {} },
	dreugh = { false, "Water breathing", "dreugh", {} },
	draugr = { false, "Summon Bonewolf", "draugr", {} },
	dwemer = { false, "Summon Centurion Sphere (Spell)", "dwemer", {} },
	wstrider = { false, "Water walking", "wstrider", {} },
	blind = { true, "Blind", "blind", {} },
	atronach = { true, "Stunted Magicka", "atronach", {} },
	x17 = { true, "Damage Intelligence", nil, { intelligence = -5 } }, -- _ of Confusion
	x18 = { true, "Damage All Attributes", nil, { agility = -3, endurance = -3, intelligence = -3, luck = -3, personality = -3, speed = -3, strength = -3, willpower = -3 } }, -- _ of Curses
	firew = { true, "Weakness to Fire", "firew", {} },
	frostw = { true, "Weakness to Frost", "frostw", {} },
	magw = { true, "Weakness to Magicka", "magw", {} },
	x19 = { true, "Damage Health", nil, { health = -20 } }, -- _ of Pain
	poisonw = { true, "Weakness to Fire", "poisonw", {} },
	shockw = { true, "Weakness to Shock", "shockw", {} },
	steelw = { true, "Weakness to Normal Weapons", "steelw", {} },
	silent = { true, "Silence", "silent", {} },
	sound = { true, "Sounds", "sound", {} },
}
local setData = {
	-- setSpell = {obtained, name, spells}
	aa_id_tamrielset = { false, "Tamriel", { "altmer", "galtmer", "argo", "gargo", "bosmer", "breton", "gbreton", "dunmer", "gdunmer", "imper", "gimper", "nord", "gnord", "orc", "gorc", "gbosmer" } },
	aa_id_healerset = { false, "Priest", { "antidot", "healer", "ghealer", "remedy", "health", "ghealth", "gremedy", "gantidot" } },
	aa_id_rogueset = { false, "Lovable Rogue", { "asserti", "gasserti", "thief", "gthief", "diplo", "gdiplo", "khajiit", "gkhajiit", "brglr", "gbrglr", "lsmith" } },
	aa_id_elementalset = { false, "Elemental", { "elem", "gelem", "flama", "gflama", "frosta", "gfrosta", "storma", "gstorma", "sorc", "gsorc" } },
	aa_id_mageset = { false, "Wizard", { "enchant", "genchant", "psiji", "gpsiji", "seer", "gseer", "smart", "gsmart", "transm", "gtransm", "willf", "gwillf", "gnegate", "negate" } },
	aa_id_beastset = { false, "Beast", { "dreugh", "fish", "gfish", "grass", "ggrass", "guar", "gguar", "wstrider", "cliff", "gcliff", "rang", "grang", "sprig", "gsprig", "track", "gtrack" } },
	aa_id_adventurerset = { false, "Adventurer", { "glow", "gglow", "keye", "gkeye", "luck", "gluck", "rest", "quick", "gquick", "grest", "mark", "recall" } },
	aa_id_fighterset = { false, "Warrior", { "fight", "gfight", "steadf", "gsteadf", "strong", "gstrong", "shield", "gshield", "block", "gblock", "kagouti", "gkagouti" } },
	aa_id_godlyset = { false, "Godly", { "alma", "sotha", "galma", "dagoth", "gdagoth", "vivec", "gvivec" } },
	aa_id_deathlordset = { false, "Deathlord", { "gmerida", "merida", "gnecro", "gsyheal", "syheal", "conj", "gconj", "necro" } },
	aa_id_daedricset = { false, "Daedric", { "gbeoth", "gmerhun", "gsang", "hirci", "malac", "merhun", "molag", "peryit", "sang", "sheo", "vaerm", "gmolag" } },
	aa_id_tricksterset = { false, "Trickster", { "gparal", "gsyagi", "gsyint", "gsyluck", "gsymag", "gsysp", "gsystam", "gsystr", "paral", "syagi", "syint", "symag", "sysp", "systam", "systr" } },
}
local identifyCost = 50

-- create mapping of spells to sets
local spellSetMap = {} ---@type table<string, string>
for setId, set in pairs(setData) do
	local spells = set[3]
	for _, spellId in ipairs(spells) do spellSetMap[spellId] = setId end
end

---@param text string
---@return string text
local function capitalize(text)
	text = text:gsub("(%w+)", function(a) return a:gsub("^%l", string.upper) end)
	return text
end

local function capitalizeSpellName() for spell in tes3.iterateObjects(tes3.objectType.spell) do if spell.id:startswith("aa_id_") then spell.name = capitalize(spell.name) end end end

-- helper function to get spells from item
---@param item tes3clothing|tes3armor|any
---@return string[]
local function tokenise(item)
	local id = item.id:lower() .. "_"
	local spells = {}
	if id:startswith("aa_id_") then for spellId, _ in pairs(spellMap) do if string.find(id, "_" .. spellId .. "_") then table.insert(spells, spellId) end end end
	return spells
end

-- add spell effects according to item ID
---@param e equippedEventData
local function addItem(e)
	if not e.item.id:startswith("aa_id_") then return end
	log:debug("addItem %s", e.item.id)
	local checkSets = {} ---@type string[]
	for _, spellId in ipairs(tokenise(e.item)) do
		local set = spellSetMap[spellId]
		if set then table.insert(checkSets, set) end
		local spell = spellMap[spellId][3]
		if spell then tes3.addSpell({ reference = e.reference, spell = "aa_id_" .. spell }) end
		local statMod = spellMap[spellId][4]
		for stat, value in pairs(statMod) do
			log:trace("modStatistic %s %s pts", stat, value)
			tes3.modStatistic({ reference = tes3.player, name = stat, value = value })
		end
	end
	-- add set spell if needed
	for _, setSpell in ipairs(checkSets) do
		local setObtained = setData[setSpell][1]
		if not setObtained then
			local found = 0
			for _, stack in ipairs(tes3.player.object.equipment) do for _, spellId in ipairs(tokenise(stack.object)) do if spellSetMap[spellId] == setSpell then found = found + 1 end end end
			if found >= 5 then
				setData[setSpell][1] = true
				tes3.addSpell({ reference = e.reference, spell = setSpell })
				local setName = setData[setSpell][2]
				tes3.messageBox("By equipping 5 items from the " .. setName .. " set, you have gained a new power.")
			end
		end
	end
end

-- remove spell effects according to item ID
---@param e unequippedEventData
local function removeItem(e)
	for _, spellId in ipairs(tokenise(e.item)) do
		-- FIXME: this will remove the spell effect even if there are other
		-- items with that spell effect still equipped
		local spell = spellMap[spellId][3]
		if spell then tes3.removeSpell({ reference = e.reference, spell = "aa_id_" .. spell }) end
		local statMod = spellMap[spellId][4]
		for stat, value in pairs(statMod) do tes3.modStatistic({ reference = tes3.player, name = stat, value = -value }) end
	end
end

-- map of unidentified items to the identified levelled lists
local identifiable = {
	aa_id_amulet_un = "aa_id_amulets_all",
	aa_id_belt_un = "aa_id_belts_all",
	aa_id_ring_un = "aa_id_rings_all",
	aa_id_robe_un = "aa_id_robes_all",
	aa_id_shirt_un = "aa_id_shirts_all",
	aa_id_pants_un = "aa_id_pants_all",
}

---@class tes3ui.showInventorySelectMenu.callbackParams
---@field item tes3item
---@field itemData tes3itemData
---@field count number
---@field inventory tes3inventory
---@field actor tes3actor

-- remove the given item and replace it with an identified one
---@param callbackParams tes3ui.showInventorySelectMenu.callbackParams
local function identifyItem(callbackParams)
	if callbackParams.item then
		local unidentified = callbackParams.item ---@cast unidentified tes3misc
		log:debug("identifyItem %s", unidentified.id)
		if tes3ui.getServiceActor() then tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = identifyCost }) end
		tes3.removeItem({ reference = tes3.player, item = unidentified, count = 1 })

		-- follow the levelled lists
		local leveledList = assert(tes3.getObject(identifiable[callbackParams.item.id:lower()]))
		if not leveledList then return end
		---@cast leveledList tes3leveledItem
		local identified = leveledList:pickFrom()
		log:trace("pick %s from leveled list %s", identified, leveledList)
		while identified and identified.objectType == tes3.objectType.leveledItem do
			identified = leveledList:pickFrom()
			log:trace("pick %s from leveled list %s", identified, leveledList)
		end

		if not identified then
			tes3.messageBox("The item's enchantment has been ruined, and it crumbles to dust.")
			return
		end

		tes3.addItem({ reference = tes3.player, item = identified })
		tes3.messageBox("%s successfully identified!", unidentified.name)
	end
end

---@class tes3ui.showInventorySelectMenu.filterParams
---@field item tes3item
---@field itemData tes3itemData

-- check that the given item is an unidentified item
---@param filterParams tes3ui.showInventorySelectMenu.filterParams
local function identifyFilter(filterParams) return not not identifiable[filterParams.item.id] end

local identifyEffectId = 9599
tes3.claimSpellEffectId("identify", identifyEffectId)

local function addSpellEffect()
	tes3.addMagicEffect({
		id = identifyEffectId,
		name = "Identify",
		description = "Identify unidentified items",
		school = tes3.magicSchool.mysticism,
		speed = 1,
		appliesOnce = true,
		casterLinked = false,
		hasContinuousVFX = false,
		hasNoDuration = true,
		hasNoMagnitude = true,
		canCastSelf = true,
		canCastTarget = false,
		canCastTouch = false,
		illegalDaedra = false,
		isHarmful = false,
		nonRecastable = false,
		targetsAttributes = false,
		targetsSkills = false,
		usesNegativeLighting = false,
		unreflectable = false,
		icon = "s\\tx_s_detect_enchtmt.tga",
		particleTexture = "vfx_myst_flare01.tga",
		castSound = "Mysticism Cast",
		castVFX = "VFX_MysticismCast",
		boltSound = "Mysticism Bolt",
		boltVFX = "VFX_MysticismBolt",
		hitSound = "Mysticism Hit",
		hitVFX = "VFX_MysticismHit",
		areaSound = "Mysticism Area",
		areaVFX = "VFX_MysticismArea",
		lighting = { x = 241 / 255, y = 228 / 255, z = 239 / 255 },
		size = 1,
		sizeCap = 50,
		onCollision = nil,
		onTick = nil,
	})
end

-- Has to be outside initialized
event.register("magicEffectsResolved", addSpellEffect)

local function showUnidentifiedItemsMenu()
	tes3ui.showInventorySelectMenu({ title = "Identify items", noResultsText = "No items that you can identify", filter = identifyFilter, callback = identifyItem })
end

---@param e magicCastedEventData
local function onMagicCasted(e)
	if e.caster ~= tes3.player then return end
	local effects = e.sourceInstance.sourceEffects
	for _, effect in ipairs(effects) do
		if effect.id == identifyEffectId then
			timer.start({ duration = 1, callback = function() showUnidentifiedItemsMenu() end })
			return
		end
	end
end

-- check if the button should be disabled 
local function getDisabled()
	-- check if the player can afford
	return tes3.getPlayerGold() < identifyCost
end

---@param menu tes3uiElement
local function updateServiceButton(menu)
	timer.frame.delayOneFrame(function()
		if not menu then return end
		local serviceButton = menu:findChild("aa_id_identify_button")
		if not serviceButton then return end
		serviceButton.visible = true
		-- if the button should be disabled, disable it and grey out
		if getDisabled() then
			serviceButton.disabled = true
			serviceButton.widget.state = 2
		else
			serviceButton.disabled = false
		end
	end)
end

local function identifyButtonTooltip(menu)
	updateServiceButton(menu)
	local tooltip = tes3ui.createTooltipMenu()
	local labelText = "Identify unidentified items"
	if getDisabled() then labelText = "You do not have enough gold." end
	local tooltipText = tooltip:createLabel({ text = labelText })
	tooltipText.wrapText = true
end

local function identifyButtonMouseClick() if not getDisabled() then showUnidentifiedItemsMenu() end end

---@param ref tes3reference
local function canIdentify(ref)
	local object = ref.object
	local aiConfig = object.aiConfig
	return aiConfig.offersEnchanting and not aiConfig.offersRepairs and aiConfig.bartersEnchantedItems
end

---@param menu tes3uiElement
local function createIdentifyButton(menu)
	local divider = menu:findChild("MenuDialog_divider")
	local topicsList = divider.parent
	local button = topicsList:createTextSelect({ id = "aa_id_identify_button", text = "Identify" })
	button.widthProportional = 1.0
	topicsList:reorderChildren(divider, button, 1)
	button:register("mouseClick", identifyButtonMouseClick)
	button:register("help", function() identifyButtonTooltip(menu) end)
	menu:registerAfter("update", function() updateServiceButton(menu) end)
end

-- upon entering the dialog menu, create the hot tea button 
---@param e uiActivatedEventData
local function onMenuDialog(e)
	local menuDialog = e.element
	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor") ---@cast mobileActor tes3mobileActor
	local ref = mobileActor.reference
	if canIdentify(ref) then
		log:debug("Adding Hot Tea Service to %s", ref.id)
		createIdentifyButton(menuDialog)
		menuDialog:updateLayout()
	end
end

-- show "cursed" tooltip on cursed items
---@param e uiObjectTooltipEventData
local function uiObjectTooltip(e)
	local object = e.object
	if not object then return end
	if not object.id:startswith("aa_id_") then return end
	if object.id:endswith("_un") then return end
	if object.id:endswith("_spellbook") then return end
	local name = e.tooltip:findChild("HelpMenu_name")
	if not name then return end
	local spells = tokenise(e.object)
	for _, spellId in ipairs(spells) do
		local isCursed = spellMap[spellId][1]
		if isCursed then
			name.text = name.text .. " (Cursed)"
			break
		end
	end
	local block = e.tooltip:createBlock({ id = tes3ui.registerID("aa_id_block_description") })
	local label = block:createLabel({ id = tes3ui.registerID("aa_id_description"), text = "" })
	label.color = tes3ui.getPalette(tes3.palette.fatigueColor)
	label.wrapText = true
	for i, spellId in ipairs(spells) do
		local spellName = spellMap[spellId][2]
		if spellName and (spellName ~= "") then
			spellName = capitalize(spellName)
			label.text = label.text .. spellName
			if i ~= #spells then label.text = label.text .. "\n" end
		end
	end
	label.borderLeft = 10
	label.borderRight = 10
	block.maxWidth = 440
	block.autoWidth = true
	block.autoHeight = true
end

local requirements = 50

---@param e infoGetTextEventData
local function changeIdentifyRequirements2(e)
	if e.info.id ~= "88727851293388736" then return end
	e.text = "I do have one, but frankly, you wouldn't be able to make sense out of it. Come back when your Mysticism and Enchant are better.\n\n" .. "[Both skills need to be at least " ..
	         requirements .. "]"
end

---@param e infoFilterEventData
local function changeIdentifyRequirements1(e)
	if e.info.id ~= "88727851293388736" then return end
	local PCMysticism = tes3.mobilePlayer.mysticism
	if PCMysticism.current >= requirements then e.passes = false end
	local PCEnchant = tes3.mobilePlayer.enchant
	if PCEnchant.current >= requirements then e.passes = false end
end

local deprecatedIdentifySpells = { ["Identify"] = true, ["aa_id_identify_spell"] = true }
local newIdentifySpell = "aa_id_identify_spell_01"
local spellbook = "aa_id_spellbook"

-- add the default identify spell when the identify spellbook is read
---@param e activateEventData|equipEventData
local function readSpellBook(e)
	if e.target then
		log:trace("e.target")
		if e.target.id == spellbook then
			log:trace("e.target.id == spellbook")
			tes3.addSpell({ reference = tes3.player, spell = newIdentifySpell })
		end
	elseif e.item then
		log:trace("e.item")
		if e.item.id == spellbook then
			log:trace("e.item.id == spellbook")
			tes3.addSpell({ reference = tes3.player, spell = newIdentifySpell })
		end
	end
end

local function deprecateOldSpells()
	local player = tes3.player.object
	for spellId, isDeprecatedSpell in pairs(deprecatedIdentifySpells) do
		if isDeprecatedSpell then
			local spell = tes3.getObject(spellId)
			if spell then
				spell.name = "<Deprecated>"
				if player.spells:contains(spellId) then
					tes3.removeSpell({ reference = tes3.player, spell = spellId })
					tes3.addSpell({ reference = tes3.player, spell = newIdentifySpell })
				end
			end
		end
	end
end

-- create a default identify spell
local function onLoaded(e)
	local spell = tes3.getObject(newIdentifySpell)
	if not spell then
		spell = tes3.createObject({ id = newIdentifySpell, objectType = tes3.objectType.spell })
		spell.name = "Identify"
		spell.magickaCost = 15
		spell.effects[1].id = identifyEffectId
	end
	deprecateOldSpells()
end

event.register("initialized", function()
	capitalizeSpellName()
	event.register("magicCasted", onMagicCasted)
	event.register("equipped", addItem)
	event.register("unequipped", removeItem)
	event.register("uiActivated", onMenuDialog, { filter = "MenuDialog" })
	event.register("uiObjectTooltip", uiObjectTooltip)
	-- event.register("infoGetText", changeIdentifyRequirements2)
	-- event.register("infoFilter", changeIdentifyRequirements1)
	event.register("activate", readSpellBook)
	event.register("equip", readSpellBook)
	event.register("loaded", onLoaded)
end)
