local this = {}
local config = require("JosephMcKean.restockFilledSoulGems.config")
local logger = require("logging.logger")
---@type mwseLogger
this.log = logger.new {
    name = "Restock Filled Soul Gems",
    logLevel = config.logLevel
}
this.loggers = {this.log}
-- create loggers for services of this mod 
this.createLogger = function(serviceName)
    local logger = logger.new {
        name = string.format("Restock Filled Soul Gems %s", serviceName),
        logLevel = config.logLevel
    }
    table.insert(this.loggers, logger)
    return logger -- return a table of logger
end
return this
