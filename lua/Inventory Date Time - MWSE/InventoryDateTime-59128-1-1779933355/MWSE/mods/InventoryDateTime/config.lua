local configPath = "InventoryDateTime"

local defaultConfig = {
	enableInventory = true,
	enableRestWaitMessage = true,
	dateTimeFormat = "%W, %D %M %T (Day %N)", --description = "Custom format. Tokens: %W = weekday, %M = month, %D = day, %Y = year, %T = time, %N = day number.",
}

local config = mwse.loadConfig(configPath, defaultConfig)

return {
	configPath = configPath,
	defaultConfig = defaultConfig,
	config = config,
}