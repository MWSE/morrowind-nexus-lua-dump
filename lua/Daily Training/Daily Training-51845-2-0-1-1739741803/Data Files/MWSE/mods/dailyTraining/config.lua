local defaultConfig = {
	townTrain = false,
	townSkills = true,
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
	expMod = 6,
	skillLimit = true,
	skillMax = 75,
	trainCost = true,
	costMultH = 2,
	costMultM = 3,
	costMultF = 5,
	attModifier = true,
	weakSkill = 15,
	weakMod = 50,
	specSkills = true,
	raceBonus = true,
	miscPenalty = true,
	skillBurn = true,
	noColor = false,
	playSound = true,
	logLevel = "NONE"
}

local mwseConfig = mwse.loadConfig("Daily Training", defaultConfig)

return mwseConfig;
