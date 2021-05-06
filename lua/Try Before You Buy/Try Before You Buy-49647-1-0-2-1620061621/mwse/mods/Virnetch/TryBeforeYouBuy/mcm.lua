
local config = require("Virnetch.tryBeforeYouBuy.config")

local template = mwse.mcm.createTemplate("Try Before You Buy")
template:saveOnClose("try_before_you_buy", config)

local page = template:createSideBarPage{
	label = "Settings",
	description = "Adds a new button to the barter window that allows the player to try the equipment before buying it."
}

page:createOnOffButton{
	label = "Limit by item value",
	description = "Limits which items you can try based on their value and your disposition with the seller. Default: On",
	variable = mwse.mcm.createTableVariable{
		id = "enableLimits",
		table = config
	}
}

page:createSlider{
	label = "Max Single Item Value",
	description = "Maximum value of a single item at 50 disposition. Only works if Limit by item value is enabled. Default: 200",
	max = 2000,
	min = 50,
	step = 50,
	jump = 200,
	variable = mwse.mcm.createTableVariable{
		id = "maxSingleValue",
		table = config
	}
}

page:createSlider{
	label = "Max Total Item Value",
	description = "Maximum value of all items combined at 50 disposition. Only works if Limit by item value is enabled. Default: 400",
	max = 2000,
	min = 50,
	step = 50,
	jump = 200,
	variable = mwse.mcm.createTableVariable{
		id = "maxTotalValue",
		table = config
	}
}

page:createOnOffButton{
	label = "Enable Distance Check",
	description = "If enabled, moving too far away from the npc will trigger a crime. Default: On",
	variable = mwse.mcm.createTableVariable{
		id = "distanceCheck",
		table = config
	}
}

page:createSlider{
	label = "Max Distance",
	description = "Moving further than this from the original position will trigger a crime if above setting is enabled. Default: 250",
	max = 2000,
	min = 50,
	step = 50,
	jump = 100,
	variable = mwse.mcm.createTableVariable{
		id = "maxDistance",
		table = config
	}
}
mwse.mcm.register(template)