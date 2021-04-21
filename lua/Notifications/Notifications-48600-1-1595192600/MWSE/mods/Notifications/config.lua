local defaultConfig = {
	Version = "Notifications, v1.0",
	deathnote = true,
	crimenote = true,
	fightnote = true,
	cellnote = true,

}

local config = mwse.loadConfig ("Notifications", defaultConfig)
return config