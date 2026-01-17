local defaultConfig = {
    aiUpdateTime = 1
}

local configPath = "updateAIFaster"

local mwseConfig = {
    loaded = mwse.loadConfig(configPath, defaultConfig),
    default = defaultConfig
}

return mwseConfig