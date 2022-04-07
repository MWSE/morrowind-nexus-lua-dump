local defaultConfig = {
	Version = "Magicka Regen, v1.0",
	pcRegen = true,
	npcRegen = true,
	vanillaRate = false,
	magickaDecay = false,
	pcRate = 100,
	npcRate = 100,
}

local config = mwse.loadConfig ("Magicka Regen", defaultConfig)
return config