local configPath = "Always Goodbye"

local defaultConfig = {
    enabled = true,
}

local config = mwse.loadConfig(configPath, defaultConfig)

if config.enabled == nil then
    config.enabled = defaultConfig.enabled
end

return {
    path = configPath,
    default = defaultConfig,
    current = config,
}