--- Setup MCM.
local function registerModConfig()
	local config = require("rfuzzo.ImmersiveBosmerDisposal.config")
	local template = mwse.mcm.createTemplate(config.mod)
	template:saveOnClose(config.file, config)
	template:register()

	local page = template:createSideBarPage({ label = "Settings" })
	page.sidebar:createInfo{ text = ("%s v%.1f\n\nBy %s"):format(config.mod, config.version, config.author) }

	local settings = page:createCategory("Settings")

	settings:createOnOffButton({
		label = "Only enable for Bosmer.",
		description = "Only enable corpse eating if you are playing as a Bosmer.",
		variable = mwse.mcm.createTableVariable { id = "isBosmerOnly", table = config },
	})

	settings:createOnOffButton({
		label = "Only enable for Green Pact classes",
		description = "Only enable corpse eating if your class contains the words 'green pact'.",
		variable = mwse.mcm.createTableVariable { id = "isGreenPactOnly", table = config },
	})

end

event.register("modConfigReady", registerModConfig)
