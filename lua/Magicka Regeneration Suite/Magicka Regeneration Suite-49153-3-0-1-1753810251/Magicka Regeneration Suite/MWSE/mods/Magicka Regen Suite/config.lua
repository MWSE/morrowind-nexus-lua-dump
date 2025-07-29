local regenerationType = require("Magicka Regen Suite.regenerationType")

local fileName = "Magicka Regen Suite"

---@class MagickaRegenSuite.config
---@field version string A [semantic version](https://semver.org/).
---@field default MagickaRegenSuite.config Access to the default config can be useful in the MCM.
---@field fileName string
local default = {
	-- General Settings
	regenerationFormula = regenerationType.morrowind --[[@as MagickaRegenSuite.regenerationType]],
	useDecay = false,
	decayExp = 2,
	regSpeedModifier = 1,
	vampireChanges = true,
	dayPenalty = 1.25, -- TODO: consider setting to 0.25
	nightBonus = 0.25,
	logLevel = mwse.logLevel.info --[[@as mwseLogger.logLevel]],

	-- Morrowind Regeneration
	baseMorrowind = 5,
	scaleMorrowind = 1.4,
	capMorrowind = 3,
	combatPenaltyMorrowind = 0.33,

	-- Oblivion Regeneration
	magickaReturnBaseOblivion = 0.75,
	magickaReturnMultOblivion = 0.02,

	-- Skyrim Regeneration
	magickaReturnSkyrim = 0.03,
	combatPenaltySkyrim = 0.33,

	-- Logarithimic INT
	INTBase = 2.5,
	INTScale = 1.1,
	INTCap = 3.5,
	INTApplyCombatPenalty = true,
	INTCombatPenalty = 0.33,
	INTUseFatigueTerm = true,
}

local config = mwse.loadConfig(fileName, default)
config.version = "3.0.1"
config.default = default
config.fileName = fileName

-- TODO: remove
-- Handle removed regeneration type
if config.regenerationFormula == regenerationType.logarithmicWILL then
	config.regenerationFormula = regenerationType.morrowind
end

return config
