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
			name = 'Potions-Only Limit',
			description = 'Disables attribute and skill limits; only potion limit apply.',
			default = false
		},
		{
			key = 'progressivePotions',
			renderer = 'checkbox',
			name = 'Progressive Potion Limit',
			description = 'Potion limit increases every 10 levels, from 3 to 8 by level 50.',
			default = false
		},
		{
			key = 'progressiveStats',
			renderer = 'checkbox',
			name = 'Progressive Stats Limit',
			description = 'Attributes: 100 + (level * 5), max 300.\nSkills: 100 + level, max 150.',
			default = false
		},
	},
})

local function setPotionsOnly(arg)
	if arg == true then
		world.mwscript.getGlobalVariables(player).r_potionsOnly = 1
	else
		world.mwscript.getGlobalVariables(player).r_potionsOnly = 0
	end
	print("setPotionsOnly: " .. tostring(arg))
end

local function setProgressivePotions(arg)
	if arg == true then
		world.mwscript.getGlobalVariables(player).r_progressivePotions = 1
	else
		world.mwscript.getGlobalVariables(player).r_progressivePotions = 0
	end
	print("setProgressivePotions: " .. tostring(arg))
end

local function setProgressiveStats(arg)
	if arg == true then
		world.mwscript.getGlobalVariables(player).r_progressiveStats = 1
	else
		world.mwscript.getGlobalVariables(player).r_progressiveStats = 0
	end
	print("setProgressiveStats: " .. tostring(arg))
end

local globalStorage = storage.globalSection('Main')
local potionsOnly = globalStorage:get('potionsOnly')
local progressivePotions = globalStorage:get('progressivePotions')
local progressiveStats = globalStorage:get('progressiveStats')

setPotionsOnly(potionsOnly)
setProgressivePotions(progressivePotions)
setProgressiveStats(progressiveStats)

local function updateOption(_, key)
	if key == 'potionsOnly' then
		potionsOnly = globalStorage:get('potionsOnly')
		setPotionsOnly(potionsOnly)
	end

	if key == 'progressivePotions' then
		progressivePotions = globalStorage:get('progressivePotions')
		setProgressivePotions(progressivePotions)
	end

	if key == 'progressiveStats' then
		progressiveStats = globalStorage:get('progressiveStats')
		setProgressiveStats(progressiveStats)
	end
end
globalStorage:subscribe(async:callback(updateOption))

return {
	interfaceName = 'raffll_limits',
	interface = {
		version = 2,
		setPotionsOnly = setPotionsOnly,
		setProgressivePotions = setProgressivePotions,
		setProgressiveStats = setProgressiveStats
	}
}