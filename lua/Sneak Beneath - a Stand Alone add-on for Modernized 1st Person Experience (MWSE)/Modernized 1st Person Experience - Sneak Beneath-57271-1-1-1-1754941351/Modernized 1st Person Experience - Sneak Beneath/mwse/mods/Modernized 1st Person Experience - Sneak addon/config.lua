--[[
	Mod: Modernized 1st Person Experience - Sneak addon
	Author: rhjelte
	Version: 1.0
]]--

local defaultConfig = {
    modEnabled = true,
    verticalPadding = 15,
    horizontalPadding = 0,
    messageCooldown = 0.5,
    firstPersonMessages = true
}

local configPath = "Modernized 1st Person Experience - Sneak addon"

local mwseConfig = {
    loaded = mwse.loadConfig(configPath, defaultConfig),
    default = defaultConfig
}

return mwseConfig