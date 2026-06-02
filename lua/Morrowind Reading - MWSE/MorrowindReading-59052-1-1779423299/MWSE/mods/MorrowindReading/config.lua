local configPath = "Morrowind Reading"

local defaultConfig = {
    enabled = true,
    showTooltipStatus = true,
    allowReadingFromList = true,

    addScrollsToReadingList = false,
    showTranslatedScrollText = false,
}

local config = mwse.loadConfig(configPath, defaultConfig)

if config.addScrollsToReadingList == nil then
    config.addScrollsToReadingList = defaultConfig.addScrollsToReadingList
end

if config.showTranslatedScrollText == nil then
    config.showTranslatedScrollText = defaultConfig.showTranslatedScrollText
end

if config.allowReadingFromList == nil then
    config.allowReadingFromList = defaultConfig.allowReadingFromList
end

if config.enabled == nil then
    config.enabled = defaultConfig.enabled
end

if config.showTooltipStatus == nil then
    config.showTooltipStatus = defaultConfig.showTooltipStatus
end

return {
    path = configPath,
    default = defaultConfig,
    current = config,
}