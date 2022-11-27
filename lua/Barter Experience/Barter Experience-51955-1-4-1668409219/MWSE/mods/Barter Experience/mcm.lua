--Mod by Muggins because nothing like this exists yet afaik--

local EasyMCM = require("EasyMCM.EasyMCM")
local config = require("Barter Experience.config")
local template = EasyMCM.createTemplate ("Barter Experience")
template:saveOnClose("Barter Experience", config)
template:register()

local page = template:createSideBarPage({
    label = "Settings",
})

local settings = page:createCategory("Settings")

settings:createOnOffButton({
  label = "Mod Enabled",
  description = "Current Status of the mod. Restart the game after changing this option.",
  variable = EasyMCM.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

settings:createSlider{
	label = "Flat Rate",
	description = "The highter this value, the more experience you get for every trade. 100 is 10xp per trade. Set this to 0 to disable this feature. Default: 10",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "FlatRate",
		table = config
	}
}

settings:createSlider{
	label = "Value Rate",
	description = "The highter this value, the more experience you get proportional to the trade value. 100 is 1% of total value. Set this to 0 to disable this feature. Default: 20",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "ValueRate",
		table = config
	}
}