local config = require("AttackChance.config")

----------------------
-- Template --
----------------------
local template = mwse.mcm.createTemplate{name = "AttackChance"}

local preferences = template:createSideBarPage{label = "Settings" }

local settings = preferences:createCategory{label = "Settings"}
settings:createOnOffButton{
    label = "Enable mod",
    variable = mwse.mcm:createTableVariable{
        id = "enableMod",
        table = config,
		restartRequired = false,
    }
}
settings:createOnOffButton{
    label = "Enable debug",
    variable = mwse.mcm:createTableVariable{
        id = "enableDebug",
        table = config,
		restartRequired = false,
    }
}
settings:createOnOffButton{
    label = "Change player",
    variable = mwse.mcm:createTableVariable{
        id = "changePlayer",
        table = config,
		restartRequired = false,
    }
}
settings:createSlider{
	label = "Min chance for player",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "chancePlayerMin",
		table = config,
		restartRequired = false,
	})
}
settings:createSlider{
	label = "Max chance for player",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "chancePlayerMax",
		table = config,
		restartRequired = false,
	})
}
settings:createOnOffButton{
    label = "Change NPCs",
    variable = mwse.mcm:createTableVariable{
        id = "changeNpc",
        table = config,
		restartRequired = false,
    }
}
settings:createSlider{
	label = "Min chance for NPCs",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "chanceNpcMin",
		table = config,
		restartRequired = false,
	})
}
settings:createSlider{
	label = "Max chance for NPCs",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "chanceNpcMax",
		table = config,
		restartRequired = false,
	})
}

template:saveOnClose("AttackChance", config)
template:register()
