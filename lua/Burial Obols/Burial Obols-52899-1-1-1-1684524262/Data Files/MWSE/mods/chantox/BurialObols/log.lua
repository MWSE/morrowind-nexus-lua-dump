local config = require("chantox.BurialObols.config")
local logger = require("logging.logger")
local version = "1.1.1"
local log = logger.new{
    name = "Burial Obols " .. version,
    logLevel = config.logLevel,
    logToConsole = true,
    includeTimestamp = true,
}

return log
