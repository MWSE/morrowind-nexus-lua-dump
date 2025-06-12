local async = require('openmw.async')
local storage = require('openmw.storage')

local options = storage.globalSection('Settings/Bardcraft/3_GlobalOptions')
local configGlobal = {}

local function updateConfig()
	configGlobal.options = options:asTable()
end

updateConfig()
options:subscribe(async:callback(updateConfig))

return configGlobal