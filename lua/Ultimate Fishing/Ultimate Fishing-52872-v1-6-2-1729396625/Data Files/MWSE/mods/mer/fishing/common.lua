
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

---Picks up any item reference, bypassing activate events
---@param reference tes3reference #The reference to pick up
---@param playSound boolean Default: false
function common.pickUp(reference, playSound)
    tes3.addItem{
        reference = tes3.player,
        item = reference.object,
        itemData = reference.itemData,
        count = reference.stackSize,
        playSound = playSound,
    }
    common.safeDelete(reference)
end

function common.safeDelete(reference)
    reference.itemData = nil
    reference:disable()
    reference:delete()
end

return common