--[[ Crafting-materials listing -- Cutting board cold food recipes
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		
		-- groups Cold Dishes, Sandwiches, Miscellaneous
		
local makerlist = {}
makerlist = {
	{id = "mc_chefsalad",
	ingreds = {
		{ id = "mc_racer_cooked", count = 1 },
		{ id = "ingred_bittergreen_petals_01", count = 1 },
		{ id = "ingred_red_lichen_01", count = 1 },
		{ id = "ingred_roobrush_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 37,
	group = "Cold Dishes",
	taskTime = 0.2
	},
	
	{id = "mc_mixedgreens",
	ingreds = {
		{ id = "ingred_chokeweed_01", count = 1 },
		{ id = "ingred_green_lichen_01", count = 1 },
		{ id = "ingred_hackle-lo_leaf_01", count = 1 },
		{ id = "ingred_roobrush_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	group = "Cold Dishes",
	taskTime = 0.2
	},
	
	{id = "mc_potatosalad",
	ingreds = {
		{ id = "mc_potato_baked", count = 1 },
		{ id = "mc_kwamasmall", count = 1 },
		{ id = "mc_onion", count = 1 },
		{ id = "mc_kanet_butter", count = 1 },
		{ id = "ingred_muck_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 53,
	modifier = "misc_com_wood_spoon_02",
	group = "Cold Dishes",
	taskTime = 0.2
	},
	
	{id = "mc_ricetreat",
	ingreds = {
		{ id = "ingred_saltrice_01", count = 1 },
		{ id = "ingred_marshmerrow_01", count = 1 },
		{ id = "mc_kanet_butter", count = 1 }
		},
	yieldCount = 1,
	difficulty = 33,
	modifier = "misc_com_wood_spoon_02",
	group = "Cold Dishes",
	taskTime = 0.5
	},
	
	{id = "mc_wheatroll",
	ingreds = {
		{ id = "ingred_wickwheat_01", count = 1 },
		{ id = "ingred_marshmerrow_01", count = 1 },
		{ id = "mc_kanet_butter", count = 1 }
		},
	yieldCount = 1,
	difficulty = 37,
	modifier = "misc_com_wood_spoon_02",
	group = "Cold Dishes",
	taskTime = 01
	},

	{id = "mc_pemmican",
	ingreds = {
		{ id = "AnyRedMeat", count = 2 },
		{ id = "ingred_wickwheat_01", count = 1 },
		{ id = "mc_horker_blubber", count = 1 },
		{ id = "ingred_comberry_01", count = 1 }
		},
	yieldCount = 5,
	difficulty = 40,
	group = "Cold Dishes",
	taskTime = 1
	},
		
	{id = "mc_kanet_butter",
	ingreds = {
		{ id = "ingred_gold_kanet_01", count = 1 },
		{ id = "ingred_kwama_cuttle_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 24,
	modifier = "misc_com_wood_spoon_02",
	group = "Miscellaneous",
	taskTime = 0.5
	},
	
	{id = "mc_riceflour",
	ingreds = {
		{ id = "ingred_saltrice_01", count = 20 }
		},
	alias = "Thresh saltrice: gives flour and straw",
	byproduct = {{ id = "mc_straw", yield = 20 }},
	yieldCount = 10,
	difficulty = 15,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_ryeflour",
	ingreds = {
		{ id = "Ingred_meadow_rye_01", count = 20 }
		},
	alias = "Thresh meadow rye: gives flour and straw",
	byproduct = {{ id = "mc_straw", yield = 20 }},
	yieldCount = 10,
	difficulty = 18,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_wheatflour",
	ingreds = {
		{ id = "ingred_wickwheat_01", count = 20 }
		},
	alias = "Thresh wickwheat: gives flour and straw",
	byproduct = {{ id = "mc_straw", yield = 20 }},
	yieldCount = 10,
	difficulty = 15,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_sausagepod",
	ingreds = {
		{ id = "AnyRedMeat", count = 4 },
		{ id = "mc_onion", count = 1 },
		{ id = "ingred_scuttle_01", count = 1 },
		{ id = "mc_garlic", count = 1 },
		{ id = "ingred_fire_salts_01", count = 0 }
		},
	yieldCount = 7,
	difficulty = 30,
	group = "Miscellaneous",
	taskTime = 0.5
	}

	}

return makerlist
