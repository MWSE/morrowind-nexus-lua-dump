local mod = require("SellThis.config")
local config = mod.config

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Sell This",
		config = config,
		defaultConfig = mod.defaultConfig,
	})

	template:saveOnClose(mod.configPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Sell This lets you mark items you want to sell later. Default: Yes",
	})

	page:createYesNoButton({
		label = "Enable Sell This",
		description = "When enabled, you can mark and unmark hovered items. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
		}),
	})

	page:createKeyBinder({
		label = "Mark/unmark key",
		description = "Press this key while hovering an item to mark or unmark it for selling. Default: F4",
		keybindName = "mark/unmark sell item",
		allowCombinations = false,
		allowMouse = false,
		configKey = "markKeyCombo",
	})

	page:createYesNoButton({
		label = "Show Messages",
		description = "Shows on screen messages. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "showMessages",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Debug logging",
		description = "Writes Sell This information to MWSE.log. Useful while testing. Default: No",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config,
		}),
	})

	page:createButton({
		label = "Remove All Marks",
		buttonText = "Clear",
		description = "Removes all Sell This marks from the current save. Use this to resolve any weirdness between saves/SellThis versions.",
		callback = function()
			if tes3.player then
				tes3.player.data["SellThis_markedItems"] = {}
				tes3.messageBox("Sell This: all marks removed.")
			else
				tes3.messageBox("Sell This: no player loaded.")
			end
		end,
	})

	template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)