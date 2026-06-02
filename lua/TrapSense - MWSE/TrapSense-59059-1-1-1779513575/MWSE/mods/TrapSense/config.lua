local configPath = "TrapSense"

local defaultConfig = {
	enabled = true,
	maxDetectChance = 95,

	showMessages = true,
	debugLog = false,

	showVFX = true,

	playDiscoverySound = true,
	discoverySound = "mysticism hit",
	discoverySoundVolume = 0.8,

	useDetectEnchantmentBonus = true,
	detectEnchantmentBonus = 25,
}

local config = mwse.loadConfig(configPath, defaultConfig)

-- Safety defaults for older saved configs.
for key, value in pairs(defaultConfig) do
	if config[key] == nil then
		config[key] = value
	end
end

return {
	config = config,
	configPath = configPath,
}