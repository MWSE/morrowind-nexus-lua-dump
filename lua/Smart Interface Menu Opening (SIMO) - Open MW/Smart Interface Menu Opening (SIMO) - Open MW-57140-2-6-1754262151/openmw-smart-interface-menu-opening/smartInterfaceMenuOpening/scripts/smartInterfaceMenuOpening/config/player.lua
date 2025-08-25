local async = require('openmw.async')
local storage = require('openmw.storage')

local options_atoms = storage.playerSection('Settings/SmartInterfaceMenuOpening/KeyBindings/Atoms')
local options_switch = storage.playerSection('Settings/SmartInterfaceMenuOpening/KeyBindings/Switch')
local options_pauses = storage.playerSection('Settings/SmartInterfaceMenuOpening/PauseMenu')
local options_movements = storage.playerSection('Settings/SmartInterfaceMenuOpening/MovementsMovementsDuringMenu')

local configPlayer = {}

local function updateConfig()
	configPlayer.options_atoms = options_atoms:asTable()
	configPlayer.options_switch = options_switch:asTable()
	configPlayer.options_pauses = options_pauses:asTable()
	configPlayer.options_movements = options_movements:asTable()
end

updateConfig()
options_atoms:subscribe(async:callback(updateConfig))
options_switch:subscribe(async:callback(updateConfig))
options_pauses:subscribe(async:callback(updateConfig))
options_movements:subscribe(async:callback(updateConfig))

return configPlayer