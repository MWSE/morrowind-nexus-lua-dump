local config = require("SSQN.config")
local common = {}
--Hardly even know why I'm including a logger. To be cool I guess
common.log = require("logging.logger").new {
    name = "SSQN",
    logLevel = "TRACE",
    logToConsole = false,
    includeTimestamp = true,
}

common.log:setLogLevel(config.loglevel)

return common