local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("Krimson.Breakable Unlimited Thieves Tools.config")

local template = EasyMCM.createTemplate("B. U. T. T.")
template:saveOnClose("Krimson.Breakable Unlimited Thieves Tools", config)
template:register()

local page = template:createSideBarPage({
  label = "Settings",
})

local settings = page:createCategory("Settings")

settings:createOnOffButton({
  label = "Unlimited Uses On/Off",
  description = "Enables unlimited uses on all picks and probes.\n\nRestart the game for menu UI changes to take effect.\n\nDefault: On\n\n",
  variable = EasyMCM.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

settings:createOnOffButton({
    label = "Breaking On/Off",
    description = "Enables breaking chance for picks and probes on each use.\n\nRegardless of settings, with this ON all lockpicks and probes have a minimum 1% chance to break on use.\nWith the exception of the Skeleton Key and the Secret Master's Lockpick/Probe, which will never break as long as Unlimited uses is turned ON.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
      id = "breakEnabled",
      table = config
    }
  })

settings:createSlider{
	label = "Lockpicks % chance to break",
	description = "No effect unless Breaking is enabled.\n\n% chance is modified by the lockpicks Quality, your base Security skill, your base Intelligence, and base your Luck.\n\nDefault: 50\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "basePick",
		table = config
	}
}

settings:createSlider{
	label = "Probes % chance to break",
	description = "No effect unless Breaking is enabled.\n\n% chance is modified by the probes Quality, your base Security skill, your base Intelligence, and base your Luck.\n\nDefault: 50\n\n",
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "baseProbe",
		table = config
	}
}