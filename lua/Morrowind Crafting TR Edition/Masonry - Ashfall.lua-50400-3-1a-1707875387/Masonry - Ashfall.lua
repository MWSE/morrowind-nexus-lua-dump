-- Allows making wooden platforms/beams - separated 'loft' items ---
local makerlist = {}
makerlist = {

	{id = "mc_brick02",
	ingreds = {
		{ id = "ashfall_stone", count = 25 },
		{ id = "Magicka", count = 20}
		},
	yieldCount = 1,
	difficulty = 30,
	group = "Miscellaneous",
	taskTime = 0.5
	},

	{id = "mc_block00",
	ingreds = {
		{ id = "ashfall_stone", count = 55 },
		{ id = "Magicka", count = 30}
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Miscellaneous",
	taskTime = 1
	},

	{id = "mc_block10",
	ingreds = {
		{ id = "ashfall_stone", count = 140 },
		{ id = "Magicka", count = 40}
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Miscellaneous",
	taskTime = 1.25
	},

	{id = "mc_block20",
	ingreds = {
		{ id = "ashfall_stone", count = 160 },
		{ id = "Magicka", count = 50}
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Miscellaneous",
	taskTime = 1.5
	},

	{id = "mc_block30",
	ingreds = {
		{ id = "ashfall_stone", count = 210 },
		{ id = "Magicka", count = 60}
		},
	yieldCount = 1,
	difficulty = 65,
	group = "Miscellaneous",
	taskTime = 1.5
	},
}
return makerlist