local async = require('openmw.async')
local storage = require('openmw.storage')

local hudOptions = storage.playerSection('Settings/ShowGoldAmount/HUDOptions')
local interfaceOptions = storage.playerSection('Settings/ShowGoldAmount/InterfaceOptions')
local configPlayer = {}

local function updateConfig()
	configPlayer.hudOptions = hudOptions:asTable()
	configPlayer.interfaceOptions = interfaceOptions:asTable()
end

updateConfig()
hudOptions:subscribe(async:callback(updateConfig))
interfaceOptions:subscribe(async:callback(updateConfig))

return configPlayer