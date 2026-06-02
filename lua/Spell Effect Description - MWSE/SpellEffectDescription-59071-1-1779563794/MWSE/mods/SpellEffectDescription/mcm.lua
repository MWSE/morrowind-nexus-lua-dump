local configModule = require("SpellEffectDescription.config")
local config = configModule.current

local modName = "Spell Effect Description"

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = modName,
	})

	template:saveOnClose(configModule.configPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Adds magic effect descriptions to spell, scroll, potion, enchanted item, ingredient, and spell vendor tooltips.",
	})

	page:createYesNoButton({
		label = "Enable",
		description = "Turns Spell Effect Description on or off.",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Hold to Activate",
		description = "Only show added effect descriptions while holding the selected key.",
		variable = mwse.mcm.createTableVariable({
			id = "holdToActivate",
			table = config,
		}),
	})

	page:createKeyBinder({
		label = "Button to Hold",
		description = "Key used when Hold to Activate is enabled. Default: I.",
		variable = mwse.mcm.createTableVariable({
			id = "holdKey",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Output Debug Logs",
		description = "Writes extra troubleshooting lines to MWSE.log.",
		variable = mwse.mcm.createTableVariable({
			id = "debug",
			table = config,
		}),
	})

	template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)