local defaultConfig = {
	ScrollMenu = false,
	BlockVanillaProgress = true,
	QuestXP = true,
	QuestRate = 10,
	QuestMsg = true,
	KillXP = true,
	KillRate = 1000,
	KillMsg = true,
	key = {keyCode = tes3.scanCode['.']},
}

local config = mwse.loadConfig('MXPS', defaultConfig)
return config