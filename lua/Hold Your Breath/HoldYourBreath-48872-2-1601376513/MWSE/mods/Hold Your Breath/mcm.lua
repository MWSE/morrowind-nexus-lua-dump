local config = require("Hold Your Breath.config")

local template = mwse.mcm.createTemplate("Hold Your Breath")
template:saveOnClose("Hold Your Breath", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"Hold Your Breath\n\n " ..
		"Endurance increases how long you can hold your breath under water.\n\n" ..
		"Does this by changing a GMST, it still uses vanilla hard coded behavior, " ..
		"meaning breath is calculated by GMST at the start of the meter, " ..
		"it will not update while holding your breath. " ..
		"Changes to endurance or MCM settings will not take effect until you surface."
	)
page.noScroll = false

local category = page:createCategory("Settings")

	category:createSlider({
	label = "Base breath meter in seconds",
	description = "Default setting 10",
	min = 1,
	max = 360,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "breathBase", table = config },
})

category:createTextField({
	label = "Breath endurance multiplier",
	description = "Default setting 0.2",
	numbersOnly = true,
	variable = mwse.mcm.createTableVariable{id = "breathMult", table = config },
})

mwse.mcm.register(template)