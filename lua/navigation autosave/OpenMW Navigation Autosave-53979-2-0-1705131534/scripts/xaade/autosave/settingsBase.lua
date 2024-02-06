local storage = require('openmw.storage')

local navigationAutosaveGroup = 'SettingsOMWNavigationAutosave'

local settingsBase = {
    navigationAutosaveGroup = navigationAutosaveGroup,
	getNavigationAutosaveSetting = function(settingsName)
		return storage.playerSection(navigationAutosaveGroup):get(settingsName)
	end
}

return settingsBase