local config = require("InspectIt.config")

local logger = require("logging.logger").new({
    name = "Inspect It!",
    logLevel = config.development.logLevel,
    logToConsole = config.development.logToConsole,
    includeTimestamp = false,
})

return logger
