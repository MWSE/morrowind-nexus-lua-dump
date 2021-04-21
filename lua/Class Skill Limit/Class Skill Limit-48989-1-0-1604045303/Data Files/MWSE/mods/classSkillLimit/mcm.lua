local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("classSkillLimit.config")

local template = EasyMCM.createTemplate("Class Skill Limit")
template:saveOnClose("classSkillLimit", config)
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
  label = "Limit Training",
  description = "When this option is off, you will still be able raise your skills beyond their cap via npc training service. I'd recommend to disable this only if you play with a mod, that restricts training per level. Restart the game after changing this option.",
  variable = EasyMCM.createTableVariable {
    id = "limitTraining",
    table = config
  }
})

settings:createSlider{
	label = "Major Skills Limit",
	description = "The cap for you major skills, without taking to account your race bonuses and specialisation.",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "major",
		table = config
	}
}

settings:createSlider{
	label = "Minor Skills Limit",
	description = "The cap for you minor skills, without taking to account your race bonuses and specialisation.",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "minor",
		table = config
	}
}

settings:createSlider{
	label = "Misc Skills Limit",
	description = "The cap for you misc skills, without taking to account your race bonuses and specialisation.",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "misc",
		table = config
	}
}