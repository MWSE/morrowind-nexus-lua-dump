local defaultConfig = {
    version = "0.9.6",
	
	modEnabled = true,
    debugEnabled = false,
	enchantEffect = false,

    forgetDuration = 5 * 60,
	
    trapDifficulty = {
		maxLockLevel = 100,
        steepness = 0.05,
        midpoint = 70
    },
    
}

local mwseConfig = mwse.loadConfig("detectTrap", defaultConfig)

return mwseConfig;
