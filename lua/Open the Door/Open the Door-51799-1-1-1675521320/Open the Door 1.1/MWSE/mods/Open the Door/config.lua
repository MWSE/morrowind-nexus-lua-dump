local configFile = "Open the Door"
local defaultConfig = {
	minDistance = 225,	--tes3.getPlayerActivationDistance(), Default: iMaxActivateDist = 192
	delay = 0,
	loadDoors = true,
	interiorDoors = true,
	barDoors = true,
	skipLocked = true,
	skipTrapped = true,
	showMessages = true,
	useCooldowns = true,
	clearOnCellChange = false,
	cooldown = 5,
}
local cachedConfig = mwse.loadConfig(configFile, defaultConfig)

local this = {}
this.version = 1.0
this.config = {}
setmetatable(this.config, { __index = cachedConfig })

this.getConfig = function()
	return table.copy(cachedConfig)
end

this.saveConfig = function (mcmConfig)
	table.copy(mcmConfig, cachedConfig)
	mwse.saveConfig(configFile, cachedConfig)
end

return this
