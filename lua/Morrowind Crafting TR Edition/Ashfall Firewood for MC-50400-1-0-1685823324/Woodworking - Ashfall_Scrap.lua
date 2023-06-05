-- Scrapwood-conversion add-in for Morrwind Crafting 3 - Denina (scrapping version)

local makerlist = {}
makerlist = {

	{id = "mc_log_scrap",
	alias = "Convert Ashfall firewood to MC scrap log",
	ingreds = {
		{ id = "ashfall_firewood", count = 3 }
		},
	yieldCount = 1,
	difficulty = 3,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 0.1
	},
	{id = "ashfall_firewood",
	alias = "Convert a log of MC scrapwood to Ashfall firewood",
	ingreds = {
		{ id = "mc_log_scrap", count = 3 }
		},
	yieldCount = 3,
	difficulty = 4,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 0.1	
	}
}
return makerlist