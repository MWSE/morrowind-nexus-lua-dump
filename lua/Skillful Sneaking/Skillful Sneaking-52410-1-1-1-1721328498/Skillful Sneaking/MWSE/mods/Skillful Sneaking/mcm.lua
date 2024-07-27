local config = require("Skillful Sneaking.config")

local function registerModConfig()

	local template = mwse.mcm.createTemplate({ name = ("Skillful Sneaking") })
	template:saveOnClose("Skillful Sneaking", config)

	local page = template:createSideBarPage({ label = "Sidebar Page Label" })
	page.sidebar:createInfo({ text = ("Skillful Sneaking") .. " " .. ("1.1.0") .. "\n" .. ("By None") .. "\n\n" .. ("Allows jumping while sneaking and scales movement speed with skill level.") })

	page:createOnOffButton({
		label = ("Enable"),
		description = (""),
		variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
	})

	--Sneak Speed Cap
	page:createSlider({
		label = "Maximum Sneaking Speed",
		description = "Relative to total running speed, measured in percent. A value of 100 allows sneaking speed to be as fast as running. Default is 70.",
		min = 0,
		max = 100,
		step = 1,
		jump = 20,
		variable = mwse.mcm.createTableVariable({ id = "speedCap", table = config }),
	})

	--Jump Height Cap
	page:createSlider({
		label = "Maximum Sneak Jump Height",
		description = "Relative to total a normal jump, measured in percent. A value of 100 allows sneak jumps as high as a normal jump. Default is 80.",
		min = 0,
		max = 100,
		step = 1,
		jump = 20,
		variable = mwse.mcm.createTableVariable({ id = "jumpCap", table = config }),
	})

	--Skill Point Scaling
	page:createSlider({
		label = "Skill Level Scaling",
		description = "The change in sneaking speed relative to skill level. Each skill point will give you this value / 100 in movement speed increase. Default is 300 (3.0/skill point).",
		min = 0,
		max = 500,
		step = 1,
		jump = 50,
		variable = mwse.mcm.createTableVariable({ id = "skillScaling", table = config }),
	})

	template:register()
end

event.register("modConfigReady", registerModConfig)