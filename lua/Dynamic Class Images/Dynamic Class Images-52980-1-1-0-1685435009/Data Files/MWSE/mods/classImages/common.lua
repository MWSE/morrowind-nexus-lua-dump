local config = require("classImages.config")
local common = {}
common.loggers = {}
local MWSELogger = require("logging.logger")
function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("%s - %s",
            config.modName, serviceName),
        logLevel = config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
return common