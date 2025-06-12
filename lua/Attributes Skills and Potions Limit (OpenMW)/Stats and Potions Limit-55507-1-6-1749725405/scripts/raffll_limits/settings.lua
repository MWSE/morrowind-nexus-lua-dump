local async = require("openmw.async")
local interfaces = require('openmw.interfaces')
local storage = require("openmw.storage")
local world = require('openmw.world')

local l10nKey = 'raffll_limits'
local settingsPageKey = 'SPL'

interfaces.Settings.registerGroup({
    key = 'Main',
    page = settingsPageKey,
    l10n = l10nKey,
    name = 'Main',
    permanentStorage = true,
    settings = {
        {
            key = 'potionsOnly',
            renderer = 'checkbox',
            name = 'Potions Limit Only',
            description = 'Disables attribute and skill limits.',
            default = false
        }
    },
})

local globalStorage = storage.globalSection('Main')
local potionsOnly = globalStorage:get('potionsOnly')
if potionsOnly == true then
	world.mwscript.getGlobalVariables(player).r_onlyPotions = 1
else
	world.mwscript.getGlobalVariables(player).r_onlyPotions = 0
end

local function updateOption(_, key)
    if key == 'potionsOnly' then
		potionsOnly = globalStorage:get('potionsOnly')
		if potionsOnly == true then
			world.mwscript.getGlobalVariables(player).r_onlyPotions = 1
		else
			world.mwscript.getGlobalVariables(player).r_onlyPotions = 0
		end
    end
end
globalStorage:subscribe(async:callback(updateOption))