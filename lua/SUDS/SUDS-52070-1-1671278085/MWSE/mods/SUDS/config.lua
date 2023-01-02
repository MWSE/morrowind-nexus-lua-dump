local defaultConfig = {
    hpCap = 500,
    hpMultiplier = 0.01,
    logToggle = false,
    blackList = {
        "player",
	"Gaenor_b",
        "Calvus Horatius",
        "Rat_pack_rerlas"
}}
local config = mwse.loadConfig ("SUDS", defaultConfig)
return config