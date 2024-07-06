
---@class Fishing.common
local common = {}

local config = require("mer.fishing.config")
local MWSELogger = require("logging.logger")

---@type table<string, mwseLogger>
common.loggers = {}
function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("%s - %s",
            config.metadata.package.name, serviceName),
        logLevel = config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

function common.getVersion()
    return config.metadata.package.version
end

function common.disablePlayerControls()
    logger:debug("Disabling player controls")
    tes3.setPlayerControlState{enabled = false }
end

function common.enablePlayerControls()
    logger:debug("Enabling player controls")
    tes3.setPlayerControlState{ enabled = true}
end

function common.addAOrAnPrefix(name)
    local vowels = {"a", "e", "i", "o", "u"}
    local firstLetter = string.sub(name, 1, 1):lower()
    for _, vowel in ipairs(vowels) do
        if firstLetter == vowel then
            return "an " .. name
        end
    end
    return "a " .. name
end

return common