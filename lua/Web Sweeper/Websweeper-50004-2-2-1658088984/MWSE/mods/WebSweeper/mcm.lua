local config = require("WebSweeper.config")
local template = mwse.mcm.createTemplate("WebSweeper")
template:saveOnClose("WebSweeper", config)
local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"Web Sweeper\n\n" ..
		"Clean spider webs by attacking them.\n\n" ..
		"Harvest ingredients if\n\n" ..
		"SpiderSilk.esp is loaded\n\n"
	)
page.noScroll = false
local category = page:createCategory("Settings")
	category:createSlider({
	label = "Respawn Chance",
	description = "Chance of respawn when cell loads.\n\n" .. "Default setting 10",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "respawnChance", table = config },
})
category:createSlider({
	label = "Distance",
	description = "Maximum distance from web for attack event",
	min = 1,
	max = 200,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "dist", table = config },
})
mwse.mcm.register(template)