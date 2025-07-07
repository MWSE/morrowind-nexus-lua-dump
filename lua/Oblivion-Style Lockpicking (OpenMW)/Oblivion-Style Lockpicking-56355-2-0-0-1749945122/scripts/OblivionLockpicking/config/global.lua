local async = require('openmw.async')
local storage = require('openmw.storage')

local options = storage.globalSection('Settings/OblivionLockpicking/3_GlobalOptions')
local tweaks = storage.globalSection('Settings/OblivionLockpicking/4_Tweaks')
local configGlobal = {}

local function updateConfig()
	configGlobal.options = options:asTable()
    configGlobal.tweaks = tweaks:asTable()
end

updateConfig()
options:subscribe(async:callback(updateConfig))
tweaks:subscribe(async:callback(updateConfig))

return configGlobal