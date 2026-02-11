local Mechanics = require('scripts.Completionist.mechanics')

local quests = {

	{
		id = "PleasureIsland",
		name = "Pleasure Island",
		category = "Pleasure Island",
		subcategory = "Pleasure Island",
		text = "Someone in Llothanis has an offer..."
	},

}

Mechanics.registerQuests(quests)
return true