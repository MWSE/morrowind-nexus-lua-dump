local config = require("Hanafuda.config")

local logger = require("logging.logger").new({
    name = "Hanafuda",
    logLevel = config.development.logLevel,
    logToConsole = config.development.logToConsole,
    includeTimestamp = false,
})

return logger
