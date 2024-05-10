local mcmDefaultValues = {
    enabled = true,
    logLevel = "INFO",
    noOrientNonStatic = false,
    orientOnDeath = true,
    maxSteepnessFlat = 50,
    maxSteepnessTall = 5,
    debug = false,
    blacklist = {
        ['ashfall.esp'] = true
    },
}
local config = {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Просто брось это!",
	modConfigPath = "Just Drop It!",
    --Description for the MCM sidebar
    modDescription =
[[
Теперь, когда вы бросаете предмет, он действительно касается земли! Мод также позволяет правильно расположить предмет относительно поверхности.
]],
}
config.mcmConfig = mwse.loadConfig(config.modConfigPath, mcmDefaultValues)

config.registeredItems = {}

return config