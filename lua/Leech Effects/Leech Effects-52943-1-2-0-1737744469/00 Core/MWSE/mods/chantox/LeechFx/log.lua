local logger = require("logging.logger")
local version = "1.1.0"
local log = logger.new{
    name = "Leech Effects " .. version,
    logLevel = "TRACE",
    logToConsole = true,
    includeTimestamp = true,
}

return log
