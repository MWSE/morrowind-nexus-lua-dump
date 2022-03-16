local config = require("OEA.OEA8+half Ghost.config")

local template = mwse.mcm.createTemplate({ name = "Stop Summoning My Ancestors" })
template:saveOnClose("SSMA", config)

local page = template:createPage()

page:createSlider{
	label = "Number of Dunmer Power Ghosts (Restart to Change):",
	variable = mwse.mcm:createTableVariable{
		id = "Ghosts", 
		table = config
	},
	min = 1,
	max = 8,
	step = 1,
	jump = 2,
}

mwse.mcm.register(template)