local fileName = "StormAtronach.SO"

---@class template.defaultConfig
local default = {
	modEnabled 					= true,
	logLevel 					= mwse.logLevel.error,
	detectionAngle 				= 80, -- degrees
	detectionCooldown 			= 5, -- seconds, cooldown for stolen ITEMs check
	dispositionDropOnDiscovery 	= 20,
	wanderRangeInterior 		= 500,
	wanderRangeExterior 		= 2000,
	bountyThreshold 			= 10,
	guardCooldownTime 			= 5,
	ownerCooldownTime 			= 5,
	guardMaxDistance 			= 4, -- roughly 100 feet / 30 meters
	-- Sneak skill multipliers
	sneakSkillMult 				= 100,
	bootMultiplier 				= 10,
	sneakDistanceBase 			= 80,
	sneakDistanceMultiplier 	= 300,
	invisibilityBonus 			= 30,
	npcSneakBonus 				= 20,
	viewMultiplier 				= 3,
	hearingMultiplier 			= 1,
	sneakDifficulty 			= 20,
	minTravelTime 				= 1, -- seconds, minimum time that the NPC will travel to the destination while investigating
	maxTravelTime				= 15, -- seconds, maximum time that the NPC will travel to the destination

}

---@class template.config : template.defaultConfig
---@field version string A [semantic version](https://semver.org/).
---@field default template.defaultConfig Access to the default config can be useful in the MCM.
---@field fileName string

local config = mwse.loadConfig(fileName, default) --[[@as template.config]]
config.version = "0.2.0"
config.default = default
config.fileName = fileName

local log = mwse.Logger.new({
	name = "Stealth Overhaul",
	level = config.logLevel,
})

return config
