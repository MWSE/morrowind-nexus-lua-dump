local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("classStartingSpells.config")

local template = EasyMCM.createTemplate("Class Starting Spells")
template:saveOnClose("classStartingSpells", config)
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
	label = "Skill Requirements",
	description = "For every magic college in your major and minor skills, you can get up to three spells, depending on your specialization and race proficiencies. The lower this value, the more spells you'll get during the character generation.",
	min = 0,
	max = 20,
	step = 5,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "skillRequirements",
		table = config
	}
}
