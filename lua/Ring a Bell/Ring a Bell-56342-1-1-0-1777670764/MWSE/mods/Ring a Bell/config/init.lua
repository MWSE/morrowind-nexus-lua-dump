local configFile = "Ring a Bell"

---@class RingABell.defaultConfigTable
local default = {
	logLevel = mwse.logLevel.info,
	semitones = 2,
}

---@class RingABell.configTable : RingABell.defaultConfigTable
---@field version string
---@field default RingABell.defaultConfigTable

local config = mwse.loadConfig(configFile, default) --[[@as RingABell.configTable]]
config.version = "1.1.0"
config.default = default

return config
