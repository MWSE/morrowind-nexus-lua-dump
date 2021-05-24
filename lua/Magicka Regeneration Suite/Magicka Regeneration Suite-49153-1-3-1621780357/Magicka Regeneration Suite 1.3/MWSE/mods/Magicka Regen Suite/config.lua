local configFile = "Magicka Regen Suite"
local this = {}
local inMemoryConfig

this.defaultConfig = {
    version = "Magicka Regen Suite 1.3",
	useDecay = false,
	regenerationType = 0,
    magickaReturnBaseMorrowind = 25,
	magickaReturnMultMorrowind = 10,
	combatPenaltyMorrowind = 33,
	magickaReturnBaseOblivion = 75,
	magickaReturnMultOblivion = 20,
	combatPenaltySkyrim = 33,
	magickaReturnSkyrim = 30,
	regSpeedModifier = 100,
	decayExp = 20,
}

inMemoryConfig = mwse.loadConfig(configFile, this.defaultConfig)

function this.getConfig()
	inMemoryConfig = inMemoryConfig or mwse.loadConfig(configFile, this.defaultConfig)
	return inMemoryConfig
end
function this.saveConfig(newConfig)
	inMemoryConfig = newConfig
	mwse.saveConfig(configFile, newConfig)
end

return this
