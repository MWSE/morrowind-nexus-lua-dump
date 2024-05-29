local config = require("YourName.config")

local logger = require("logging.logger").new({
    name = "Your Name",
    logLevel = config.development.logLevel,
    logToConsole = config.development.logToConsole,
    includeTimestamp = false,
})

return logger
