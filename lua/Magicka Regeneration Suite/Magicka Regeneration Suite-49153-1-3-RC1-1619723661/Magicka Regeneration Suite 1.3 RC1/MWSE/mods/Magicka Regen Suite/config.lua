local configPath = "Magicka Regen Suite"
local this = {}
local inMemoryConfig

this.defaultConfig = {
	Version = "Magicka Regen Suite 1.3",
	bDecay = false,
	regenerationType = 0,
	fMagickaReturnBaseOblivion = 0.75,
	fMagickaReturnMultOblivion = 0.02,
	fMagickaReturnBaseMorrowind = 0.25,
	fMagickaReturnMultMorrowind = 0.01,
	fCombatPenaltyMorrowind = 0.33,
	fCombatPenaltySkyrim = 0.33,
	fMagickaReturnSkyrim = 0.03,
	regenerationSpeedModifier = 1,
	fDecayExp = 2,
}
function this.getConfig()
	inMemoryConfig = inMemoryConfig or mwse.loadConfig(configPath, this.defaultConfig)
	return inMemoryConfig
end
function this.saveConfig(newConfig)
	inMemoryConfig = newConfig
	mwse.saveConfig(configPath, newConfig)
end

return this