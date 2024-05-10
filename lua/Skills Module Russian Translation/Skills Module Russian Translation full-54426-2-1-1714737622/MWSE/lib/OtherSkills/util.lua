local config = require("OtherSkills.config")

--Provides utility functions for the SkillsModule
---@class SkillsModule.Util
local util = {}

local MWSELogger = require("logging.logger")
---@type table<string, mwseLogger>
util.loggers = {}
function util.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("Skills Module - %s", serviceName),
        logLevel = config.mcm.logLevel,
        includeTimestamp = true,
    }
    util.loggers[serviceName] = logger
    return logger
end

return util