local fileName = "Hidden_Powers_Config"


local notPlayableRacesList ={
    ["argonian"]    = false,
    ["breton"]      = false,
    ["dark elf"]    = false,
    ["high elf"]    = false,
    ["imperial"]    = false,
    ["khajiit"]     = false,
    ["nord"]        = false,
    ["orc"]         = false,
    ["redguard"]    = false,
    ["wood elf"]    = false,
	["t_cyr_ayleid"]		= true,
    ["t_els_cathay"]		= true,
    ["t_els_cathay-raht"]	= true,
	["t_els_dagi-raht"]		= true,
	["t_els_ohmes"]			= true,
	["t_els_ohmes-raht"]	= true,
	["t_els_suthay"]		= true,
    ["t_cnq_chimeriquey"]	= true,
    ["t_yok_duadri"]		= true,
    ["t_val_imga"]			= true,
    ["t_cnq_keptu"]			= true,
    ["t_sky_reachman"]		= true,
    ["t_hr_riverfolk"]		= true,
    ["t_pya_seaelf"]		= true,
    ["t_aka_tsaesci"]		= true,
    ["t_yne_ynesai"]		= true
}

---@class template.defaultConfig
local default = {
logLevel                = mwse.logLevel.error,
NPC_powerDistribution   = true,
NPC_unlockPowerLevel    = 15,
Guard_powerDistribution = true,
Guard_unlockPowerLevel  = 25,
playableRaceFiltering   = true,
notPlayableRaces        = notPlayableRacesList,
unlockOnTopic           = true,
unlockOnMeetingNewRace  = true,
unlockOnActivatingCorpse = false
}

---@class template.config : template.defaultConfig
---@field version string A [semantic version](https://semver.org/).
---@field default template.defaultConfig Access to the default config can be useful in the MCM.
---@field fileName string

local config = mwse.loadConfig(fileName, default) --[[@as template.config]]
config.version = "1.0.0"
config.default = default
config.fileName = fileName

-- Setting up the logger
local log = mwse.Logger.new({
    name = "Hidden Powers",
    level = config.logLevel,
})


return config
