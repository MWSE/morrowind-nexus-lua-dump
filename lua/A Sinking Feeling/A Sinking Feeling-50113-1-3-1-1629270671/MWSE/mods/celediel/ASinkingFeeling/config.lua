local common = require("celediel.ASinkingFeeling.common")

local currentConfig

local this = {}

this.defaultConfig = {
	enabled = true,
	debug = false,
	playerOnly = false,
	multipliers = {
		equippedArmour = 100,
		allEquipment = 100,
		encumbrancePercentage = 100
	},
	mode = common.modes[1].mode,
	caseScenarioNecroMode = true
}

this.getConfig = function()
	currentConfig = currentConfig or mwse.loadConfig(common.configString, this.defaultConfig)
	return currentConfig
end

return this
