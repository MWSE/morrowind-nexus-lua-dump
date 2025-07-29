local I = require('openmw.interfaces')

settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "SKILL_MULT",
			name = "Mult Skills",
			description = "",
			renderer = "number",
			default = 0.6,
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
			default = 1,
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
			default = 20,
			argument = {
				min = 0,
				max = 1000,
			},
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
			key = "HARDCORE_PENALTY",
			name = "Hardcore Penalty Mult",
			description = "Increase Challenge requirements by this factor when dying for the first time",
			renderer = "number",
			default = 1.8,
			argument = {
				min = 0,
				max = 10,
			},
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
				min = 1,
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
			key = "DETECT_INGREDIENTS",
			name = "Detect Ingredients",
			description = "If you picked the herbalist blessing (requires up-to-date HUDMarkers on blessing selection)",
			renderer = "checkbox",
			default = true,
		},
		
		
	}
}

local updateSettings = function (_,setting)
	if saveData and saveData.blessings and saveData.blessings.herbalist and I.HUDMarkers and I.HUDMarkers.version >= 6 then
		if playerSection:get("DETECT_INGREDIENTS") then
			I.HUDMarkers.setIngredientBonus("Roguelite", 120)
			I.HUDMarkers.setHerbBonus("Roguelite", 120)
		else
			I.HUDMarkers.setIngredientBonus("Roguelite", 0)
			I.HUDMarkers.setHerbBonus("Roguelite", 0)
		end
	end
end
playerSection:subscribe(async:callback(updateSettings))


I.Settings.registerGroup(settings)

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = ""
}