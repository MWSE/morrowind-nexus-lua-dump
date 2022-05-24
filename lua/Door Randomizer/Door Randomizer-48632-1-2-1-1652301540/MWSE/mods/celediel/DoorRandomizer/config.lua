local common = require("celediel.DoorRandomizer.common")

local defaultConfig = {
    randomizeChance = 50,
    interiorExterior = common.cellTypes.match,
    wildernessCells = true,
    needDoor = true,
    keepRandomized = false,
    ignoreScripted = true,
    debug = false,
    ignoredCells = {},
    -- some of these aren't cell change doors but whatever
    ignoredDoors = {
        ["chargen customs door"] = true,
        ["chargendoorjournal"] = true,
        ["chargen door hall"] = true,
        ["chargen door captain"] = true,
        ["chargen door exit"] = true,
        ["chargen_ship_trapdoor"] = true,
        ["chargen_shipdoor"] = true,
        ["chargen exit door"] = true,
        ["chargen_cabindoor"] = true
    }
}

local currentConfig

local this = {}

function this.getConfig()
    currentConfig = currentConfig or mwse.loadConfig(common.configPath, defaultConfig)
    return currentConfig
end

return this
