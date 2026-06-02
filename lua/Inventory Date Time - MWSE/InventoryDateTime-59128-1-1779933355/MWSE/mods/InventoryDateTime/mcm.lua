local mod = require("InventoryDateTime.config")
local config = mod.config

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Inventory Date Time",
		config = config,
		defaultConfig = mod.defaultConfig,
	})

	template:saveOnClose(mod.configPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Shows the date and time in your inventory and/or after resting or waiting.",
	})

	page:createYesNoButton({
		label = "Enable Inventory Date/Time",
		description = "Shows the date/time display in the inventory. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "enableInventory",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Enable Rest/Wait Message",
		description = "Shows the date/time message after resting or waiting. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "enableRestWaitMessage",
			table = config,
		}),
	})

	local formatField = page:createTextField({
		label = "Date/Time Format",
		description = "Custom format. Tokens: %W = weekday, %M = month, %D = day, %Y = year, %T = time, %N = day number.",
		variable = mwse.mcm.createTableVariable({
			id = "dateTimeFormat",
			table = config,
		}),
	})

	page:createButton({
		buttonText = "Set Default",
		description = "Resets the date/time format to the default value.",
		callback = function()
			local defaultFormat = mod.defaultConfig.dateTimeFormat

			config.dateTimeFormat = defaultFormat
			formatField:setVariableValue(defaultFormat)

			mwse.saveConfig(mod.configPath, config)

			mwse.log("[Inventory Date Time] Date/time format reset to default: %s", defaultFormat)
		end
	})

	template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)