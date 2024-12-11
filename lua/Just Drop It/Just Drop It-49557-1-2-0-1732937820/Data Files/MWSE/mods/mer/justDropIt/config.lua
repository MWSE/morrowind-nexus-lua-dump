local mcmDefaultValues = {
    enabled = true,
    logLevel = "INFO",
    noOrientNonStatic = false,
    orientOnDeath = true,
    maxSteepnessFlat = 50,
    maxSteepnessTall = 5,
    debug = false,
    blacklist = {},
}
local config = {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Just Drop It",
    --Description for the MCM sidebar
    modDescription =
[[
When you drop an item, it will actually touch the ground! It also orients the item so it sits correctly on the ground.
]],
}
config.mcmConfig = mwse.loadConfig(config.modName, mcmDefaultValues)

config.registeredItems = {}

return config