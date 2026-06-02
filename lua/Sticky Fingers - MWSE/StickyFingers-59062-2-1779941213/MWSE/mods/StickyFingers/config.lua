local configPath = "StickyFingers"

local defaultConfig = {
	-- Main toggle.
	enabled = true,

	-- Item ownership.
	showItemOwnerName = true,
	showItemStatus = true,

	-- Container ownership.
	showContainerOwnerName = true,
	showContainerStatus = true,

	-- Bed ownership.
	showBedOwnerName = true,
	showBedStatus = true,

	-- Stolen status.
	showStolenStatus = true,
	showStolenFromName = true,

	-- Display.
	showColors = true,

	-- Debug.
	debugLog = false,
}

local config = mwse.loadConfig(configPath, defaultConfig)

-- Safety defaults, so older saved configs do not break after updates.
for key, value in pairs(defaultConfig) do
	if config[key] == nil then
		config[key] = value
	end
end

return {
	configPath = configPath,
	defaultConfig = defaultConfig,
	config = config,
}