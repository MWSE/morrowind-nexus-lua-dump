local config = require("rations.config")
local template = mwse.mcm.createTemplate("rations")
template:saveOnClose("rations", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"rations\n\n " ..
		"\n\n" ..
		"Requires rations.esp\n\n" ..
		"gives members of legion or ashlander factions a chance to have food in their inventory\n\n"
	)
page.noScroll = false

local category = page:createCategory("Settings")

	category:createSlider({
	label = "Legion chance",
	description = "percent chance to add rations to Legion.\n\n" .. "Default setting 10",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "legionChance", table = config },
})

	category:createSlider({
	label = "Ashlander chance",
	description = "percent chance to add rations to Ashlanders.\n\n" .. "Default setting 10",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "ashChance", table = config },
})

mwse.mcm.register(template)