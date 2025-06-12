local config = require("SedrynTyros.ORLL.config")
local logger = require("logging.logger")
local version = "2.01"
local log = logger.new{
    name = "Oblivion Remastered Like Leveling " .. version,
    logLevel = config.logLevel,
    logToConsole = true,
    includeTimestamp = true,
}

return log
