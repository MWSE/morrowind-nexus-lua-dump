local configPath = "SellThis"

local defaultConfig = {
	enabled = true,
	debugLog = false,
	showMessages = true,
	
	-- Default key: F4.
	markKeyCombo = {
		keyCode = tes3.scanCode.F4,
	},
}

local config = mwse.loadConfig(configPath, defaultConfig)

-- Safety defaults, so older saved configs do not break after updates.
for key, value in pairs(defaultConfig) do
	if config[key] == nil then
		config[key] = value
	end
end

-- Safety repair for old/broken configs.
if type(config.markKeyCombo) ~= "table" then
	config.markKeyCombo = {
		keyCode = tes3.scanCode.F4,
	}
end

if config.markKeyCombo.keyCode == nil then
	config.markKeyCombo.keyCode = tes3.scanCode.F4
end

return {
	configPath = configPath,
	defaultConfig = defaultConfig,
	config = config,
}