local seph = require("seph")
local npcSoulMode = require("seph.npcSoulTrapping.npcSoulMode")

local config = seph.Config()

config.autoClean = false

config.default = {
	npcExceptions = {},
	creatureExceptions = {
		["vivec_god"] = true,
		["dagoth_ur_1"] = true,
		["dagoth_ur_2"] = true,
		["almalexia"] = true,
		["almalexia_warrior"] = true
	},
	blackSoulGem = {
		required = true,
		canSoulTrapCreatures = true,
		defineAzuraAsBlackSoulGem = true,
		value = 500,
		swapChance = 20
	},
	npcSoul = {
		mode = npcSoulMode.level,
		fixedValue = 1000,
		levelMultiplier = 10,
		multiplier = 1.0
	}
}

function config:onSave()
	self:clean{"npcExceptions", "creatureExceptions"}
end

return config