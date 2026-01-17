local fileName = "Argonian Anatomy"

---@class argonianAnatomy.config
---@field version string A [semantic version](https://semver.org/).
---@field default argonianAnatomy.config Access to the default config can be useful in the MCM.
---@field fileName string
local default = {
	logLevel = mwse.logLevel.info,
	["argonian"] = true,
	["godzilla"] = true,
	["shadowscale"] = true,
}
local config = mwse.loadConfig(fileName, default)
config.version = "1.5.0"
config.default = default
config.fileName = fileName

return config
