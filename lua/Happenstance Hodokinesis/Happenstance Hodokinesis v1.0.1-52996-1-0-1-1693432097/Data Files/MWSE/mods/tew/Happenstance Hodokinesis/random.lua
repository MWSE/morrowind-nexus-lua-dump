local random = {}

local actions = require("tew.Happenstance Hodokinesis.actions")

random.actions = {
	[true] = {
		actions.teleportRandom,
		actions.luckyContainer,
		actions.summonScrib,
	},
	[false] = {
		actions.preventEquip,
		actions.flies,
		actions.flunge,
		actions.teleportRandom,
		actions.summonScribHostile,
	}
}

return random

