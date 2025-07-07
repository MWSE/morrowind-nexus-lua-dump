local async = require('openmw.async')
local storage = require('openmw.storage')

local keybinds = storage.playerSection('Settings/Keytar/1_Keybinds')
local configPlayer = {}

local function updateConfig()
	configPlayer.keybinds = keybinds:asTable()
end

updateConfig()
keybinds:subscribe(async:callback(updateConfig))

return configPlayer