local configFile = "livebookediting"

---@class livebookeditingModConfigTable
local defaultConfig = {
	---@type mwseLoggerLogLevel
	logLevel = "NONE",
	addBook = false,
	addScroll = false,
	bookKey = {
		keyCode = tes3.scanCode.o,
		isShiftDown = false,
		isAltDown = true,
		isControlDown = false,
	},
	scrollKey = {
		keyCode = tes3.scanCode.p,
		isShiftDown = false,
		isAltDown = true,
		isControlDown = false,
	},
}

local cachedConfig = mwse.loadConfig(configFile, defaultConfig)
local this = {
	version = "1.0.0",
	---@type livebookeditingModConfigTable
	config = {},
	default = defaultConfig,
}

setmetatable(this.config, { __index = cachedConfig })

--- Returns a copy of the current config table.
--- This function should only be used in mcm\init.lua
---@return livebookeditingModConfigTable
this.getConfig = function()
	return table.copy(cachedConfig)
end

--- Saves the config table to mod's config file.
--- This function should only be used in mcm\init.lua
this.saveConfig = function(mcmConfig)
	table.copy(mcmConfig, cachedConfig)
	mwse.saveConfig(configFile, cachedConfig)
end

return this
