local logger = require("logging.logger")

local log = logger.new({
    name = "Leeches",
    logLevel = "INFO",
    logToConsole = false,
    includeTimestamp = false,
})

return log
