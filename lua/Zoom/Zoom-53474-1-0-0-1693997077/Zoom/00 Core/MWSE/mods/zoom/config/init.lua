local configFile = "zoom"

---@class zoomModConfigTable
local defaultConfig = {
	---@type mwseLoggerLogLevel
	logLevel = "INFO",
	---@type zoommodType
	zoomType = "press",
	maxZoom = 2.0,
	zoomStrength = 0.06,
	zoomKey = {
		keyCode = tes3.scanCode.i,
		isAltDown = false,
		isShiftDown = false,
		isControlDown = false,
	},
	faderOn = false,
}

local cachedConfig = mwse.loadConfig(configFile, defaultConfig)
local this = {
	version = "1.0.0",
	---@type zoomModConfigTable
	config = {},
	default = defaultConfig,
}

setmetatable(this.config, { __index = cachedConfig })

--- Returns a copy of the current config table.
--- This function should only be used in mcm\init.lua
---@return zoomModConfigTable
this.getConfig = function()
	local ret = table.copy(cachedConfig) --[[@as zoomModConfigTable]]
	return ret
end

--- Saves the config table to mod's config file.
--- This function should only be used in mcm\init.lua
---@param mcmConfig zoomModConfigTable
this.saveConfig = function(mcmConfig)
	table.copy(mcmConfig, cachedConfig)
	mwse.saveConfig(configFile, cachedConfig)
end

return this
