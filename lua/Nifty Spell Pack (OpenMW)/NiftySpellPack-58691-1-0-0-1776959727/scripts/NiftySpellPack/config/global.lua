local async = require('openmw.async')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')

local options = storage.globalSection('Settings/NiftySpellPack/1_GlobalOptions')
local configGlobal = {}

local effectConfigs = {}
for path in vfs.pathsWithPrefix('scripts/niftyspellpack/effects/') do
	if path:match('config%.lua$') then
		local effectId = path:match('scripts/niftyspellpack/effects/(.-)/config%.lua$')
		if effectId then
			effectConfigs[effectId] = storage.globalSection('Settings/NiftySpellPack/Effect_' .. effectId)
		end
	end
end

local function updateConfig()
	configGlobal.options = options:asTable()
	for effectId, effectConfig in pairs(effectConfigs) do
		configGlobal[effectId] = effectConfig:asTable()
	end
end

updateConfig()
options:subscribe(async:callback(updateConfig))
for _, effectConfig in pairs(effectConfigs) do
	effectConfig:subscribe(async:callback(updateConfig))
end

return configGlobal