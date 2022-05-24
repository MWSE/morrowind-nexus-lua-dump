local defaultConfig = {
	mod = "Immersive Bosmer Corpse Disposal",
	id = "IBD",
	file = "rf_ibd",
	version = 1.0,
	author = "rfuzzo",

	isBosmerOnly = true,
	isGreenPactOnly = false,
}

local mwseConfig = mwse.loadConfig(defaultConfig.file, defaultConfig)

return mwseConfig;
