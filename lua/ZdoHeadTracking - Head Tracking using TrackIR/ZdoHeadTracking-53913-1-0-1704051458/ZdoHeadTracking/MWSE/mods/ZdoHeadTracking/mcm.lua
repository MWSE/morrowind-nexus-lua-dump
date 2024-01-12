local config = require("ZdoHeadTracking.config")

local template = mwse.mcm.createTemplate("ZdoHeadTracking")
template:saveOnClose("ZdoHeadTracking", config)

local page = template:createSideBarPage()
page.label = "General Settings"
page.description = "ZdoHeadTracking," .. config.version .. "\nby zdo"
page.noScroll = false

local category = page

local enableButton = category:createYesNoButton()
enableButton.label = "Enable"
enableButton.description = "Toggle to turn this mod on and off."
enableButton.variable = mwse.mcm:createTableVariable{id = "enable", table = config}

category:createYesNoButton({
	label="Debug",
	description="Log values to MWSE.log. Do not enable this value for too long to avoid log growing out of control",
	variable=mwse.mcm.createTableVariable{id = "debug", table = config}
})

category:createTextField({
	label="File",
	description="File path with head tracking values to read from",
	variable=mwse.mcm.createTableVariable{id = "file", table = config}
})

category:createDecimalSlider({
	label = "Head tracking pitch",
	description = "Looking up/down. 0 to disable",
	min = -1,
	max = 1,
	variable = mwse.mcm:createTableVariable{id = "pitch", table = config}
})

category:createDecimalSlider({
	label = "Head tracking yaw",
	description = "Looking left/right. 0 to disable",
	min = -1,
	max = 1,
	variable = mwse.mcm:createTableVariable{id = "yaw", table = config}
})

category:createDecimalSlider({
	label = "Head tracking roll",
	description = "Turning head around forward axis",
	min = -1,
	max = 1,
	variable = mwse.mcm:createTableVariable{id = "roll", table = config}
})

category:createDecimalSlider({
	label = "Head tracking offset X",
	description = "0 to disable",
	min = -1,
	max = 1,
	variable = mwse.mcm:createTableVariable{id = "x", table = config}
})

category:createDecimalSlider({
	label = "Head tracking offset Y",
	description = "0 to disable",
	min = -1,
	max = 1,
	variable = mwse.mcm:createTableVariable{id = "y", table = config}
})

category:createDecimalSlider({
	label = "Head tracking offset Z",
	description = "0 to disable",
	min = -1,
	max = 1,
	variable = mwse.mcm:createTableVariable{id = "z", table = config}
})

category:createDecimalSlider({
	label = "Head tracking max offset",
	description = "To not get head too detached from the body",
	min = 0,
	max = 100,
	variable = mwse.mcm:createTableVariable{id = "maxHeadOffset", table = config}
})

category:createSlider({
	label = "Head bobbing step length",
	description = "",
	min = 0,
	max = 300,
	variable = mwse.mcm:createTableVariable{id = "stepLength", table = config}
})

category:createDecimalSlider({
	label = "Head bobbing step height",
	description = "",
	min = 0,
	max = 12,
	variable = mwse.mcm:createTableVariable{id = "stepHeight", table = config}
})

category:createDecimalSlider({
	label = "Head bobbing max roll",
	description = "Max roll over forward axis, in degrees",
	min = 0,
	max = 5,
	variable = mwse.mcm:createTableVariable{id = "maxRoll", table = config}
})

mwse.mcm.register(template)