local configFile = "The Inflation"

local this = {
	version = "1.2.0",
	--- @class TheInflation.ConfigTable
	config = {},
}
this.netWorth = {
	goldOnly = 0,
	equippedItems = 1,
	wholeInventory = 2,
}
--- @class TheInflation.ConfigTable
local defaultConfig = {
	enableBarter = true,
	enableGeneric = true,
	enableSpells = true,
	enableTraining = true,
	netWorthCaluclation = this.netWorth.wholeInventory,
	spellsAffectNetWorth = true,
	base = 10,
	genericExp = 2,
	trainingExp = 5,
	barterExp = 2,
	spellExp = 2.5,
}
this.default = defaultConfig

local cachedConfig = mwse.loadConfig(configFile, defaultConfig)
setmetatable(this.config, { __index = cachedConfig })


--- Returns a copy of the current config table.
--- This function should only be used in mcm\init.lua
--- @return TheInflation.ConfigTable
function this.getConfig()
	return table.copy(cachedConfig)
end

--- Saves the config table to mod's config file.
--- This function should only be used in mcm\init.lua
--- @param mcmConfig TheInflation.ConfigTable
this.saveConfig = function(mcmConfig)
	table.copy(mcmConfig, cachedConfig)
	mwse.saveConfig(configFile, cachedConfig)
	event.trigger("The Inflation:Config Changed")
end

return this
