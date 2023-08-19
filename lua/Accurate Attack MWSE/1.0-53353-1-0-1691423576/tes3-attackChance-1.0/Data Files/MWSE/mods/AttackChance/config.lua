local defaultConfig = {
	enableMod = false,
	enableDebug = false,
	changePlayer = false,
	changeNpc = false,
	chancePlayerMin = 0,
	chancePlayerMax = 0,
	chanceNpcMin = 0,
	chanceNpcMax = 0,
}

return mwse.loadConfig("AttackChance", defaultConfig)