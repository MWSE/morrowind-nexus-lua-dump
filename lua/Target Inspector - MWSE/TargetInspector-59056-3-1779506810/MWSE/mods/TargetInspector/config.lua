local configPath = "Target Inspector"

local defaultConfig = {
    enabled = true,

    inspectKey = {
        keyCode = tes3.scanCode.i,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },

    showAttributes = true,
    showSkills = true,
    showVitals = true,
}

local config = mwse.loadConfig(configPath, defaultConfig)

if config.inspectKey == nil then
    config.inspectKey = defaultConfig.inspectKey
end

if config.enabled == nil then
    config.enabled = defaultConfig.enabled
end

if config.showAttributes == nil then
    config.showAttributes = defaultConfig.showAttributes
end

if config.showSkills == nil then
    config.showSkills = defaultConfig.showSkills
end

if config.showVitals == nil then
    config.showVitals = defaultConfig.showVitals
end

return {
    path = configPath,
    default = defaultConfig,
    current = config,
}