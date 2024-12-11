---@class CharacterBackgrounds.common
local common = {}
common.config = require("mer.characterBackgrounds.config")

local logger = require("logging.logger")
---@type mwseLogger
common.log = logger.new{
    name = "Character Backgrounds",
    includeTimestamp = true,
    logLevel = common.config.mcm.logLevel,
}
common.loggers = {common.log}
common.createLogger = function(serviceName)
    local logger = logger.new{
        name = string.format("Character Backgrounds - %s", serviceName),
        logLevel = common.config.mcm.logLevel,
        includeTimestamp = true,
    }
    table.insert(common.loggers, logger)
    return logger
end

function common.modReady()
    return common.config.mcm.enableBackgrounds
        and tes3.player ~= nil
end

function common.isBackgroundActive(backgroundId)
    return common.config.persistent.currentBackground == backgroundId
end


return common