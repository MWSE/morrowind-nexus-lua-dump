local config = require("chantox.SAD.config")
local logger = require("logging.logger")
local version = "1.1.1"
local log = logger.new{
    name = "Simple Attribute Distribution " .. version,
    logLevel = config.logLevel,
    logToConsole = true,
    includeTimestamp = true,
}

return log
