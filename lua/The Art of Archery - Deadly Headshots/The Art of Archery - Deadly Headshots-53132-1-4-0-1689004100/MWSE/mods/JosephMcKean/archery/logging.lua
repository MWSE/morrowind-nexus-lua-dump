local config = require("JosephMcKean.archery.config")
local logging = require("logging.logger")

local this = {}

---@type mwseLogger[]
this.loggers = {}

function this.createLogger(serviceName)
	local logger = logging.new({ name = string.format("The Art of Archery - %s", serviceName), logLevel = config.logLevel })
	table.insert(this.loggers, logger)
	return logger
end

return this
