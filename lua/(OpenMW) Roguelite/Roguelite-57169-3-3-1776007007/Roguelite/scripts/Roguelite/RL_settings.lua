local I = require('openmw.interfaces')

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local settingsTemplate = {}
local tempKey

tempKey = "General"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey,
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "SKILL_MULT",
			name = "Mult Skills",
			description = "",
			renderer = "number",
			default = 0.75,
			argument = {
				min = 0,
				max = 10,
			},
		},
		{
			key = "SKILL_SUBTRACT",
			name = "Subtract Skills",
			description = "",
			renderer = "number",
			default = 1,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "ATTRIBUTE_MULT",
			name = "Mult Attributes",
			description = "",
			renderer = "number",
			default = 0.95,
			argument = {
				min = 0,
				max = 10,
			},
		},
		{
			key = "ATTRIBUTE_SUBTRACT",
			name = "Subtract Attributes",
			description = "",
			renderer = "number",
			default = 12,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "HALF_SPEED_MALUS",
			name = "Half speed malus",
			description = "makes it much less painful by only applying half of the maluses to your speed attribute",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "CHALLENGE_DIFFICULTY",
			name = "Challenge difficulty",
			description = "Multiplier for Challenge difficulty",
			renderer = "number",
			default = 1,
			argument = {
				min = 0,
				max = 10,
			},
		},
		{
			key = "DYING_PENALTY",
			name = "Dying Penalty (%)",
			description = "Increase Challenge requirements by this percentage when dying",
			renderer = "number",
			default = 60,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "PENALTY_PER_DEATH",
			name = "Dying Penalty PER DEATH?",
			description = "if this is disabled, only the first death will increase the challenge requirements",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "EXTRA_BLESSINGS",
			name = "Extra blessings",
			description = "Increase your amount of blessings",
			renderer = "number",
			default = 1,
			argument = {
				min = -100000,
				max = 100000,
			},
		},
		{
			key = "SELECTABLE_CHALLENGES",
			name = "Selectable Challenges",
			description = "Select how many challenges you can pick up for your run",
			renderer = "number",
			default = 1,
			argument = {
				min = 0,
				max = 100000,
			},
		},
		{
			key = "CHALLENGES_TARGET",
			name = "Challenges Target",
			description = "Select how many challenges you have to complete to unlock a new blessing",
			renderer = "number",
			default = 1,
			argument = {
				min = 1,
				max = 100000,
			},
		},
		{
			key = "ONE_UNLOCK_PER_RUN",
			name = "Only one unlock per run",
			description = "Disable this to get another blessing every time you complete x challenges",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "SHOW_ON_EXIT_INVENTORY",
			name = "Show tracker on exiting inventory",
			description = "If not, only shows the tracker when making progress",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "DETECT_INGREDIENTS",
			name = "Detect Ingredients",
			description = "If you picked the herbalist blessing (requires up-to-date HUDMarkers on blessing selection)",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "FASTER_DUNGEON_UPDATING",
			name = "Recheck dungeon on kill",
			description = "When doing the 'Tomb Raider' challenge, recheck the current dungeon every time you kill an enemy.\nAllows you to see how many enemies are left.\nCauses a lagspike of ~2ms on kill.",
			renderer = "checkbox",
			default = true,
		},
	},
}

-- Settings Migration from legacy single-group format
local legacySection = storage.playerSection('Settings'..MODNAME)
if legacySection:get("SKILL_MULT") then
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local legacyValue = legacySection:get(entry.key)
			if legacyValue ~= nil then
				settingsSection:set(entry.key, legacyValue)
			end
		end
	end
	legacySection:reset()
end

-- Register all groups and page
for _, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = MODNAME,
	description = "",
}

-- Read all settings into S_ prefixed globals
local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G["S_"..entry.key] = newValue
		end
	end
end

readAllSettings()

-- Subscribe to changes per section
for _, template in pairs(settingsTemplate) do
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function(_, setting)
		
		_G["S_"..setting] = settingsSection:get(setting)

		-- HUDMarkers integration for herbalist blessing
		if setting == "DETECT_INGREDIENTS" then
			if saveData and saveData.blessings and saveData.blessings.herbalist and I.HUDMarkers and I.HUDMarkers.version >= 6 then
				if S_DETECT_INGREDIENTS then
					I.HUDMarkers.setIngredientBonus("Roguelite", 90)
					I.HUDMarkers.setHerbBonus("Roguelite", 90)
				else
					I.HUDMarkers.setIngredientBonus("Roguelite", 0)
					I.HUDMarkers.setHerbBonus("Roguelite", 0)
				end
			end
		end
	end))
end