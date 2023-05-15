local defaultConfig = {

	waterBreathing = true,
	restUnderwater = true,
	swiftSwim = true,
	swimValue = 25,
	npcBenefits = true,
	onlyArgonians = true,
	affectVampires = true,
	logLevel = "INFO"

}

local mwseConfig = mwse.loadConfig("Aquatic Ascendancy", defaultConfig)

return mwseConfig;