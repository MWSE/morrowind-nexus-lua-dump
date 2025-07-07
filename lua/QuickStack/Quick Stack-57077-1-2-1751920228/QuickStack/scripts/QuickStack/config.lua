local async = require('openmw.async')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')

local options = storage.playerSection('Settings/QuickStack/Options')
local keybinds = storage.playerSection('Settings/QuickStack/Keybinds')
local config = {}

local function updateConfig()
	config.options = options:asTable()
	config.keybinds = keybinds:asTable()
end
updateConfig()
options:subscribe(async:callback(updateConfig))
keybinds:subscribe(async:callback(updateConfig))

return config