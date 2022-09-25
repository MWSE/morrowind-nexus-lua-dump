local regenerationType = require("Magicka Regen Suite.regenerationType")

local this = {}

local configFile = "Magicka Regen Suite"
local defaultConfig = {
	-- General Settings
	regenerationFormula = 0,
	useDecay = false,
	decayExp = 2,
	regSpeedModifier = 1,
	vampireChanges = true,
	dayPenalty = 1.25, -- TODO: set to 0.25
	nightBonus = 0.25,

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
local decimalShifts = {
	-- General Settings
	decayExp = 1,
	regSpeedModifier = 2,
	dayPenalty = 2,
	nightBonus = 2,

	-- Morrowind Regeneration
	baseMorrowind = 1,
	scaleMorrowind = 1,
	capMorrowind = 1,
	combatPenaltyMorrowind = 2,

	-- Oblivion Regeneration
	magickaReturnBaseOblivion = 2,
	magickaReturnMultOblivion = 3,

	-- Skyrim Regeneration
	magickaReturnSkyrim = 3,
	combatPenaltySkyrim = 2,

	-- Logarithimic INT
	INTBase = 1,
	INTScale = 1,
	INTCap = 1,
	INTCombatPenalty = 2,
}

local cachedConfig = mwse.loadConfig(configFile, defaultConfig)

-- Handle removed regeneration type
if cachedConfig.regenerationFormula == regenerationType.logarithmicWILL then
	cachedConfig.regenerationFormula = regenerationType.morrowind
end

this.version = "2.2.1"
this.config = setmetatable({}, {
	__index = cachedConfig,
	__tostring = function()
		local s = "{ "
		local sep1 = " = "
		local sep2 = ", "
		for key, value in pairs(cachedConfig) do
			s = s .. key .. sep1 .. value .. sep2
		end
		s = s .. " }"
		return s .. "}"
	end
})

---Returns the config table shifted so no values are decimal numbers. To be used inside MCM.
---@return table mcmConfig
this.mcmGetConfig = function()
	local mcmConfig = table.copy(cachedConfig)

	for setting, value in pairs(mcmConfig) do
		if decimalShifts[setting] then
			mcmConfig[setting] = value * 10 ^ decimalShifts[setting]
		end
	end

	return mcmConfig
end

---Shifts the config table back, and saves it by calling `mwse.saveConfig()`.
---@param mcmConfig table
this.mcmSaveConfig = function (mcmConfig)
	if mcmConfig.eventType then
		mcmConfig.eventType = nil
	end

	for setting, value in pairs(mcmConfig) do
		if decimalShifts[setting] then
			cachedConfig[setting] = value / 10 ^ decimalShifts[setting]
		else
			cachedConfig[setting] = value
		end
	end

	mwse.saveConfig(configFile, cachedConfig)
end

return this
