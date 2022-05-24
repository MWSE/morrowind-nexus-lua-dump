--[[ Poisons listing -- creating toxins to add to bolts/arrows/darts/stars
		Part of Morrowind Crafting 3.0
		Toccatta and Drac c/r 2019 --]]
	
local makerlist = {}
makerlist = {
	{id = "mc_poison01",
	ingreds = {
		{ id = "ingred_muck_01", count = 1 },
		{ id = "ingred_void_salts_01", count = 2 },
		{ id = "ingred_scamp_skin_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_stilltongue", count = 0, alias = "Recipe for Stilltongue" }
		},
	yieldCount = 1,
	difficulty = 50,
	taskTime = 5
	},
	
	{id = "mc_poison02",
	ingreds = {
		{ id = "ingred_fire_petal_01", count = 1 },
		{ id = "ingred_void_salts_01", count = 1 },
		{ id = "ingred_black_lichen_01", count = 1 },
		{ id = "ingred_hackle-lo_leaf_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_stith", count = 0, alias = "Recipe for Stith" }
		},
	yieldCount = 1,
	difficulty = 60,
	taskTime = 6
	},
	
	{id = "mc_poison03",
	ingreds = {
		{ id = "Ingred_nirthfly_stalks_01", count = 1 },
		{ id = "ingred_black_anther_01", count = 1 },
		{ id = "ingred_fire_salts_01", count = 1 },
		{ id = "mc_netch_acid", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_magruk_baj", count = 0, alias = "Recipe for Magruk Baj" }
		},
	yieldCount = 1,
	difficulty = 40,
	taskTime = 4
	},
	
	{id = "mc_poison04",
	ingreds = {
		{ id = "ingred_willow_anther_01", count = 1 },
		{ id = "ingred_trama_root_01", count = 1 },
		{ id = "ingred_fire_salts_01", count = 1 },
		{ id = "ingred_corprus_weepings_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_magrok_tuk", count = 0, alias = "Recipe for Magrok Tuk" }
		},
	yieldCount = 1,
	difficulty = 50,
	taskTime = 5
	},
	
	{id = "mc_poison05",
	ingreds = {
		{ id = "ingred_bittergreen_petals_01", count = 1 },
		{ id = "ingred_roobrush_01", count = 1 },
		{ id = "ingred_chokeweed_01", count = 1 },
		{ id = "ingred_daedra_skin_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_maisith", count = 0, alias = "Recipe for Maisith" }
		},
	yieldCount = 1,
	difficulty = 95,
	taskTime = 8
	},
	
	{id = "mc_poison06",
	ingreds = {
		{ id = "ingred_ruby_01", count = 1 },
		{ id = "ingred_fire_petal_01", count = 1 },
		{ id = "ingred_fire_salts_01", count = 1 },
		{ id = "ingred_red_lichen_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_earthblood", count = 0, alias = "Recipe for Earthblood" }
		},
	yieldCount = 1,
	difficulty = 80,
	taskTime = 8
	},
	
	{id = "mc_poison07",
	ingreds = {
		{ id = "ingred_holly_01", count = 1 },
		{ id = "ingred_belladonna_02", count = 1 },
		{ id = "ingred_gravetar_01", count = 1 },
		{ id = "ingred_frost_salts_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_kjelvik", count = 0, alias = "Recipe for Kjelvik" }
		},
	yieldCount = 1,
	difficulty = 70,
	taskTime = 7
	},
	
	{id = "mc_poison08",
	ingreds = {
		{ id = "mc_netch_acid", count = 1 },
		{ id = "ingred_roobrush_01", count = 1 },
		{ id = "ingred_black_lichen_01", count = 1 },
		{ id = "ingred_ash_salts_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_vvardith", count = 0, alias = "Recipe for Vvardith" }
		},
	yieldCount = 1,
	difficulty = 30,
	taskTime = 5
	},

	{id = "mc_poison09",
	ingreds = {
		{ id = "ingred_bc_bungler's_bane", count = 1 },
		{ id = "ingred_kagouti_hide_01", count = 1 },
		{ id = "ingred_ash_salts_01", count = 1 },
		{ id = "misc_skooma_vial", count = 1 },
		{ id = "mc_poison_darkeye", count = 0, alias = "Recipe for Darkeye" }
		},
	yieldCount = 1,
	difficulty = 65,
	taskTime = 5
	}

	}

return makerlist
