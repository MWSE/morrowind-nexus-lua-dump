local logger = require("logging.logger")

local log = logger.new({
    name = "Colossus",
    logLevel = "DEBUG",
    logToConsole = false,
    includeTimestamp = false,
})

return log
