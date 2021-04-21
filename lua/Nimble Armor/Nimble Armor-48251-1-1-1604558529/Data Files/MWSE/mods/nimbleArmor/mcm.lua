local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("nimbleArmor.config")

local template = EasyMCM.createTemplate("Nimble Armor")
template:saveOnClose("nimbleArmor", config)
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
  label = "Unarmored Protection",
  description = "When this option is off, you won't get any armor bonus for your unarmored skill, making it fully focused on evading attacks.",
  variable = EasyMCM.createTableVariable {
    id = "unarmored",
    table = config
  }
})

settings:createSlider{
	label = "Evasion Contribution",
	description = "The highter this value, the more your armor, or its absense, contributes to your evasion modifier. Referenced value is an evasion modifier of a character with 100 Unarnored Skill, no armor equipped and no other sources of evasion.",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "evasion",
		table = config
	}
}

settings:createSlider{
	label = "Armor Type Penalty",
	description = "The highter this value, the more penalized you are for wearing heavier types of armor. You get no penalty to your evasion for being unarmored, once the penalty for light, twice the penalty for medium and three times the penalty for heavy armor.",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "step",
		table = config
	}
}
