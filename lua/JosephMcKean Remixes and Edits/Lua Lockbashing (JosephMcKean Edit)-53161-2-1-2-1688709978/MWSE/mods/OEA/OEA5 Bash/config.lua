local defaultConfig = { OldMult = "1", Hand = true }
---@class OEA5Bash.config
---@field Hand boolean
---@field OldMult number
---@field logLevel mwseLoggerLogLevel
local config = mwse.loadConfig("Lua_Lockbashing", defaultConfig)
return config
