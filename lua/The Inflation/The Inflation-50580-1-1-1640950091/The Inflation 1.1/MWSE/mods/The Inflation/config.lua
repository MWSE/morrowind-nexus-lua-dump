local this = {}

this.netWorth = {
	goldOnly = 0,
	equippedItems = 1,
	wholeInventory = 2,
}
local configFile = "The Inflation"
local defaultConfig = {
	enableBarter = true,
	enableGeneric = true,
	enableSpells = true,
	enableTraining = true,
	netWorthCaluclation = this.netWorth.wholeInventory,
	spellsAffectNetWorth = true,
	base = 10,
	genericExp = 2,
	trainingExp = 5,
	barterExp = 2,
	spellExp = 2.5,
}
local decimalShifts = {
	genericExp = 2,
	trainingExp = 2,
	barterExp = 2,
	spellExp = 2,
}
local cachedConfig = mwse.loadConfig(configFile, defaultConfig)


this.version = 1.1
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
	event.trigger("The Inflation:Config Changed")
end

return this
