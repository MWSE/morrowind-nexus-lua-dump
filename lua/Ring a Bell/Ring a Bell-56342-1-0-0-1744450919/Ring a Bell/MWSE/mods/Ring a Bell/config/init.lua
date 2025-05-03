local configFile = "Ring a Bell"

---@class RingABell.defaultConfigTable
local default = {
	---@type mwseLoggerLogLevel
	logLevel = "INFO",
	semitones = 2,
}

---@class RingABell.configTable : RingABell.defaultConfigTable
---@field version string
---@field default RingABell.defaultConfigTable

local config = mwse.loadConfig(configFile, default) --[[@as RingABell.configTable]]
config.version = "1.0.0"
config.default = default

return config
