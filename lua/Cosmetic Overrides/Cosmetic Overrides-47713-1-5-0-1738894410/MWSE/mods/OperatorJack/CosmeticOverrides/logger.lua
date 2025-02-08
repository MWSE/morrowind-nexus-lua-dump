local config = require("OperatorJack.CosmeticOverrides.config")
local name = config.name

local logger = require("logging.logger")
local log = logger.getLogger(name) or logger.new({ name = name, logLevel = config.logLevel })

log:info("Initialized logger with log level %s", config.logLevel)

return log;
