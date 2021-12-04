--[[ Crafting-materials listing -- Crafting bag
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]

local makerlist = {}
makerlist = {

	{id = "mc_brick01",
	ingreds = {
		{ id = "mc_clay", count = 3 },
		{ id = "mc_straw", count = 1 }
		},
	yieldCount = 2,
	difficulty = 6,
	group = "Miscellaneous",
	taskTime = 0.25
	},

	{id = "mc_brick02",
	ingreds = {
		{ id = "mc_block00", count = 1 }
		},
	alias = "Make brick-sized stone blocks from cubes",
	yieldCount = 2,
	difficulty = 5,
	group = "Miscellaneous",
	taskTime = 0.25
	},

	{id = "mc_block00",
	ingreds = {
		{ id = "mc_block10", count = 1 }
		},
	alias = "Make stone cubes from a rectangular block",
	yieldCount = 2,
	difficulty = 5,
	group = "Miscellaneous",
	taskTime = 0.5
	},

	{id = "mc_block00",
	ingreds = {
		{ id = "mc_block20", count = 1 }
		},
	alias = "Make stone cubes from a larger rectangular block",
	yieldCount = 3,
	difficulty = 8,
	group = "Miscellaneous",
	taskTime = 0.5
	},

	{id = "mc_block_00",
	ingreds = {
		{ id = "mc_block30", count = 1 }
		},
	alias = "Make stone cubes from the largest stone block",
	yieldCount = 4,
	difficulty = 10,
	group = "Miscellaneous",
	taskTime = 0.5
	},

	{id = "mc_block10",
	ingreds = {
		{ id = "mc_block30", count = 1 }
		},
	alias = "Make one large stone block into two rectangles",
	yieldCount = 2,
	difficulty = 10,
	group = "Miscellaneous",
	taskTime = 0.5
	},

	{id = "mc_brick02",
	ingreds = {
		{ id = "mc_block00", count = 1 }
		},
	alias = "Make stone 'bricks' from stone blocks",
	yieldCount = 2,
	difficulty = 5,
	group = "Miscellaneous",
	taskTime = 0.5
	},

	{id = "mc_brazier01",
	ingreds = {
		{ id = "mc_block10", count = 2 }
		},
	yieldCount = 1,
	difficulty = 25,
	group = "Brazier",
	taskTime = 2
	},

	{id = "mc_brazier02",
	ingreds = {
		{ id = "mc_brick01", count = 10 },
		{ id = "mc_clay", count = 40 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Brazier",
	taskTime = 3
	},	
	
	{id = "mc_firepit02",
	ingreds = {
		{ id = "mc_brick02", count = 20 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Forge/Hearth",
	taskTime = 6
	},

	{id = "mc_firepit01",
	ingreds = {
		{ id = "mc_brick02", count = 40 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Forge/Hearth",
	taskTime = 7
	},

	{id = "mc_fireplace01",
	ingreds = {
		{ id = "mc_block00", count = 140 },
		{ id = "mc_log_ash", count = 6 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Forge/Hearth",
	taskTime = 24
	},

	{id = "mc_fireplace02",
	ingreds = {
		{ id = "mc_block00", count = 75 },
		{ id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Forge/Hearth",
	taskTime = 16
	},

	{id = "mc_fireplace03",
	ingreds = {
		{ id = "mc_block00", count = 65 },
		{ id = "mc_clay", count = 20}
		},
	yieldCount = 1,
	difficulty = 70,
	group = "Forge/Hearth",
	taskTime = 16
	},

	{id = "mc_forge01",
	ingreds = {
		{ id = "mc_brick01", count = 60 },
		{ id = "mc_clay", count = 100 }
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Forge/Hearth",
	taskTime = 16
	},

	{id = "mc_forge02",
	ingreds = {
		{ id = "mc_block20", count = 5 },
		{ id = "mc_clay", count = 5 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Forge/hearth",
	taskTime = 16
	},

	{id = "mc_pedestal01",
	ingreds = {
		{ id = "mc_block10", count = 10 },
		{ id = "mc_prepared_cloth", count = 12 }
		},
	yieldCount = 1,
	difficulty = 65,
	group = "Furnishings",
	taskTime = 3
	},

	{id = "mc_pedestal02",
	ingreds = {
		{ id = "mc_block10", count = 2 },
		{ id = "mc_prepared_cloth", count = 4 }
		},
	yieldCount = 1,
	difficulty = 55,
	group = "Furnishings",
	taskTime = 6
	},

	{id = "mc_pedestal03",
	ingreds = {
		{ id = "mc_block10", count = 2 }
		},
	yieldCount = 1,
	difficulty = 25,
	group = "Furnishings",
	taskTime = 2
	},

	{id = "mc_platform01",
	ingreds = {
		{ id = "mc_brick01", count = 100 },
		{ id = "mc_clay", count = 150 }
		},
	yieldCount = 1,
	difficulty = 55,
	group = "Foundations",
	taskTime = 12
	},

	{id = "mc_platform02",
	ingreds = {
		{ id = "mc_brick01", count = 60 },
		{ id = "mc_clay", count = 75 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Foundations",
	taskTime = 12
	},

	{id = "mc_platform03",
	ingreds = {
		{ id = "mc_brick01", count = 300 },
		{ id = "mc_clay", count = 300 },
		{ id = "ingred_bonemeal_01", count = 100 }
		},
	yieldCount = 1,
	difficulty = 100,
	group = "Foundations",
	taskTime = 24
	},

	{id = "mc_urn10",
	ingreds = {
		{ id = "mc_block10", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	group = "Furnishings",
	taskTime = 4
	},

	{id = "mc_urn11",
	ingreds = {
		{ id = "mc_block10", count = 2 }
		},
	yieldCount = 1,
	difficulty = 90,
	group = "Furnishings",
	taskTime = 4.5
	},

	{id = "mc_planter01",
	ingreds = {
		{ id = "mc_brick01", count = 8 },
		{ id = "mc_clay", count = 20 },
		{ id = "mc_log_scrap", count = 3 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Furnishings",
	taskTime = 3
	},

	{id = "mc_planter02",
	ingreds = {
		{ id = "mc_brick01", count = 12 },
		{ id = "mc_clay", count = 52 },
		{ id = "mc_log_scrap", count = 4 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Furnishings",
	taskTime = 4
	},

	{id = "mc_planter03",
	ingreds = {
		{ id = "mc_brick01", count = 50 },
		{ id = "mc_clay", count = 80 },
		{ id = "mc_log_scrap", count = 8 }
		},
	yieldCount = 1,
	difficulty = 65,
	group = "Furnishings",
	taskTime = 8
	},

	{id = "mc_planter04",
	ingreds = {
		{ id = "mc_brick01", count = 100 },
		{ id = "mc_clay", count = 100 },
		{ id = "mc_log_scrap", count = 16 }
		},
	yieldCount = 1,
	difficulty = 75,
	group = "Furnishings",
	taskTime = 9
	},

	{id = "mc_planter05",
	ingreds = {
		{ id = "mc_brick01", count = 4 },
		{ id = "mc_clay", count = 14 },
		{ id = "mc_log_scrap", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	group = "Furnishings",
	taskTime = 3
	},

	{id = "mc_planter06",
	ingreds = {
		{ id = "mc_block20", count = 2 }
		},
	yieldCount = 1,
	difficulty = 85,
	group = "Furnishings",
	taskTime = 6
	},

	{id = "mc_well01",
	ingreds = {
		{ id = "mc_brick02", count = 20 },
		{ id = "mc_log_cypress", count = 4 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 85,
	group = "Miscellaneous",
	taskTime = 12
	},

	{id = "mc_well02",
	ingreds = {
		{ id = "mc_brick02", count = 20 },
		{ id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 75,
	group = "Miscellaneous",
	taskTime = 5
	},

	{id = "mc_altar01",
	ingreds = {
		{ id = "mc_block10", count = 10 },
		{ id = "mc_prepared_cloth", count = 6 }
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Furnishings",
	taskTime = 4
	},

	{id = "mc_altar02",
	ingreds = {
		{ id = "mc_brick01", count = 60 },
		{ id = "mc_clay", count = 20 },
		{ id = "mc_log_parasol", count = 12 }
		},
	yieldCount = 1,
	difficulty = 65,
	group = "Furnishings",
	taskTime = 5
	},

	}

return makerlist
