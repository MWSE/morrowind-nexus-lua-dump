local logging = require("logging.logger")

local config = require("JosephMcKean.ashfallSurvivalStart.config")

local common = {}
---@type mwseLogger
common.log = logging.new({ name = "common", logLevel = config.debugMode and "DEBUG" or "INFO" })
common.loggers = { common.log }
-- create loggers for services of this mod 
common.createLogger = function(serviceName)
	local logger = logging.new { name = string.format("Ashfall Survival Start - %s", serviceName), logLevel = config.debugMode and "DEBUG" or "INFO" }
	table.insert(common.loggers, logger)
	return logger -- return a table of logger
end

return common
