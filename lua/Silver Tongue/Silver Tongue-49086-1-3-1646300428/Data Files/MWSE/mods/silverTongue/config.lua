local defaultConfig = {
	
	modEnabled = true,
	pauperBonus = 40,
    guardPenalty = 20,
	showDisposition = 25,
    showFight = 50,
	showAlarm = 75,
	allowAdmire = 25,
	allowIntimidate = 50,
	allowTaunt = 50,
	bribeDecreasesAlarm = 75,
	combatTalk = 100,
}

local mwseConfig = mwse.loadConfig("Silver Tongue", defaultConfig)

return mwseConfig