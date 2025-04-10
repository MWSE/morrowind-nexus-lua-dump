local async = require('openmw.async')
local storage = require('openmw.storage')

local options = storage.globalSection('Settings/Keytar/Options')
local technical = storage.globalSection('Settings/Keytar/Technical')
local configGlobal = {}

local function updateConfig()
	configGlobal.options = options:asTable()
	configGlobal.technical = technical:asTable()
end

updateConfig()
options:subscribe(async:callback(updateConfig))
technical:subscribe(async:callback(updateConfig))

return configGlobal