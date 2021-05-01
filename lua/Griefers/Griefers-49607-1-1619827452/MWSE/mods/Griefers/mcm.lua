local config = require("Griefers.config")
local template = mwse.mcm.createTemplate("Griefers")
template:saveOnClose("Griefers", config)
local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"Griefers\n\n" ..
		"Random chance encounters with hostile NPCs.\n\n" ..
		"Exterior cells only.\n\n" ..
		"Requires Griefers.esp\n\n"
	)
page.noScroll = false
local category = page:createCategory("Settings")
	category:createSlider({
	label = "Base Percent chance of spawn",
	description = "Base chance.\n\n" .. "Default setting 1",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "baseChance", table = config },
})
	category:createOnOffButton({
	label = "Leveled spawn chance",
	description = "Player level added to base spawn chance.",
	variable = mwse.mcm:createTableVariable{id = "leveledSpawn", table = config},
})
	category:createSlider({
	label = "Timer",
	description = "Duration between spawn chances.\n\n" .. "Default setting 500",
	min = 10,
	max = 10000,
	step = 1,
	jump = 100,
	variable = mwse.mcm.createTableVariable{id = "spawnTimer", table = config },
})
category:createSlider({
	label = "Distance",
	description = "Distance of spawns.\n\n" .. "Default setting 2048",
	min = 100,
	max = 10000,
	step = 1,
	jump = 100,
	variable = mwse.mcm.createTableVariable{id = "spawnDist", table = config },
})
mwse.mcm.register(template)