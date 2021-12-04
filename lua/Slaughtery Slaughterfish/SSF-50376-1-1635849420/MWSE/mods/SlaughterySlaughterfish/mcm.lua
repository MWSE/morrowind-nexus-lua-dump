local config = require("SlaughterySlaughterfish.config")

local template = mwse.mcm.createTemplate("SlaughterySlaughterfish")
template:saveOnClose("SlaughterySlaughterfish", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"Slaughterfish attack NPCs that swim near them."
	)
page.noScroll = false

local category = page:createCategory("Settings")

	category:createSlider({
	label = "Detection Rate",
	description = "Time in seconds between running detection script",
	min = 1,
	max = 30,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = "detectRate", table = config },
})


	category:createSlider({
	label = "Detection Range",
	description = "Maximum distance for actor detection",
	min = 1,
	max = 1024,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "detectRange", table = config },
})

mwse.mcm.register(template)