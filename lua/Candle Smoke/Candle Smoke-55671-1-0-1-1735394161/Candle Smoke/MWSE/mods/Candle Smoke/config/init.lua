local configFile = "Candle Smoke"

---@class CandleSmoke.configTable
local default = {
	---@type mwseLoggerLogLevel
	logLevel = "INFO",
	smokeIntensity = 60,
	disableCarriable = false,
}

local cachedConfig = mwse.loadConfig(configFile, default)
local this = {
	version = "1.0.1",
	---@type CandleSmoke.configTable
	config = {}, --- @diagnostic disable-line: missing-fields
	default = default,
}

-- We use a trick of empty "config" table with a __index in its metatable. This way we make sure
-- that all the other files that read from "config" table read our up-to-date cachedConfig.
-- This approach was pioneered by Merlord.
setmetatable(this.config, { __index = cachedConfig })

--- Returns a copy of the current config table.
--- Usually used in mcm\init.lua
---@return CandleSmoke.configTable
this.getConfig = function()
	return table.copy(cachedConfig)
end

--- Saves the config table to mod's config file.
--- Usually used in mcm\init.lua
--- @param mcmConfig CandleSmoke.configTable
this.saveConfig = function(mcmConfig)
	table.copy(mcmConfig, cachedConfig)
	event.trigger("Candle Smoke: update effects")
	mwse.saveConfig(configFile, cachedConfig)
end

return this
