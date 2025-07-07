local async = require('openmw.async')

settings = {
    key = 'SettingsPlayer'..MODNAME,
    page = MODNAME,
    l10n = "ImprovedVanillaLeveling",
    name = "ImprovedVanillaLeveling",
	description = "",
    permanentStorage = true,
    settings = {
		
		{
			key = "keepAttributeProgress",
			name = "Keep attribute progress",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "retroactiveHealth",
			name = "Retroactive Health",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "cappedAt100",
			name = "Capped at 100",
			description = "Discard skill ups when the governing attribute is at 100",
			renderer = "checkbox",
			default = true
		},
	}
}




local function updateSettings()

end


I.Settings.registerGroup(settings)


I.Settings.registerPage {
    key = MODNAME,
    l10n = "ImprovedVanillaLeveling",
    name = "ImprovedVanillaLeveling",
    description = ""
}


playerSection:subscribe(async:callback(updateSettings))
return true