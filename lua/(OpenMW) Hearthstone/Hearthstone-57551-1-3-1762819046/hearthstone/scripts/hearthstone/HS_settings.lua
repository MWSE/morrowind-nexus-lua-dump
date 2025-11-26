local I = require('openmw.interfaces')

local settingTemplate = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = "none",
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "CLOCK_INTERVAL",
			name = "Clock Interval",
			description = "Update the clock every x minutes in-game.\nDefault is 15",
			renderer = "number",
			integer = true,
			default = 15,
			argument = {
				min = 1,
				max = 60,
			},
		},
		{
			key = "HUD_DISPLAY",
			name = "HUD Display",
			description = "When to display the HUD/widget element. Interface = when menus are pulled up",
			default = "Always", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Always", "Never", "Interface Only", "Hide on Interface"}
			},
		},
	}
}

I.Settings.registerGroup(settingTemplate)

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = ""
}

function readAllSettings()
	for i, entry in pairs(settingTemplate.settings) do
		_G[entry.key] = settingsSection:get(entry.key)
	end
end

readAllSettings()

local updateSettings = function (_,setting)
	--print(setting.." changed to "..settingsSection:get(setting))
	readAllSettings()
	
end

settingsSection:subscribe(async:callback(updateSettings))