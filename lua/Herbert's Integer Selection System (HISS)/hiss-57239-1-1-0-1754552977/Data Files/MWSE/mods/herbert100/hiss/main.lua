-- The actual mod is in `mod.lua`, for livecoding reasons.
-- This file contains just a require statement and the MCM code.
require("herbert100.hiss.mod")


event.register(tes3.event.modConfigReady, function(e)
	local cfg = require("herbert100.hiss.config")
	local default_cfg = require("herbert100.hiss.config.default")
	local log = mwse.Logger.new()

	local template = mwse.mcm.createTemplate {
		name = log.modName,
		config = cfg,
		defaultConfig = default_cfg,
		showDefaultSetting = true,
		onClose = function(modConfigContainer)
			mwse.saveConfig(log.modName, cfg)
		end
	}

	template:register()


	local page = template:createSideBarPage {
		label = "Settings",
		description = "Herbert's Integer Selection System\n\n\z
			This mod allows several in-game menus to be navigated using the 0-9 number keys. Some menus can also be closed by pressing Escape.\n\n\z
			The \"Allowed Menus\" page lets you control which menus the mod is enabled for.\n\n\z
			The logging level can be useful for debugging and for finding the IDs of certain menus.\n\n\z
			This mod also supports the Book and Scroll menus, but they are disabled by default because the button prompts will not be updated, \z
			even if the relevant setting is enabled.\n\z
			If enabling the mod for the book and scroll menu, the controls are:\n\z
			1) Take\n\z
			2) Close\n\z
			3) Next Page\n\z
			4) Previous Page\n\z
		"
	}
	page:createYesNoButton {
		label = "Try to make button layouts vertical",
		description = "If enabled, this mod will attempt to make the button layouts of certain menus be vertical instead of horizontal",
		configKey = "make_top_to_bottom",
	}
	page:createYesNoButton {
		label = "Escape Means \"Close\"",
		description = "Pressing the esape button will result in clicking the \"Close\" button.\n\n\z
			Note: This will not change the labeling of buttons. \z
			(i.e., the \"Esc\" prompt will not be shown, but pressing the escape button will still close the menu.)\z
		",
		configKey = "esc_presses_close_button",
	}
	page:createYesNoButton {
		label = "Escape Means \"No\"",
		description = "Pressing the esape button will result in clicking the \"No\" button.\n\n\z
			Note: This will not change the labeling of buttons. \z
			(i.e., the \"Esc\" prompt will not be shown, but pressing the escape button will still close the menu.)\z
		",
		configKey = "esc_presses_no_button",
	}
	page:createYesNoButton {
		label = "Update button labels",
		description = 'If enabled, then button labels will be updated to display a numeric prompt.\n\n\z
			For example, if the options for a menu are "Yes" and "No", they will be updated to "1) Yes" and "2) No".\z
		',
		configKey = "update_button_text",
	}

	page:createLogLevelOptions { logger = log, configKey = "log_level" }

	template:createExclusionsPage {
		label = "Allowed Menus",
		description = "On this page you can toggle which menus the mod works for.\n\z
		MenuBook and MenuScroll won't update button prompts, even if the relevant setting is turned on.\n\z
		MenuContents is disabled by default because it can interact strangely with the search functionality in UI Expansion.",
		configKey = "valid_menu_names",
		leftListLabel = "Allowed",
		rightListLabel = "Not Allowed",
		filters = {
			{
				label = "Menu Ids",
				callback = function()
					return table.keys(default_cfg.valid_menu_names, true)
				end
			}
		},
	}

	log:writeInitMessage()
end)
