local configPath = "SpellEffectDescription"

local defaultConfig = {
	enabled = true,
	holdToActivate = false,

	-- MCM keybinds need a key-combo table, not just a number.
	holdKey = {
		keyCode = tes3.scanCode.i,
		isShiftDown = false,
		isAltDown = false,
		isControlDown = false,
	},

	debug = false,

	showSchool = true,
	showEffectSummary = false,
	showDescriptions = true,
}

local config = mwse.loadConfig(configPath, defaultConfig)

-- Safety defaults for old saved configs.
for key, value in pairs(defaultConfig) do
	if config[key] == nil then
		config[key] = value
	end
end

-- Safety conversion for old configs where holdKey was saved as a number.
if type(config.holdKey) == "number" then
	config.holdKey = {
		keyCode = config.holdKey,
		isShiftDown = false,
		isAltDown = false,
		isControlDown = false,
	}
end

-- Safety fallback.
if type(config.holdKey) ~= "table" or not config.holdKey.keyCode then
	config.holdKey = {
		keyCode = tes3.scanCode.i,
		isShiftDown = false,
		isAltDown = false,
		isControlDown = false,
	}
end

return {
	configPath = configPath,
	defaultConfig = defaultConfig,
	current = config,
}