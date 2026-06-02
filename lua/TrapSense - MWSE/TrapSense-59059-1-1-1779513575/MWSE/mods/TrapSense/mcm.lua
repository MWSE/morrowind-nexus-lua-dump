local configPackage = require("TrapSense.config")
local config = configPackage.config
local configPath = configPackage.configPath

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Trap Sense",
		headerImagePath = nil,
	})

	template:saveOnClose(configPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Trap Sense lets your Security skill warn you before opening trapped containers.",
	})

	page:createYesNoButton({
		label = "Enable Trap Sense",
		description = "If enabled, activating a trapped container rolls against your Security skill.",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
		}),
	})

	page:createSlider({
		label = "Maximum Detection Chance",
		description = "Caps the detection chance. The base chance is your Security skill.",
		min = 5,
		max = 100,
		step = 5,
		jump = 5,
		variable = mwse.mcm.createTableVariable({
			id = "maxDetectChance",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Show Messages",
		description = "Shows a message when you detect a trap.",
		variable = mwse.mcm.createTableVariable({
			id = "showMessages",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Show Visual Effect",
		description = "Shows a magical visual effect on containers after their trap is detected.",
		variable = mwse.mcm.createTableVariable({
			id = "showVFX",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Play Discovery Sound",
		description = "Plays a sound when you discover a trapped container.",
		variable = mwse.mcm.createTableVariable({
			id = "playDiscoverySound",
			table = config,
		}),
	})

	page:createTextField({
		label = "Discovery Sound ID",
		description = "The vanilla sound ID played when a trap is discovered. Default: mysticism hit",
		variable = mwse.mcm.createTableVariable({
			id = "discoverySound",
			table = config,
		}),
	})

	page:createSlider({
		label = "Discovery Sound Volume",
		description = "Volume of the trap discovery sound.",
		min = 0.1,
		max = 1.0,
		step = 0.1,
		jump = 0.1,
		variable = mwse.mcm.createTableVariable({
			id = "discoverySoundVolume",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Detect Enchantment Bonus",
		description = "If enabled, having Detect Enchantment active gives a bonus to trap detection.",
		variable = mwse.mcm.createTableVariable({
			id = "useDetectEnchantmentBonus",
			table = config,
		}),
	})

	page:createSlider({
		label = "Detect Enchantment Bonus Amount",
		description = "Extra detection chance added while Detect Enchantment is active.",
		min = 0,
		max = 100,
		step = 5,
		jump = 5,
		variable = mwse.mcm.createTableVariable({
			id = "detectEnchantmentBonus",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Debug Logging",
		description = "Writes Trap Sense debug info to MWSE.log.",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config,
		}),
	})

	mwse.mcm.register(template)
end

event.register(tes3.event.modConfigReady, registerModConfig)