local config = require("OEA.OEA5 Bash.config")
local logging = require("logging.logger")

local this = {}

---@type mwseLogger[]
this.loggers = {}

function this.createLogger(serviceName)
	local logger = logging.new({ name = string.format("Lua Lockbashing - %s", serviceName), logLevel = config.logLevel })
	table.insert(this.loggers, logger)
	return logger
end

return this
