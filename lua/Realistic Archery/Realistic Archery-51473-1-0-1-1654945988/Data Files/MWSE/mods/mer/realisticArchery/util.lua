local Util = {}

Util.config = require("mer.realisticArchery.config")
Util.loggers = {}
do --logger
    local logLevel = Util.config.mcm.logLevel
    local logger = require("logging.logger")
    Util.log = logger.new{
        name = Util.config.static.modName,
        logLevel = logLevel
    }
    Util.createLogger = function(serviceName)
        local logger = logger.new{
            name = string.format("%s: %s", Util.config.static.modName, serviceName),
            logLevel = logLevel
        }
        Util.loggers[serviceName] = logger
        return logger
    end
end
local logger = Util.createLogger("Util")

function Util.getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/realisticArchery/version.txt", "r")
    if not versionFile then return end
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end

--Get the marksman skill for NPCs, or fake the marksman skill of creatures based on their level.
---@param mobile tes3mobileCreature|tes3mobileNPC
---@return number marksmanSkill The fake marksman skill calculated for the given creature mobile
function Util.getNPCOrCreatureMarksmanSkill(mobile)
    if mobile.marksman then
        return mobile.marksman.current
    else
        local lvl = mobile.object.level
        local marksmanSkill = math.remap(lvl, 1, 50, 20, 100)
        marksmanSkill = math.clamp(marksmanSkill, 20, 100)
        return marksmanSkill
    end
end

function Util.getNormalDistributionRandom(range)
    logger:debug("getNormalDistributionRandom")
    logger:debug("Range: %s", range)
    local normalDistribution = math.sqrt(-2 * math.log(math.random())) * math.cos(2 * math.pi * math.random())
    logger:debug("getNormalDistributionRandom: %s", normalDistribution)
    normalDistribution = normalDistribution * range / 2
    logger:debug("getNormalDistributionRandom*range: %s", normalDistribution)
    return normalDistribution
end




return Util