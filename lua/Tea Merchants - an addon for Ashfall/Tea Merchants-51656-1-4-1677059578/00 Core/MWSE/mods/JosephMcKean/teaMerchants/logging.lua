local this = {}
local config = require("JosephMcKean.teaMerchants.config")
local logging = require("logging.logger")
---@type mwseLogger
this.log = logging.new { name = "Tea Merchants", logLevel = config.logLevel }
this.loggers = { this.log }
-- create loggers for services of this mod 
this.createLogger = function(serviceName)
	local logger = logging.new { name = string.format("Tea Merchants - %s", serviceName), logLevel = config.logLevel }
	table.insert(this.loggers, logger)
	return logger -- return a table of logger
end
return this
