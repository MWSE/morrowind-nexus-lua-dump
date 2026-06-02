local async = require('openmw.async')
local storage = require('openmw.storage')

local gameplay = storage.globalSection('Settings/InventoryExtender/6_Gameplay')
local configGlobal = {}

local function updateConfig()
	configGlobal.gameplay = gameplay:asTable()
end

updateConfig()
gameplay:subscribe(async:callback(updateConfig))

return configGlobal