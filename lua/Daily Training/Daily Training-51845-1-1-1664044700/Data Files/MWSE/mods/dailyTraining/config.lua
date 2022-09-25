local defaultConfig = {
	townTrain = false,
	trainCD = true,
	ambush = true,
	ambushChance = 7,
	cdMessages = true,
	trainCDtime = 24,
	streakBonus = true,
	gracePeriod = 48,
	sessionLimit = true,
	wilMod = 5,
	endMod = 5,
	expMod = 5,
	skillLimit = true,
	skillMax = 75,
	trainCost = true,
	costMultH = 2,
	costMultM = 3,
	costMultF = 5,
	noColor = false,
	logLevel = "NONE"
}

local mwseConfig = mwse.loadConfig("Daily Training", defaultConfig)

return mwseConfig;
