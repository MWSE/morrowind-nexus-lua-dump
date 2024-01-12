local inMemConfig

local Config = {}

--Interops
Config.skooma = {}
Config.moonSugar = {}
Config.pipes = {}

--Static Config (stored right here)
Config.static = {
    modName = "Skoomaesthesia",
    --Description for the MCM sidebar
    modDescription =
[[
Overhauls Skooma mechanics. Incudes hallucinations, functional skooma pipes and skooma addiction.

- Scripting by Merlord
- Shader by XeroFoxx and Vtastek
- Animations by Greatness7
]],
    --Shader Configs
    shaderName = "skoomaesthesia",
    musicPath = "skoomaesthesia/trip.mp3",
    silencePath = "skoomaesthesia/silence.mp3",
    timeShift = 1,
    onSetTime = 6,
    onsetIterations = 200,
    maxIntensity = 0.3,
    maxBlur = 1.0,
    --Skooma Pipe Configs
    skoomaIds = {
        potion_skooma_01 = true
    },
    pipeIds = {
        apparatus_a_spipe_01 = true,
        apparatus_a_spipe_tsiya = true,
        t_com_skoomapipe_01 = true,
        llcs_apparatus_a_spipe_01 = true,
    },
    moonSugarIds = {
        ingred_moon_sugar_01 = true
    },

    --Addiction Configs
    baseAddictionChance = 1,
    maxAddictionMulti = 5.0,--0 will
    minAddictionMulti = 0.0,--100 will
    hoursToWithdrawal = 2 * 24,
    hoursToRecovery = 5 * 24,
}

--MCM Config (stored as JSON)
Config.configPath = "skoomaesthesia"
Config.mcmDefault = {
    enableHallucinations = true,
    enableSkoomaPipe = true,
    enableAddiction = true,
    logLevel = "INFO",
    maxColor = 70,
    maxBlur = 100,
}
Config.save = function(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(Config.configPath, inMemConfig)
end

Config.mcm = setmetatable({}, {
    __index = function(_, key)
        inMemConfig = inMemConfig or mwse.loadConfig(Config.configPath, Config.mcmDefault)
        return inMemConfig and inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig = inMemConfig or mwse.loadConfig(Config.configPath, Config.mcmDefault)
        inMemConfig[key] = value
        mwse.saveConfig(Config.configPath, inMemConfig)
    end
})

--Persistent (Stored on player)
local persistentDefault = {
    isAddicted = nil,
    tripState = nil,
    lastSmoked = nil,
    previousMusicVolume = nil,
}

Config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[Config.configPath] = tes3.player.data[Config.configPath] or persistentDefault
        return tes3.player.data[Config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[Config.configPath] = tes3.player.data[Config.configPath] or persistentDefault
        tes3.player.data.skoomaesthesia[key] = value
    end
})

return Config