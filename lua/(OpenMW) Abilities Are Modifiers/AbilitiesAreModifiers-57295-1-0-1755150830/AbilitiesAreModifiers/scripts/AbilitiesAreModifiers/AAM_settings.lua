local I = require('openmw.interfaces')



I.Settings.registerGroup {
	key = "Settings" .. MOD_NAME,
	l10n = MOD_NAME,
	name = "Settings",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "ENABLED",
			name = "Enable",
			description = "Enable or disable the ability buff handling system\nUse before uninstalling",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "DEBUG",
			name = "Debug Mode",
			description = "Print debug information to console",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "WARNINGS",
			name = "Warn About Irregularities",
			description = "Show warnings when modifier values don't match expected ability buffs",
			default = true,
			renderer = "checkbox",
		},
	}
}

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = MOD_NAME,
	description = ""
}

local updateSettings = function (_,setting)
	if ENABLED and not playerSection:get("ENABLED") then
		ENABLED = playerSection:get("ENABLED")
		undoAdjustments()
	elseif not ENABLED and playerSection:get("ENABLED") then
		ENABLED = playerSection:get("ENABLED")
		handleAbilityBuffs()
	else
		ENABLED = playerSection:get("ENABLED")
	end
	
	
end

playerSection:subscribe(async:callback(updateSettings))