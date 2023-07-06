local config = require("JosephMcKean.furnitureCatalogue.config")
local logging = require("logging.logger")

local this = {}

---@type mwseLogger[]
this.loggers = {}

function this.createLogger(serviceName)
	local logger = logging.new { name = string.format("Furniture Catalogue - %s", serviceName), logLevel = config.debugMode and "DEBUG" or "INFO" }
	table.insert(this.loggers, logger)
	return logger
end

return this
