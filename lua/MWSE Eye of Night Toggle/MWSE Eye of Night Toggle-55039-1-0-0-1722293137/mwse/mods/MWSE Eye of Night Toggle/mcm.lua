local config = require("MWSE Eye of Night Toggle.config")

local template = mwse.mcm.createTemplate("MWSE Eye of Night Toggle")
template:saveOnClose("MWSE Eye of Night Toggle", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description = 
	(
		"MWSE Eye of Night Toggle replicates the original Eye of Night Toggle mod with" ..
		"an MWSE menu allowing a configurable Night Eye effect."
	)
page.noScroll = false

local category = page:createCategory("Settings")

local makeNightEyeLevel = category:createSlider({
	label = "Night Eye Level: %s%%",
	description = "Determines the level of Night Eye effect added to player.\n\nDefault: 20%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "nightEyeLevel", table = config },
})

mwse.mcm.register(template)