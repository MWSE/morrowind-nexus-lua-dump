local async = require('openmw.async')
local storage = require('openmw.storage')

local options = storage.playerSection('Settings/ClickToCloseMenu/ClientOptions')
local configPlayer = {}

local function updateConfig()
	configPlayer.options = options:asTable()
end

updateConfig()
options:subscribe(async:callback(updateConfig))

return configPlayer