local config = require("walk fatigue.config")

local template = mwse.mcm.createTemplate("walk fatigue")
template:saveOnClose("walk fatigue", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"Fatigues player while walking."
	)
page.noScroll = false

local category = page:createCategory("Settings")

	category:createSlider({
	label = "Fatigue loss",
	description = "Amount of fatigue used per second while walking",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "staminaLoss", table = config },
})

mwse.mcm.register(template)