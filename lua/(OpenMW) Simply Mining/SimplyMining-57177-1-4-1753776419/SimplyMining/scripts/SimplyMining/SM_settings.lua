local I = require('openmw.interfaces')

settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "UNINSTALL",
			name = "Uninstall",
			description = "Deletes all spawned ores and prevents spawning new ones\nYou have to be outside for this to work when toggling this option on!",
			renderer = "checkbox",
			default = false,
		},
		
		
	}
}

local updateSettings = function (_,setting)
	if playerSection:get("UNINSTALL") then
		core.sendGlobalEvent("SimplyMining_removeAllOres", self)
	end
end
playerSection:subscribe(async:callback(updateSettings))


I.Settings.registerGroup(settings)

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = ""
}