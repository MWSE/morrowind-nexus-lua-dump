--[[ Crafting-materials listing -- Cutting board cold food recipes
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		
		-- groups = Cold Dishes, Sandwiches, Miscellaneous
		
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
	byproduct = { id = "mc_straw", yield = 20 },
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
	byproduct = { id = "mc_straw", yield = 20 },
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
	byproduct = { id = "mc_straw", yield = 20 },
	yieldCount = 10,
	difficulty = 15,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_coarsefiber",
	ingreds = {
		{ id = "mc_straw", count = 10 }
		},
	alias = "Strip and soak straw into coarse fiber",
	yieldCount = 20,
	difficulty = 20,
	group = "Miscellaneous",
	taskTime = 0.3
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "T_IngFood_BreadDeshaan_01", count = 1 }
		},
	alias = "Slice Wide Deshaan bread",
	yieldCount = 8,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "T_IngFood_BreadDeshaan_03", count = 1 }
		},
	alias = "Slice Round Deshaan bread",
	yieldCount = 8,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "T_IngFood_BreadDeshaan_04", count = 1 }
		},
	alias = "Slice Deshaan half-loaf",
	yieldCount = 4,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "T_IngFood_BreadColovian_01", count = 1 }
		},
	alias = "Slice Colovian loaf",
	yieldCount = 8,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "T_IngFood_BreadColovian_02", count = 1 }
		},
	alias = "Slice Colovian half-loaf",
	yieldCount = 4,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "ingred_bread_01", count = 1 }
		},
	alias = "Slice local bread",
	yieldCount = 3,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "mc_wheatbread", count = 1 }
		},
	alias = "Slice wheat bread",
	yieldCount = 4,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "mc_ricebread", count = 1 }
		},
	alias = "Slice rice bread",
	yieldCount = 4,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_bread_slice",
	ingreds = {
		{ id = "mc_ryebread", count = 1 }
		},
	alias = "Slice rye bread",
	yieldCount = 4,
	difficulty = 2,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_sausagepod",
	ingreds = {
		{ id = "AnyRedMeat", count = 4 },
		{ id = "mc_onion", count = 1 },
		{ id = "ingred_scuttle_01", count = 1 },
		{ id = "mc_garlic", count = 1 },
		{ id = "ingred_fire_salts_01", count = 1, consumed = false }
		},
	yieldCount = 7,
	difficulty = 30,
	group = "Miscellaneous",
	taskTime = 0.5
	},
	
	{id = "mc_sandwich_crab",
	ingreds = {
		{ id = "mc_crabmeat_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "mc_onion", count = 1 },
		{ id = "mc_garlic", count = 1 },
		{ id = "mc_kanet_butter", count = 1 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	},
	
	{id = "mc_sandwich_fish",
	ingreds = {
		{ id = "mc_fish_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "ingred_chokeweed_01", count = 2 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	},
	
	{id = "mc_sandwich_guar",
	ingreds = {
		{ id = "mc_guar_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "ingred_chokeweed_01", count = 2 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	},

	{id = "mc_sandwich_alit",
	ingreds = {
		{ id = "mc_alit_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "ingred_chokeweed_01", count = 2 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	},
	
	{id = "mc_sandwich_hound",
	ingreds = {
		{ id = "mc_hound_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "ingred_chokeweed_01", count = 2 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	},
	
	{id = "mc_sandwich_kagouti",
	ingreds = {
		{ id = "mc_kagouti_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "ingred_chokeweed_01", count = 2 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	},
	
	{id = "mc_sandwich_racer",
	ingreds = {
		{ id = "mc_racer_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "ingred_chokeweed_01", count = 2 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	},
	
	{id = "mc_sandwich_rat",
	ingreds = {
		{ id = "mc_rat_cooked", count = 1 },
		{ id = "mc_bread_slice", count = 4 },
		{ id = "ingred_chokeweed_01", count = 2 }
		},
	yieldCount = 2,
	difficulty = 10,
	group = "Sandwiches",
	taskTime = 0.5
	}

	}

return makerlist
