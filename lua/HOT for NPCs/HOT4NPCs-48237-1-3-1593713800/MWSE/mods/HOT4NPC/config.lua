local defaultConfig = {
	Version = "HOT4NPC, v1.0",
	hotNeutralRate = 1,
	hotNeutralHeal = 1,
	hotCompanionRate = 10,
	hotCompanionHeal = 1,
	hotHostileRate = 10,
	hotHostileHeal = 10,

}

local config = mwse.loadConfig ("HOT4NPC", defaultConfig)
return config