local mod = require("KeepThis.config")
local config = mod.config

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Keep This",
		config = config,
		defaultConfig = mod.defaultConfig,
	})

	template:saveOnClose(mod.configPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Keep This lets you mark items so their tooltips remind you not to sell or drop them.",
	})

	page:createYesNoButton({
		label = "Enable Keep This",
		description = "When enabled, you can mark and unmark hovered inventory items. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Prevent dropping marked items",
		description = "When enabled, dropped marked items are returned to your inventory. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "preventDropping",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Prevent selling marked items",
		description = "When enabled, barter offers that include marked items are blocked. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "preventSelling",
			table = config,
		}),
	})

	page:createKeyBinder({
		label = "Mark/unmark key",
		description = "Press this key while hovering an inventory item to mark or unmark it. Default: F3",
		keybindName = "mark/unmark item",
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
		description = "Writes Keep This information to MWSE.log. Default: No",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config,
		}),
	})

	page:createButton({
		label = "Remove All Marks",
		buttonText = "Clear",
		description = "Removes all Keep This marks from the current save. Use this to resolve any weirdness between saves/KeepThis versions.",
		callback = function()
			if tes3.player then
				tes3.player.data["KeepThis_markedItems"] = {}
				tes3.messageBox("Keep This: all marks removed.")
			else
				tes3.messageBox("Keep This: no player loaded.")
			end
		end,
	})

	template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)