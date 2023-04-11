local defaultConfig = {

	modEnabled = true,
	major = 100,
	minor = 70,
	misc = 40,
	specialisationCoef = 1,
	raceCoef = 1,
	limitTraining = true,
}

local mwseConfig = mwse.loadConfig("classSkillLimit", defaultConfig)

return mwseConfig
