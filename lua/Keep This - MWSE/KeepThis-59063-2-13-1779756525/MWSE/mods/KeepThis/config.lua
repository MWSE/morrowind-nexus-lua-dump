local configPath = "KeepThis"

local defaultConfig = {
	enabled = true,
	preventDropping = true,
	preventSelling = true,
	showMessages = true,
	debugLog = false,

	-- Default key: F3.
	markKeyCombo = {
		keyCode = tes3.scanCode.F3,
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
		keyCode = tes3.scanCode.F3,
	}
end

if config.markKeyCombo.keyCode == nil then
	config.markKeyCombo.keyCode = tes3.scanCode.F3
end

return {
	configPath = configPath,
	defaultConfig = defaultConfig,
	config = config,
}