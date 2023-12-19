local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("attackChance.config")

local template = EasyMCM.createTemplate("Attack Chance")
template:saveOnClose("attackChance", config)
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
	label = "Two Handed Blunt",
	description = "Default value -15",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "bluntTwoClose",
		table = config
	},
	defaultSetting = -15,
}

settings:createSlider{
	label = "One Handed Blunt",
	description = "Default value -5",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "bluntOneHand",
		table = config
	},
	defaultSetting = -5,
}

settings:createSlider{
	label = "Staves",
	description = "Default value -10",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "bluntTwoWide",
		table = config
	},
	defaultSetting = -10,
}

settings:createSlider{
	label = "Two Handed Axes",
	description = "Default value -30",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "axeTwoHand",
		table = config
	},
	defaultSetting = -30,
}

settings:createSlider{
	label = "One Handed Axes",
	description = "Default value -20",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "axeOneHand",
		table = config
	},
	defaultSetting = -20,
}

settings:createSlider{
	label = "Spears",
	description = "Default value 10",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "spearTwoWide",
		table = config
	},
	defaultSetting = 10,
}

settings:createSlider{
	label = "Two Handed Longblades",
	description = "Default value 0",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "longBladeTwoClose",
		table = config
	},
	defaultSetting = 0,
}

settings:createSlider{
	label = "One Handed Longblades",
	description = "Default value 10",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "longBladeOneHand",
		table = config
	},
	defaultSetting = 10,
}

settings:createSlider{
	label = "One Handed Shortblades",
	description = "Default value 30",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "shortBladeOneHand",
		table = config
	},
	defaultSetting = 30,
}

settings:createSlider{
	label = "Throwing Weapons",
	description = "Default value 30",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "marksmanThrown",
		table = config
	},
	defaultSetting = 30,
}

settings:createSlider{
	label = "Bows",
	description = "Default value 15",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "marksmanBow",
		table = config
	},
	defaultSetting = 15,
}

settings:createSlider{
	label = "Crossbows",
	description = "Default value 20",
	min = -100,
	max = 100,
	step = 1,
	jump = 5,
	variable = EasyMCM.createTableVariable{
		id = "marksmanCrossbow",
		table = config
	},
	defaultSetting = 20,
}
