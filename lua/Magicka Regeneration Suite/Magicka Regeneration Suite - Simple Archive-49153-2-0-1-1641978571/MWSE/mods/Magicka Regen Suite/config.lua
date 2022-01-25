local this = {}

local configFile = "Magicka Regen Suite"
local defaultConfig = {
	-- General Settings
	regenerationFormula = 0,
	useDecay = false,
	decayExp = 2,
	regSpeedModifier = 1,
	vampireChanges = true,
	dayPenalty = 1.25,
	nightBonus = 0.25,

	-- Morrowind Regeneration
	magickaReturnBaseMorrowind = 0.25,
	magickaReturnMultMorrowind = 0.01,
	combatPenaltyMorrowind = 0.33,

	-- Oblivion Regeneration
	magickaReturnBaseOblivion = 0.75,
	magickaReturnMultOblivion = 0.02,

	-- Skyrim Regeneration
	magickaReturnSkyrim = 0.03,
	combatPenaltySkyrim = 0.33,

	-- Logarithimic WILL
	WILLBase = 1.5,
	WILLa = 0.2,
	WILLApplyCombatPenalty = true,
	WILLCombatPenalty = 0.33,
	WILLUseFatigueTerm = true,

	-- Logarithimic INT
	INTBase = 1.05,
	INTa = 0.07,
	INTb = 4,
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
	magickaReturnBaseMorrowind = 2,
	magickaReturnMultMorrowind = 3,
	combatPenaltyMorrowind = 2,

	-- Oblivion Regeneration
	magickaReturnBaseOblivion = 2,
	magickaReturnMultOblivion = 3,

	-- Skyrim Regeneration
	magickaReturnSkyrim = 3,
	combatPenaltySkyrim = 2,

	-- Logarithimic WILL
	WILLBase = 1,
	WILLa = 1,
	WILLCombatPenalty = 2,

	-- Logarithimic INT
	INTBase = 2,
	INTa = 2,
	INTb = 1,
	INTCombatPenalty = 2,
}

-- TODO: remove on next update
local function loadConfig()
	local maybe = json.loadfile("config\\" .. configFile)
	local result = {}
	local hasOldConfig = false

	if maybe then
		if table.size(maybe) == 11 then
			hasOldConfig = true
		end
	end

	if hasOldConfig then
		for setting, value in pairs(maybe) do
			if decimalShifts[setting] then
				result[setting] = value / 10 ^ decimalShifts[setting]
			else
				result[setting] = value
			end
		end
	else
		result = maybe
	end

	table.copymissing(result, defaultConfig)
	-- Overwrite the config file immediately with new settings in new formatting style
	mwse.saveConfig(configFile, result)
	return result
end
local cachedConfig = loadConfig()
--local cachedConfig = mwse.loadConfig(configFile, defaultConfig)


this.version = 2.0
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

this.mcmGetConfig = function()
	local mcmConfig = table.copy(cachedConfig)

	for setting, value in pairs(mcmConfig) do
		if decimalShifts[setting] then
			mcmConfig[setting] = value * 10 ^ decimalShifts[setting]
		end
	end

	return mcmConfig
end

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
