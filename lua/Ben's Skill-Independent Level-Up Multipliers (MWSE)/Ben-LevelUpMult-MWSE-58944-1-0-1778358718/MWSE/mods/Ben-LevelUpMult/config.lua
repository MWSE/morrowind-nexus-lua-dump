local util = require("Ben-LevelUpMult.util")

this = {}

local defaultMcmConfig = {
    version = 1.0,
    attributeMults = {
        [tes3.attribute.strength] = 3,
        [tes3.attribute.intelligence] = 3,
        [tes3.attribute.willpower] = 3,
        [tes3.attribute.agility] = 3,
        [tes3.attribute.speed] = 3,
        [tes3.attribute.endurance] = 3,
        [tes3.attribute.personality] = 3,
        [tes3.attribute.luck] = 1,
    },
}

local staticConfig = {
    loggingEnabled = false,
    gameSettings = {
        [tes3.gmst.iLevelUp01Mult] = 1,
        [tes3.gmst.iLevelUp02Mult] = 2,
        [tes3.gmst.iLevelUp03Mult] = 3,
        [tes3.gmst.iLevelUp04Mult] = 4,
        [tes3.gmst.iLevelUp05Mult] = 5,
        [tes3.gmst.iLevelUp06Mult] = 6,
        [tes3.gmst.iLevelUp07Mult] = 7,
        [tes3.gmst.iLevelUp08Mult] = 8,
        [tes3.gmst.iLevelUp09Mult] = 9,
        [tes3.gmst.iLevelUp10Mult] = 10,
    },
}

local gameConfig = {} -- all of the above configs merged into one table

local configName = "Ben-LevelUpMult"

local function updateGameConfig(mcmConfig)
    
    util.deepMerge(gameConfig, mcmConfig)
    
end

this.saveMcmConfig = function(newConfig)
    
    mwse.saveConfig(configName, newConfig)
    updateGameConfig(newConfig)
    
end

local function upgradeConfig(mcmConfig, version)
    
    mcmConfig.version = defaultMcmConfig.version
    
end

local function getVersion(mcmConfig)
    
    -- if fresh config, return latest version
    if util.count(mcmConfig) == 0 then return defaultMcmConfig.version end
    
    -- if version is invalid, assume 1.0 config
    return util.getNumber(mcmConfig.version, 1.0)
    
end

this.loadMcmConfig = function()
    
    local mcmConfig = mwse.loadConfig(configName, {})
    local version = getVersion(mcmConfig)
    
    util.fixNumberKeys(mcmConfig)
    util.deepRemoveMissingKeys(mcmConfig, defaultMcmConfig)
    util.deepMergeWhenNil(mcmConfig, defaultMcmConfig)
    
    upgradeConfig(mcmConfig, version)
    
    return mcmConfig
    
end

this.getDefaultMcmConfig = function ()
    return defaultMcmConfig
end

this.getGameConfig = function()
    return gameConfig
end

this.getModName = function()
    return "Level-Up Multipliers"
end

this.getVersion = function()
    return defaultMcmConfig.version
end

this.getLoggingEnabled = function()
    return gameConfig.loggingEnabled
end

util.deepMerge(gameConfig, staticConfig)
updateGameConfig(this.loadMcmConfig())

return this
