-- logger.lua
local logger = require("logging.logger")
local log = logger.new{
    name = "SetBonus",
    logLevel = "ERROR",
    logToConsole = true,
    includeTimestamp = true,
}

return log