local I = require('openmw.interfaces')

S_FILE_EXP_MULTS = {}
S_SKILL_EXP_MULTS = {}

local settingsTemplate = {}

settingsTemplate.GAMEPLAY = {
	key = 'Settings'..MODNAME..'Gameplay',
	page = MODNAME,
	l10n = "none",
	order = 1,
	name = "Gameplay",
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "GLOBAL_EXP_MULT",
			name = "Experience Mult",
			description = "Experience scales with amount of ingredients and relative recipe level",
			renderer = "number",
			default = 1,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "CRAFTING_SPEED",
			name = "Crafting Speed",
			description = "Multiplier on speed (higher = faster)",
			renderer = "number",
			default = 1,
			argument = {
				min = 0.001,
				max = 1000,
			},
		},
		{
			key = "USE_CRAFTING_SKILL",
			name = "Use Crafting Skill",
			description = "Patch all recipes to use 'Crafting' instead of 'Armorer'",
			renderer = "checkbox",
			default = true,
		},
	}
}

settingsTemplate.UI = {
	key = 'Settings'..MODNAME..'UI',
	page = MODNAME,
	l10n = "none",
	order = 2,
	name = "UI",
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "MAX_RECIPES",
			name = "Max Recipes",
			description = "Determines window height",
			renderer = "number",
			default = 21,
			argument = {
				min = 2,
				max = 100,
			},
		},
		{
			key = "FONT_SIZE",
			name = "Font Size",
			description = "Affects window width",
			renderer = "number",
			default = 21,
			argument = {
				min = 7,
				max = 100,
			},
		},
		{
			key = "HIDE_VANILLA_WINDOWS",
			name = "Hide Vanilla Windows",
			description = "When opening the crafting window, hide Map/Stats/Magic/Inventory",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "USE_VANILLA_COLORS",
			name = "Use Vanilla Colors",
			description = "Use original Morrowind colors instead of reading them from GMSTs (e.g. when using a theme replacer)",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "SCROLL_WRAP_MODE",
			name = "Scroll Wrap",
			description = "Behavior when scrolling past the top or bottom of the recipe list.\nFree: wraps instantly.\nResistance: brief gate at edge before wrapping.\nNone: clamps at edge",
			renderer = "select",
			default = "Resistance",
			argument = {
				disabled = false,
				l10n = "none",
				items = {"Free", "Resistance", "None"},
			},
		},
	}
}

table.insert(onActiveFunctions, function()
	if I.TimeFlies and I.TimeFlies.enableCraftingFrameworkSetting  then
		if I.TimeFlies.enableCraftingFrameworkSetting() then
			HAS_TIME_FLIES = true
			local settingsSection = storage.playerSection("SettingsTimeFliesCRAFTING")
			settingsSection:subscribe(async:callback(function (_,setting)
				S_CRAFTING_TIME = settingsSection:get("CRAFTING_TIME")
			end))
			S_CRAFTING_TIME = settingsSection:get("CRAFTING_TIME")
		end
	end
end)

------------------------------ register ------------------------------

for _, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = MODNAME,
	description = ""
}

------------------------------ read ------------------------------

local function readAllSettings()
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
	-- derived
	S_DESCRIPTION_WIDTH = math.floor(S_FONT_SIZE * 22.71)
	S_LIST_WIDTH = math.floor(S_FONT_SIZE * 15.86)
end

readAllSettings()

------------------------------ subscribe ------------------------------

for _, template in pairs(settingsTemplate) do
	local section = storage.playerSection(template.key)
	section:subscribe(async:callback(function(_, setting)
		_G["S_" .. setting] = section:get(setting)
		S_DESCRIPTION_WIDTH = math.floor(S_FONT_SIZE * 22.71)
		S_LIST_WIDTH = math.floor(S_FONT_SIZE * 15.86)
		if setting == "USE_VANILLA_COLORS" and refreshColors then
			refreshColors()
		end
	end))
end

------------------------------ dynamic exp mults ------------------------------

-- MCM keys must be safe identifiers
local function sanitizeKey(s)
	return (s:gsub("[^%w]", "_"))
end

-- called from parseRecipes after all recipes are loaded
function registerDynamicExpMults(files, skills)
	-- per-file group
	local fileSettings = {}
	local fileKeyToName = {}
	for _, filename in ipairs(files) do
		local key = sanitizeKey(filename)
		fileKeyToName[key] = filename
		table.insert(fileSettings, {
			key = key,
			name = filename,
			renderer = "number",
			default = 1,
			argument = { min = 0, max = 1000 },
		})
	end
	local fileTemplate = {
		key = "Settings" .. MODNAME .. "FileExpMults",
		page = MODNAME,
		l10n = "none",
		order = 100,
		name = "Per-File Exp Mults",
		description = "Experience multiplier applied to recipes from each recipe file",
		permanentStorage = true,
		settings = fileSettings,
	}
	I.Settings.registerGroup(fileTemplate)

	-- per-skill group
	local skillSettings = {}
	local skillKeyToName = {}
	for _, skillId in ipairs(skills) do
		local key =  sanitizeKey(skillId)
		local name = getSkillName(skillId)
		skillKeyToName[key] = skillId
		table.insert(skillSettings, {
			key = key,
			name = name,
			renderer = "number",
			default = skillId == "armorer" and 0.72 or 1,
			argument = { min = 0, max = 1000 },
		})
	end
	local skillTemplate = {
		key = "Settings" .. MODNAME .. "SkillExpMults",
		page = MODNAME,
		l10n = "none",
		order = 101,
		name = "Per-Skill Exp Mults",
		description = "Experience multiplier applied to each skill",
		permanentStorage = true,
		settings = skillSettings,
	}
	I.Settings.registerGroup(skillTemplate)

	-- read
	local fileSection = storage.playerSection(fileTemplate.key)
	for key, filename in pairs(fileKeyToName) do
		local val = fileSection:get(key)
		if val == nil then val = 1 end
		S_FILE_EXP_MULTS[filename] = val
	end

	local skillSection = storage.playerSection(skillTemplate.key)
	for key, skillId in pairs(skillKeyToName) do
		local val = skillSection:get(key)
		if val == nil then val = 1 end
		S_SKILL_EXP_MULTS[skillId] = val
	end

	-- subscribe
	fileSection:subscribe(async:callback(function(_, setting)
		if setting and fileKeyToName[setting] then
			S_FILE_EXP_MULTS[fileKeyToName[setting]] = fileSection:get(setting)
		end
	end))
	skillSection:subscribe(async:callback(function(_, setting)
		if setting and skillKeyToName[setting] then
			S_SKILL_EXP_MULTS[skillKeyToName[setting]] = skillSection:get(setting)
		end
	end))
end