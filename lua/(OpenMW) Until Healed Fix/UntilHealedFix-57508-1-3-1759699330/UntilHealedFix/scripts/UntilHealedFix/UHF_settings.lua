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
			key = "ENABLED",
			name = "Enabled",
			description = "",
			renderer = "checkbox",
			default = true,
		},	
		{
			key = "SHOW_DEBUG_BOXES",
			name = "Show Debug Boxes",
			description = "Show calculated positions of the Rest Buttons",
			renderer = "checkbox",
			default = false,
		},	
	}
}

I.Settings.registerGroup(settingTemplate)

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = "Workaround to actually stop sleeping when your Resources are full, instead of after the sleep duration the game calculated upfront"
}

function readAllSettings()
	--print("caching settings")
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