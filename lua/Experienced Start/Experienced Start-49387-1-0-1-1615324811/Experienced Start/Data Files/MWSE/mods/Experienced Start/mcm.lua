local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("Experienced Start.config")

local template = EasyMCM.createTemplate("Experienced Start")
template:saveOnClose("Experienced Start", config)
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

settings:createOnOffButton({
  label = "Lucky Player",
  description = "When this option is on, you will get 1 point in Luck for every level at the cost of other attributes.",
  variable = EasyMCM.createTableVariable {
    id = "luckyPlayer",
    table = config
  }
})

settings:createSlider{
	label = "Focus on Major Skills",
	description = "The percentage of skill increase that is focused on Major skills.",
	min = 50,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "majorFocus",
		table = config
	}
}

settings:createSlider{
	label = "Player Starting Level",
	description = "The level to increase the player to after character creation is finished.",
	min = 2,
	max = 50,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "level",
		table = config
	}
}
