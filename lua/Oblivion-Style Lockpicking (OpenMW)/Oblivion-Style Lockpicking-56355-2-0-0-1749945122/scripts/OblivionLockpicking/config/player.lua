local async = require('openmw.async')
local storage = require('openmw.storage')

local keybinds = storage.playerSection('Settings/OblivionLockpicking/1_Keybinds')
local options = storage.playerSection('Settings/OblivionLockpicking/2_ClientOptions')
local configPlayer = {}

local function updateConfig()
	configPlayer.keybinds = keybinds:asTable()
	configPlayer.options = options:asTable()
end

updateConfig()
keybinds:subscribe(async:callback(updateConfig))
options:subscribe(async:callback(updateConfig))

return configPlayer