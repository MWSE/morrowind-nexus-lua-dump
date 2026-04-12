local fileName = "Attack_Types_Matter"

---@class template.defaultConfig
local default = {
	logLevel 	= mwse.logLevel.info,
	enabled 	= true,
	messages 	= false,
	crosshair 	= true,
	materials	= true,
}

---@class template.config : template.defaultConfig
---@field version string A [semantic version](https://semver.org/).
---@field default template.defaultConfig Access to the default config can be useful in the MCM.
---@field fileName string

local config 	= mwse.loadConfig(fileName, default) --[[@as template.config]]
config.version 	= "1.0.0"
config.default 	= default
config.fileName = fileName

local log = mwse.Logger.new{
	modName = "Attack Types Matter",
	level 	= config.logLevel
}

return config
