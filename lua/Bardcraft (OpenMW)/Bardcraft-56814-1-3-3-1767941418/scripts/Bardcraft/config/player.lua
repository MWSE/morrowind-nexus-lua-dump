local async = require('openmw.async')
local storage = require('openmw.storage')

local keybinds = storage.playerSection('Settings/Bardcraft/1_Keybinds')
local options = storage.playerSection('Settings/Bardcraft/2_PlayerOptions')
local configPlayer = {}

local function updateConfig()
	configPlayer.keybinds = keybinds:asTable()
	configPlayer.options = options:asTable()
end

updateConfig()
keybinds:subscribe(async:callback(updateConfig))
options:subscribe(async:callback(updateConfig))

return configPlayer