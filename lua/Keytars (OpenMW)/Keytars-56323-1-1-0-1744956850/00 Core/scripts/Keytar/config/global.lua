local async = require('openmw.async')
local storage = require('openmw.storage')

local options = storage.globalSection('Settings/Keytar/3_Options')
local technical = storage.globalSection('Settings/Keytar/4_Technical')
local customMusic = storage.globalSection('Settings/Keytar/2_CustomMusic')
local configGlobal = {}

local function updateConfig()
	configGlobal.options = options:asTable()
	configGlobal.technical = technical:asTable()
	configGlobal.customMusic = customMusic:asTable()
end

updateConfig()
options:subscribe(async:callback(updateConfig))
technical:subscribe(async:callback(updateConfig))
customMusic:subscribe(async:callback(updateConfig))

return configGlobal