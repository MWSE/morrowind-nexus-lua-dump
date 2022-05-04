local defaultConfig = {
	mod = "MWSE Loading Splash Screens",
	id = "LSS",
	file = "loadingSplashScreens",
	version = 1.0,
	author = "rfuzzo",

	alpha = 50,
}

local mwseConfig = mwse.loadConfig(defaultConfig.file, defaultConfig)

return mwseConfig;
