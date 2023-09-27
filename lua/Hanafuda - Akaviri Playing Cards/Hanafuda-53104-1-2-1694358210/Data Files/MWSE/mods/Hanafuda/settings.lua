
---@class Settings
local this = {}

local hr = require("Hanafuda.KoiKoi.houseRule")

---@enum CardLanguage
this.cardLanguage = {
    japanese = 1,
    tamrielic = 2,
}

---@class Config
local defaultConfig = {
    enable = true,
    cardStyle = "worn",
    cardBackStyle = "worn",
    cardLanguage = this.cardLanguage.tamrielic,
    tooltipImage = false,
    cardAnimation = true,
    -- game speed x1.0 for wait time
    ---@class Config.KoiKoi
    koikoi = {
        help = true, -- more help
        round = 3, -- 3, 6, 12, 1 (debug)
        ---@class Config.KoiKoi.HouseRule
        houseRule = {
            multiplier = hr.multiplier.doublePointsOver7,
            flowerViewingSake = true,
            moonViewingSake = true,
            luckyHands = true,
            -- nov cards rain off, dec cards fog
            -- wild card
        },
    },
    audio = {
        --volume = 100,
        playerVoice = true,
        npcVoice = true,
    },
    development = {
        logLevel = "INFO",
        logToConsole = false,
        debug = false,
        unittest = false,
    }
}

this.configPath = "Hanafuda"
this.metadata = toml.loadFile("Data Files\\Hanafuda-metadata.toml") ---@type MWSE.Metadata?
this.modName = this.metadata.package.name
this.version = this.metadata.package.version
local config = nil ---@type Config

---@return Config
function this.Load()
    config = config or mwse.loadConfig(this.configPath, defaultConfig)
    return config
end

---@return Config
function this.Default()
    return table.deepcopy(defaultConfig)
end

return this
