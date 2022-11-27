local config = require("NIR.config")
local template = mwse.mcm.createTemplate("NIR")
template:saveOnClose("NIR", config)
local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"NPC's Interrupt Rest\n\n" ..
		"Description.\n\n" ..
		"overrides normal rest interuption with a npc encounter.\n\n" ..
		"Requires NIR.esp\n\n" ..
		"Recommended to use alongside MWSE NPC random face and name generators.\n\n"
	)
page.noScroll = false
local category = page:createCategory("Settings")

	category:createSlider({
	label = "Ascadian Isles",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "aiChance", table = config },
})
	category:createSlider({
	label = "Ashlands",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "alChance", table = config },
})
	category:createSlider({
	label = "Azura's Coast",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "acChance", table = config },
})
	category:createSlider({
	label = "Bitter Coast",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "bcChance", table = config },
})
	category:createSlider({
	label = "Grazelands",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "glChance", table = config },
})
	category:createSlider({
	label = "Molag Amur",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "maChance", table = config },
})
	category:createSlider({
	label = "Red Mountain",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "rmChance", table = config },
})
	category:createSlider({
	label = "Sheogorad",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "sgChance", table = config },
})
	category:createSlider({
	label = "West Gash",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "wgChance", table = config },
})
	category:createSlider({
	label = "Brodir Grove",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "bgChance", table = config },
})
	category:createSlider({
	label = "Felsaad Coast",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "fcChance", table = config },
})
	category:createSlider({
	label = "Hirstaang Forest",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "hfChance", table = config },
})
	category:createSlider({
	label = "Isinfier Plains",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "ipChance", table = config },
})
	category:createSlider({
	label = "Moesring Mountains",
	description = "Chance for Override",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "mmChance", table = config },
})
	category:createOnOffButton({
	label = "test mode",
	description = "Toggle develeloper test mode",
	variable = mwse.mcm:createTableVariable{id = "testmode", table = config},
})
mwse.mcm.register(template)