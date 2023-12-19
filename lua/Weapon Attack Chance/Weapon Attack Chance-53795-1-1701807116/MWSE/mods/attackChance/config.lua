local defaultConfig = {
	modEnabled = true,
	affectEnemiesToo = false,
	axeTwoHand = -30,
	axeOneHand = -20,
	bluntTwoClose = -15,
	bluntTwoWide = -10,
	bluntOneHand = -5,
	spearTwoWide = 10,
	longBladeTwoClose = 0,
	longBladeOneHand = 10,
	shortBladeOneHand = 30,
	marksmanThrown = 30,
	marksmanBow = 15,
	marksmanCrossbow = 20,
}

local mwseConfig = mwse.loadConfig("attackChance", defaultConfig)

return mwseConfig;
