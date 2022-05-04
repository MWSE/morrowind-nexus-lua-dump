--- Setup MCM.
local function registerModConfig()
	local config = require("rfuzzo.LoadingSplashScreens.config")
	local template = mwse.mcm.createTemplate(config.mod)
	template:saveOnClose(config.file, config)
	template:register()

	local page = template:createSideBarPage({ label = "Settings" })
	page.sidebar:createInfo{ text = ("%s v%.1f\n\nBy %s"):format(config.mod, config.version, config.author) }

	local settings = page:createCategory("Settings")

	settings:createSlider{
		label = "Splash Screen Alpha",
		description = "Set the splash screen alpha colour.",
		min = 0,
		max = 100,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable { id = "alpha", table = config },
	}

end

event.register("modConfigReady", registerModConfig)
