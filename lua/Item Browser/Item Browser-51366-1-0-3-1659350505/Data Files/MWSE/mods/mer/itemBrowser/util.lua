local Util = {}

local config = require("mer.itemBrowser.config")
Util.loggers = {}
do --logger
    local logLevel = config.mcm.logLevel
    local logger = require("logging.logger")
    Util.log = logger.new{
        name = config.static.modName,
        logLevel = logLevel
    }
    Util.createLogger = function(serviceName)
        local logger = logger.new{
            name = string.format("%s: %s", config.static.modName, serviceName),
            logLevel = logLevel
        }
        Util.loggers[serviceName] = logger
        return logger
    end
end

---@param pressed keyDownEventData
---@param expected keyDownEventData
function Util.isKeyPressed(pressed, expected)
    return (
        pressed.keyCode == expected.keyCode
         and not not pressed.isShiftDown == not not expected.isShiftDown
         and not not pressed.isControlDown == not not expected.isControlDown
         and not not pressed.isAltDown == not not expected.isAltDown
         and not not pressed.isSuperDown == not not expected.isSuperDown
    )
end

function Util.getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/itemBrowser/version.txt", "r")
    if not versionFile then return end
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end



return Util