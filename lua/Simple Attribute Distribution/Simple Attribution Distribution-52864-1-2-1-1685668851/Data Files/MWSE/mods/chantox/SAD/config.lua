local configPath = "Simple Attribute Distribution"
local defaultConfig = {
    attributeLvlCap = 100,
    pointsPerLevel = 10,
    maxPointsPerAttribute = 0,
    altLevelMsgs = true,
    alpha = 1.78,
    beta = 0.83,
    minHealth = 1,
    logLevel = "INFO"
}

return mwse.loadConfig(configPath, defaultConfig)
