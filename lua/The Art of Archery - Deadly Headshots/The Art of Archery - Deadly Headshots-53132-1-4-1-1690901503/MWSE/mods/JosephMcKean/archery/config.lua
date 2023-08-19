local defaults = {
	enableLocationalDamage = true,
	noPlayerHeadshot = false,
	enableDamageReduction = true,
	enableArrowCounter = true,
	logLevel = "INFO",
	showMessages = true,
	headshotMessage = "GOTTEM!",
	onlyHeadshotMessage = false,
}
---@class archery.config
---@field enableLocationalDamage boolean
---@field noPlayerHeadshot boolean
---@field enableDamageReduction boolean
---@field enableArrowCounter boolean
---@field logLevel mwseLoggerLogLevel
---@field showMessages boolean
---@field headshotMessage string
---@field onlyHeadshotMessage boolean
local config = mwse.loadConfig("The Art of Archery", defaults)
return config
