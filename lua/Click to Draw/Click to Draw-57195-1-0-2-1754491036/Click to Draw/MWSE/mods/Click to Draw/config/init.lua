local fileName = "Click to Draw"

---@class clickToDraw.config
---@field version string A [semantic version](https://semver.org/).
---@field default clickToDraw.config Access to the default config can be useful in the MCM.
---@field fileName string
local default = {
	logLevel = mwse.logLevel.info,
	draw = {
		mouseButton = 0,
	},
	sheath = {
		mouseButton = 2,
	},
	raiseHands = {
		mouseButton = 2,
	}
}

local config = mwse.loadConfig(fileName, default)
config.version = "1.0.2"
config.default = default
config.fileName = fileName

return config
