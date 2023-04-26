local defaultConfig = { logLevel = "INFO", defaultLuaConsole = false, leftRightArrowSwitch = false, marks = {} }
local configPath = "More Console Commands"
return mwse.loadConfig(configPath, defaultConfig)
