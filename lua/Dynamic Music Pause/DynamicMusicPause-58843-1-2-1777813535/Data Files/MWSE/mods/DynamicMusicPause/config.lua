local defaultConfig = {
    minPause = 30,
    maxPause = 120,
    pauseChance = 100
}

local config = mwse.loadConfig("DynamicMusicPauseConfig", defaultConfig)
return config