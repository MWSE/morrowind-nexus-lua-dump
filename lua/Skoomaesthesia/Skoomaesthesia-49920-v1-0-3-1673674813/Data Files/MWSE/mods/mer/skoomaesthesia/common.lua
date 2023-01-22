local common = {}
local config = require("mer.skoomaesthesia.config")

do --Logging
    ---@type table<string, MWSELogger>
    common.loggers = {}
    local MWSELogger = require("logging.logger")
    function common.createLogger(serviceName)
        local logger = MWSELogger.new{
            name = string.format("Skoomaesthesia - %s", serviceName),
            logLevel = config.mcm.logLevel
        }
        common.loggers[serviceName] = logger
        return logger
    end
end

function common.logAssert(logger, condition, message)
    if not condition then
        logger:error(message)
        assert(condition, message)
    end
end

function common.getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/skoomaesthesia/version.txt", "r")
    if not versionFile then return end
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end


return common