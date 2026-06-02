local config = require("InteractiveLockpick.config")

local function registerModConfig()
	local modName = "Interactive Lockpick"
	local configPath = "InteractiveLockpick"

	local template = mwse.mcm.createTemplate({
		name = modName,
	})

	template:saveOnClose(configPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Settings for Interactive Lockpick.",
	})

	page:createYesNoButton({
		label = "Enable Mod",
		description = "Enable or disable Interactive Lockpick. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
		}),
	})

	page:createCycleButton({
		label = "Open Menu With",
		description = "Choose how Interactive Lockpick opens. Default: Lockpick Use",
		options = {
			{
				text = "Lockpick Use",
				value = "lockpickUse",
			},
			{
				text = "Interact",
				value = "interact",
			},
			{
				text = "Either",
				value = "either",
			},
		},
		variable = mwse.mcm.createTableVariable({
			id = "lockpickOpenMode",
			table = config,
		}),
	})

	page:createSlider({
		label = "Maximum Sliders",
		description = "Maximum number of lockpick pins/sliders that can appear in the lockpick menu. Default: 8",
		min = 3,
		max = 8,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createTableVariable({
			id = "maximumSliders",
			table = config,
		}),
	})

	page:createCategory({
		label = "Debug",
	})

	page:createYesNoButton({
		label = "Show Messages",
		description = "Show in-game messages. Default: No",
		variable = mwse.mcm.createTableVariable({
			id = "debugMessages",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Debug Log",
		description = "Print debug info to MWSE.log. Default: No",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config,
		}),
	})

	mwse.mcm.register(template)
end

event.register(tes3.event.modConfigReady, registerModConfig)