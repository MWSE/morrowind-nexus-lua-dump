local RENDERER_SLIDER = "SuperSlider2"

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local tempKey
local settingsTemplate = {}

-- ═══════════════════════════════════════════════════════════════ General ═══════════════════════════════════════════════════════════════

tempKey = "General"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("Group.General", "General").."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "SWING_MINING",
			name = L("SWING_MINING.name", "Swing-Based Mining"),
			description = L("SWING_MINING.desc", "Use weapon swings to mine ore (like woodcutting) instead of the default timer-based method\nPickaxes and blunt weapons are ideal"),
			renderer = "checkbox",
			default = true,
		},
		{
			key = "USE_MINING_SKILL",
			name = L("USE_MINING_SKILL.name", "Use Mining Skill"),
			description = L("USE_MINING_SKILL.desc", "Use a custom Mining skill instead of Armorer for all mining calculations and experience\nRequires SkillFramework"),
			renderer = "checkbox",
			default = false,
		},
		{
			key = "VOLUME",
			name = L("VOLUME.name", "Volume (%)"),
			description = L("VOLUME.desc", "of the pickaxe\nValues above 100 only have an effect if your General x Effect volume settings are <100%"),
			renderer = RENDERER_SLIDER,
			default = 90,
			argument = {
				min = 0,
				max = 300,
				step = 5,
				default = 90,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.Silent", "Silent"),
				maxLabel = L("label.Loud", "Loud"),
				width = 150,
			},
		},
		{
			key = "UNINSTALL",
			name = L("UNINSTALL.name", "Uninstall"),
			description = L("UNINSTALL.desc", "Deletes all spawned ores and prevents spawning new ones"),
			renderer = "checkbox",
			default = false,
		},
	},
}
if LOCALIZATION_FOUND then
	table.insert(settingsTemplate[tempKey].settings, 1,
		{
			key = "USE_TRANSLATIONS",
			name = "Use Translations",
			description = "Disable to go back to english. Requires a restart or reloadlua",
			renderer = "checkbox",
			default = true,
		}
	)
end


-- ═══════════════════════════════════════════════════════════════ Spawning ═══════════════════════════════════════════════════════════════

tempKey = "Spawning"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("Group.Spawning", "Spawning").."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "SPAWN_EXTERIOR",
			name = L("SPAWN_EXTERIOR.name", "Allow spawning in exteriors"),
			description = L("SPAWN_EXTERIOR.desc", "If you disable this, the ores will only spawn in interiors"),
			renderer = "checkbox",
			default = true,
		},
		{
			key = "ALLOW_CITIES",
			name = L("ALLOW_CITIES.name", "Allow spawning in cities"),
			description = L("ALLOW_CITIES.desc", ""),
			renderer = "checkbox",
			default = true,
		},
		{
			key = "SUNS_DUSK_FILTER",
			name = L("SUNS_DUSK_FILTER.name", "Sun's Dusk Interior Filter"),
			description = L("SUNS_DUSK_FILTER.desc", "Lets interior ores only spawn in caves and mines, even if there's a rocky section somewhere"),
			renderer = "checkbox",
			default = false,
		},
		{
			key = "INTERIOR_MULT",
			name = L("INTERIOR_MULT.name", "Interior Ore (%)"),
			description = L("INTERIOR_MULT.desc", "Amount scales with area size"),
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 800,
				step = 10,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.None", "None"),
				maxLabel = L("label.Many", "Many"),
				width = 150,
			},
		},
		{
			key = "EXTERIOR_NODES",
			name = L("EXTERIOR_NODES.name", "Exterior Ores per cell"),
			description = L("EXTERIOR_NODES.desc", "How many nodes on average?"),
			renderer = RENDERER_SLIDER,
			default = 2.8,
			argument = {
				min = 0,
				max = 8,
				step = 0.2,
				default = 2.8,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.None", "None"),
				maxLabel = L("label.Many", "Many"),
				width = 150,
			},
		},
		{
			key = "ORE_LEVEL_SCALING",
			name = L("ORE_LEVEL_SCALING.name", "Ore Level Scaling (%)"),
			description = L("ORE_LEVEL_SCALING.desc", "Spawn ores closer to your level\n 0 = normal distribution\n100 = heavily biased towards your level"),
			renderer = RENDERER_SLIDER,
			default = 20,
			argument = {
				min = 0,
				max = 100,
				step = 5,
				default = 20,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.Random", "Random"),
				maxLabel = L("label.Scaled", "Scaled"),
				width = 150,
			},
		},
		{
			key = "ORE_LOOT",
			name = L("ORE_LOOT.name", "Loot in the world (%)"),
			description = L("ORE_LOOT.desc", "This reduces the amount of ore that's laying around.\nAfter all, the mod is called Simply Mining and not Simply Looting and leaving the ebony mine with 50 ebony..."),
			renderer = RENDERER_SLIDER,
			default = 50,
			argument = {
				min = 0,
				max = 100,
				step = 5,
				default = 50,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.None", "None"),
				maxLabel = L("label.Full", "Full"),
				width = 150,
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════ Mining & Yield ════════════════════════════════════════════════════════════

tempKey = "Mining & Yield"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = L("Group.MiningYield", "Mining & Yield").."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "MINING_DIFFICULTY",
			name = L("MINING_DIFFICULTY.name", "Mining Difficulty"),
			description = L("MINING_DIFFICULTY.desc", "0 = easy, 100 = normal, 200 = hard"),
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 300,
				step = 5,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.Easy", "Easy"),
				maxLabel = L("label.Hard", "Hard"),
				width = 150,
			},
		},
		{
			key = "EXP_MULT",
			name = L("EXP_MULT.name", "Experience (%)"),
			description = L("EXP_MULT.desc", "How much armorer or mining exp you receive"),
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 500,
				step = 10,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.None", "None"),
				maxLabel = L("label.Lots", "Lots"),
				width = 150,
			},
		},
		{
			key = "YIELD_EQUALIZER",
			name = L("YIELD_EQUALIZER.name", "Yield Equalizer (%)"),
			description = L("YIELD_EQUALIZER.desc", "Flattens the level scaling so you always get the same amount of ore, even if you dont have the skill"),
			renderer = RENDERER_SLIDER,
			default = 0,
			argument = {
				min = 0,
				max = 100,
				step = 5,
				default = 0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.Skill-based", "Skill-based"),
				maxLabel = L("label.Flat", "Flat"),
				width = 150,
			},
		},
		{
			key = "YIELD_MULT",
			name = L("YIELD_MULT.name", "Yield (%)"),
			description = L("YIELD_MULT.desc", "Multiplies how much ore you receive"),
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 300,
				step = 10,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.None", "None"),
				maxLabel = L("label.Lots", "Lots"),
				width = 150,
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════ Migration ══════════════════════════════════════════════════════════════════

local legacySection = storage.playerSection('Settings'..MODNAME)
if legacySection:get("UNINSTALL") ~= nil then
	local multToPercent = { VOLUME = true, INTERIOR_MULT = true, EXP_MULT = true, YIELD_MULT = true }
	for _, template in pairs(settingsTemplate) do
		local section = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local oldVal = legacySection:get(entry.key)
			if oldVal ~= nil then
				if multToPercent[entry.key] then
					oldVal = oldVal * 100
				end
				section:set(entry.key, oldVal)
			end
		end
	end
	legacySection:reset()
end

-- ═══════════════════════════════════════════════════════════ Register ═══════════════════════════════════════════════════════════════════

for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = ""
}

-- ═══════════════════════════════════════════════════════ Read All Settings ══════════════════════════════════════════════════════════════

function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local section = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local val = section:get(entry.key)
			if val == nil then
				val = entry.default
			end
			_G["S_" .. entry.key] = val
		end
	end
end

readAllSettings()

-- ═══════════════════════════════════════════════════════ Subscribe to Changes ═══════════════════════════════════════════════════════════

for _, template in pairs(settingsTemplate) do
	local section = storage.playerSection(template.key)
	section:subscribe(async:callback(function(_, setting)
		local globalKey = "S_" .. setting
		local oldValue = _G[globalKey]
		_G[globalKey] = section:get(setting)
		if setting == "USE_TRANSLATIONS" then
			core.sendGlobalEvent("SimplyMining_useTranslations", USE_TRANSLATIONS)
		elseif setting == "USE_MINING_SKILL" then
			if S_USE_MINING_SKILL and not G_skillRegistered and registerMiningSkill then
				registerMiningSkill()
			end
		elseif setting == "UNINSTALL" then
			if S_UNINSTALL then
				core.sendGlobalEvent("SimplyMining_removeAllOres", self)
			end
		elseif setting == "SWING_MINING" then
			if S_SWING_MINING then
				mineOre = require"scripts.SimplyMining.SM_mineOre_swing"
			else
				mineOre = require"scripts.SimplyMining.SM_mineOre"
			end
			if miningTooltip then
				miningTooltip:destroy()
				miningTooltip = nil
			end
		end
	end))
end