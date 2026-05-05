local defaultConfig = {
    enableDebug = false,
    maxPenalty = 15,
    raceScale = 1.0,
    speechcraftScale = 1.0,
    personalityScale = 1.0,
    factionScale = 0.5,
    fameScale = 0.5
}

local config = mwse.loadConfig("DynamicDispositionConfig", defaultConfig)
if not config then
    config = table.copy(defaultConfig)
end

return config
