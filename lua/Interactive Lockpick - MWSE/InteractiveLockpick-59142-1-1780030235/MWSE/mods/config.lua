local config = {
	enabled = true,

	debugLog = false,
	debugMessages = false,

	-- Lockpick menu balance/settings.
	maximumSliders = 8,

	-- true  = use the real vanilla lockpick-use event
	-- false = use the old interact/activate hook
	lockpickOpenMode = "lockpickUse",
}

return mwse.loadConfig("InteractiveLockpick", config)