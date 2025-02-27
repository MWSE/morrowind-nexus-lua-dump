local configFile = "Nocturnal Moths"

---@class NocturnalMoths.defaultConfigTable
local default = {
	---@type mwseLoggerLogLevel
	logLevel = "INFO",
	enableSound = true,
	soundVolume = 1.0,
	---@type { [string]: boolean }
	whitelist = {}
}

---@class NocturnalMoths.configTable : NocturnalMoths.defaultConfigTable
---@field version string
---@field default NocturnalMoths.defaultConfigTable

local config = mwse.loadConfig(configFile, default) --[[@as NocturnalMoths.configTable]]
config.version = "2.0.0"
config.default = default

return config
