local defaultConfig = {
	version = "Glancing Blows and Crits, V.1.2.1",
    enabled = true,
	castOnGlance = true,
	critEnabled = true,
	glanceSkill = true,
	critSkill = true,
}

--return mwse.loadConfig("GBAC", defaultConfig)
local config = mwse.loadConfig ("GBAC", defaultConfig)
return config
