local I = require('openmw.interfaces')

settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = "none",
    name = MODNAME,
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
				min = 9,
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
			key = "EXPERIENCE_MULT",
			name = "Experience Mult",
			description = "Experience scales with amount of ingredients and relative recipe level",
			renderer = "number",
			default = 3.1,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		
		
	}
}

local updateSettings = function (_,setting)
	maxRecipes = playerSection:get("MAX_RECIPES") or 21
	textSize = playerSection:get("FONT_SIZE") or 21
	descriptionWidth = math.floor(textSize*22.71)
	listWidth =  math.floor(textSize*15.86)
end
playerSection:subscribe(async:callback(updateSettings))


I.Settings.registerGroup(settings)

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = ""
}