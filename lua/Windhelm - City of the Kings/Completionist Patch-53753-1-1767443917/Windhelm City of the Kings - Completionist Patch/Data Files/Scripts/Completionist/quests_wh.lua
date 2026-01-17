local Mechanics = require('scripts.Completionist.mechanics')

local quests = {

	{
		id = "wh_blackrats",
		name = "Rats on Warehouse",
		category = "Windhelm | Miscellaneous",
		subcategory = "Windhelm",
		text = "Asgald has a problem with rats."
	},
	{
		id = "wh_guardkilled",
		name = "The Missing Guard",
		category = "Windhelm | Miscellaneous",
		subcategory = "Windhelm",
		text = "The guard did not show up for duty."
	},
	{
		id = "wh_investigateruins",
		name = "Investigate the Ancient Ruins",
		category = "Windhelm | Mages Guild",
		subcategory = "Skyrim",
		text = "What secrets lie hidden in the ancient ruins?",
	},
	{
		id = "wh_kjaldiron",
		name = "Recover Iron for Kjald",
		category = "Windhelm | Miscellaneous",
		subcategory = "Windhelm",
		text = "Kjald needs his special iron.",
	},
	{
		id = "wh_ollurhook",
		name = "Legendary Hook Hand of Ollur the Maulhand",
		category = "Windhelm | Miscellaneous",
		subcategory = "Windhelm",
		text = "What is true about the legend?",
	},
	{
		id = "wh_recoverhammer",
		name = "Recover Hammer from Bandits",
		category = "Windhelm | Fighters Guild",
		subcategory = "Windhelm",
		text = "The stolen artefact must be recovered.",
	},
	{
		id = "wh_huntmoon",
		name = "The Hunter and the Moon",
		category = "Windhelm | Miscellaneous",
		subcategory = "Skyrim",
		text = "What injured the hunter?",
	},

}

Mechanics.registerQuests(quests)
return true