local defaults = { logLevel = "INFO" }
---@class BoundAmmo.config
---@field logLevel mwseLoggerLogLevel
local config = mwse.loadConfig("Bound Ammo", defaults)
return config
