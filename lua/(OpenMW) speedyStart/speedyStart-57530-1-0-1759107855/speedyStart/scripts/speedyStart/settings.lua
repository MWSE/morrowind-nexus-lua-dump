local I = require('openmw.interfaces')

local settingTemplate = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
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
			key = "SCALE",
			name = "Time Scale",
			description = "",
			renderer = "number",
			default = 5,
			argument = {
				min = 0.5,
				max = 10,
			},
		},
	}
}

I.Settings.registerGroup(settingTemplate)

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = "Speeds up the game during character creation"
}

function readAllSettings()
	--print("caching settings")
	for i, entry in pairs(settingTemplate.settings) do
		_G[entry.key] = settingsSection:get(entry.key)
	end

end

readAllSettings()

local updateSettings = function (_,setting)
	readAllSettings()
	if not ENABLED then
		core.sendGlobalEvent("speedyStartSetSimulationTimeScale", 1)
	elseif not types.Player.isCharGenFinished(self) then
		core.sendGlobalEvent("speedyStartSetSimulationTimeScale", SCALE)
	end
end

settingsSection:subscribe(async:callback(updateSettings))