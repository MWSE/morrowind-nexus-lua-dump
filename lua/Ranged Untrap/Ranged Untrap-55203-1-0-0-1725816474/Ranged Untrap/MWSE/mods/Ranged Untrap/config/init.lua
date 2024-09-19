local configFile = "Ranged Untrap"

--- @class RangedUntrap.modConfigTable
local defaultConfig = {
	--- @mwseLoggerLogLevel
	logLevel = "TRACE",
	castTrapOnFail = false,
	castTrapOnCriticalFail = true,
	soundOnFail = true,
	fTrapCostMult = 1.0,
	fSecurityMult = 0.7,
	fMarksmanMult = 0.3,
}

local cachedConfig = mwse.loadConfig(configFile, defaultConfig)
local this = {
	version = "1.0.0",
	--- @type RangedUntrap.modConfigTable
	config = {},
	default = defaultConfig,
}

setmetatable(this.config, { __index = cachedConfig })

--- Returns a copy of the current config table.
--- This function should only be used in mcm\init.lua
---@return RangedUntrap.modConfigTable
this.getConfig = function()
	return table.copy(cachedConfig)
end

--- Saves the config table to mod's config file.
--- This function should only be used in mcm\init.lua
--- @param mcmConfig RangedUntrap.modConfigTable
this.saveConfig = function(mcmConfig)
	table.copy(mcmConfig, cachedConfig)
	mwse.saveConfig(configFile, cachedConfig)
end

return this
