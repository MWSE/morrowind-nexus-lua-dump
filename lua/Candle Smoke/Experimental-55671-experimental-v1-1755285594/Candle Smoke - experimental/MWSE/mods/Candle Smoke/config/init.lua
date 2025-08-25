local fileName = "Candle Smoke"

---@class candleSmoke.config
---@field version string A [semantic version](https://semver.org/).
---@field default candleSmoke.config Access to the default config can be useful in the MCM.
---@field fileName string
local default = {
	logLevel = mwse.logLevel.info,
	intensity = 0.6,
	disableCarriable = false,
}

local config = mwse.loadConfig(fileName, default)
config.version = "2.0.0"
config.default = default
config.fileName = fileName

return config
