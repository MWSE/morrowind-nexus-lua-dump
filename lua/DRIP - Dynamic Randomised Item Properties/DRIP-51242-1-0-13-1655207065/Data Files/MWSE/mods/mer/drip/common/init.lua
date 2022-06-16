local Common = {}
Common.config = require("mer.drip.config")
local logger = require("logging.logger")
local logLevel = Common.config.mcm.logLevel
local loggers = {}
Common.createLogger = function(serviceName)
    local thisLogger = logger.new{
        name = string.format("%s: %s", Common.config.modName, serviceName),
        logLevel = logLevel
    }
    table.insert(loggers, thisLogger)
    return thisLogger
end
Common.updateLoggers = function(newLogLevel)
    for _, logger in ipairs(loggers) do
        logger:setLogLevel(newLogLevel)
    end
end

Common.getAllLootObjectIds = function()
    local objectIds = {}
    table.copy(Common.config.armor, objectIds)
    table.copy(Common.config.weapons, objectIds)
    table.copy(Common.config.clothing, objectIds)
    return objectIds
end

Common.canBeDripified = function(object)
    local objIds = Common.getAllLootObjectIds()
    return objIds[object.id:lower()] ~= nil
end

return Common