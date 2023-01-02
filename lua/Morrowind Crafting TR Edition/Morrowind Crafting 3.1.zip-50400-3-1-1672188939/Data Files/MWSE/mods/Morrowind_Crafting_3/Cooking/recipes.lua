--[[ Crafting-materials listing -- Cook fire and camp fire hot food recipes
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		
		--groups = Hot Dishes, Grilled Meats, Soups and Stews, Baked Goods, Miscellaneous

local makerlist = {}
makerlist = {

	{id = "mc_crabmeat_cooked",
	alias = "Steamed mudcrab",
	ingreds = {
		{ id = "ingred_crab_meat_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	modifier = "mc_saucepan",
	group = "Hot Dishes",
	taskTime = 0.25
	},
	
	{id = "mc_crabmeat_cooked",
	alias = "Steamed ornada",
	ingreds = {
		{ id = "T_IngFood_MeatOrnada_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	modifier = "mc_saucepan",
	group = "Hot Dishes",
	taskTime = 0.25
	},
	
	{id = "mc_fried_mushroom",
	alias = "Fried mushrooms",
	ingreds = {
		{ id = "AnyMushroom", count = 1 }
		},
	yieldCount = 1,
	difficulty = 24,
	modifier = "mc_saucepan",
	group = "Hot Dishes",
	taskTime = 0.25
	},
	
	{id = "mc_kwamalarge",
	alias = "Large boiled kwama egg",
	ingreds = {
		{ id = "food_kwama_egg_02", count = 1 }
		},
	yieldCount = 1,
	difficulty = 13,
	modifier = "mc_saucepan",
	group = "Hot Dishes",
	taskTime = 0.5
	},
	
	{id = "mc_kwamasmall",
	alias = "Small boiled kwama egg",
	ingreds = {
		{ id = "food_kwama_egg_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 13,
	modifier = "mc_saucepan",
	group = "Hot Dishes",
	taskTime = 0.5
	},
	
	{id = "mc_potato_baked",
	alias = "Baked potato",
	ingreds = {
		{ id = "Potato", count = 1 }
		},
	yieldCount = 1,
	difficulty = 21,
	group = "Hot Dishes",
	taskTime = 0.75
	},
	
	{id = "mc_ashyam_baked",
	alias = "Roasted ash yam",
	ingreds = {
		{ id = "ingred_ash_yam_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 21,
	group = "Hot Dishes",
	taskTime = 0.75
	},
	
	{id = "mc_bubble_squeak",
	alias = "Bubble -n- squeek",
	ingreds = {
		{ id = "ingred_scrib_cabbage_01", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "Garlic", count = 1 },
		{ id = "Potato", count = 1 }
		},
	yieldCount = 1,
	difficulty = 57,
	modifier = "mc_saucepan",
	group = "Hot Dishes",
	taskTime = 0.5
	},
	
	{id = "mc_guar_cooked",
	alias = "Grilled guar steak",
	ingreds = {
		{ id = "T_IngFood_MeatGuar_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 9,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.5
	},

	{id = "mc_alit_cooked",
	alias = "Grilled alit brisket",
	ingreds = {
		{ id = "T_IngFood_MeatAlit_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.5
	},
	
	{id = "mc_hound_cooked",
	alias = "Grilled hound meat",
	ingreds = {
		{ id = "ingred_hound_meat_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 7,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.5
	},
	
	{id = "mc_kagouti_cooked",
	alias = "Fried kagouti chops",
	ingreds = {
		{ id = "T_IngFood_MeatKagouti_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 11,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.5
	},
	
	{id = "mc_rat_cooked",
	alias = "Braised rat cutlets",
	ingreds = {
		{ id = "ingred_rat_meat_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 7,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.75
	},
	
	{id = "mc_racer_cooked",
	alias = "Grilled racer breast",
	ingreds = {
		{ id = "T_IngFood_MeatCliffracer_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 11,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.5
	},
	
	{id = "mc_durzog_cooked",
	alias = "Durzog rump roast",
	ingreds = {
		{ id = "ingred_durzog_meat_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.75
	},
	
	{id = "mc_fish_cooked",
	alias = "Broiled slaughterfish steak",
	ingreds = {
		{ id = "mc_fish_raw", count = 1 }
		},
	yieldCount = 1,
	difficulty = 9,
	modifier = "mc_skillet",
	group = "Grilled Meats",
	taskTime = 0.5
	},
	
	{id = "mc_guarstew",
	alias = "Guar stew",
	ingreds = {
		{ id = "Onion", count = 1 },
		{ id = "Potato", count = 1 },
		{ id = "Garlic", count = 1 },
		{ id = "ingred_scrib_jelly_01", count = 1 },
		{ id = "T_IngFood_MeatGuar_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 61,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 0.75
	},
	
	{id = "mc_kagarine",
	alias = "Kagarine",
	ingreds = {
		{ id = "T_IngFood_MeatKagouti_01", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "Garlic", count = 1 },
		{ id = "ingred_scuttle_01", count = 1 },
		{ id = "mc_starch", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 93,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 1
	},
	
	{id = "mc_potluckstew",
	alias = "Potluck stew",
	ingreds = {
		{ id = "AnyRedMeat", count = 1 },
		{ id = "AnyMushroom", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "Potato", count = 1 },
		{ id = "ingred_bittergreen_petals_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 73,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 1
	},
	
	{id = "mc_racerrevenge",
	alias = "Racer revenge",
	ingreds = {
		{ id = "Potato", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "mc_fish_bladder", count = 1 },
		{ id = "T_IngFood_MeatCliffracer_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 89,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 1
	},
	
	{id = "mc_seafood_medley",
	alias = "Seafood medley",
	ingreds = {
		{ id = "mc_fish_raw", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "mc_riceflour", count = 1 },
		{ id = "ingred_bittergreen_petals_01", count = 1 },
		{ id = "ingred_crab_meat_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 77,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 1.25
	},
	
	{id = "mc_seafood_stew",
	alias = "Seafood chowder",
	ingreds = {
		{ id = "mc_fish_bladder", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "ingred_saltrice_01", count = 1 },
		{ id = "mc_sausagepod", count = 1 },
		{ id = "ingred_crab_meat_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 97,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 1.25
	},
	
	{id = "mc_felaril",
	alias = "Felaril",
	ingreds = {
		{ id = "mc_sausagepod", count = 1 },
		{ id = "ingred_saltrice_01", count = 1 },
		{ id = "ingred_bc_hypha_facia", count = 1 },
		{ id = "ingred_bittergreen_petals_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 85,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 1
	},
	
	{id = "mc_glowpotsoup",
	alias = "Glowpot soup",
	ingreds = {
		{ id = "ingred_bc_ampoule_pod", count = 1 },
		{ id = "ingred_willow_anther_01", count = 1 },
		{ id = "Garlic", count = 1 },
		{ id = "mc_riceflour", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 101,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 1.5
	},
	
	{id = "mc_mushroomsoup",
	alias = "Mushroom soup",
	ingreds = {
		{ id = "mc_sugar", count = 1 },
		{ id = "mc_kanet_butter", count = 1 },
		{ id = "AnyMushroom", count = 1 },
		{ id = "mc_starch", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 69,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 0.75
	},
	
	{id = "mc_root_soup",
	alias = "Root soup",
	ingreds = {
		{ id = "Potato", count = 1 },
		{ id = "ingred_ash_yam_01", count = 1 },
		{ id = "ingred_trama_root_01", count = 1 },
		{ id = "Garlic", count = 1 },
		{ id = "KwamaEgg", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 81,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 0.75
	},
	
	{id = "mc_scuttle_soup",
	alias = "Scuttle soup",
	ingreds = {
		{ id = "Onion", count = 1 },
		{ id = "mc_sugar", count = 1 },
		{ id = "ingred_chokeweed_01", count = 1 },
		{ id = "ingred_scuttle_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 57,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 0.5
	},
	
	{id = "mc_spice_soup",
	alias = "Spice soup",
	ingreds = {
		{ id = "Onion", count = 1 },
		{ id = "Potato", count = 1 },
		{ id = "ingred_chokeweed_01", count = 1 },
		{ id = "ingred_bittergreen_petals_01", count = 1 },
		{ id = "ingred_roobrush_01", count = 1 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 81,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 0.75
	},
	
	{id = "mc_trailbroth",
	alias = "Trail broth",
	ingreds = {
		{ id = "ingred_scrib_jelly_01", count = 1 },
		{ id = "ingred_bloat_01", count = 1 },
		{ id = "AnyRedMeat", count = 2 },
		{ id = "SmallBowl", count = 1 }
		},
	yieldCount = 1,
	difficulty = 45,
	modifier = "misc_com_iron_ladle",
	group = "Soups and Stews",
	taskTime = 0.5
	},
	
	{id = "mc_wheatbread",
	alias = "Wheat bread",
	ingreds = {
		{ id = "mc_wheatflour", count = 2 }
		},
	yieldCount = 1,
	difficulty = 18,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_ryebread",
	alias = "Rye bread",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "mc_ryeflour", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_ricebread",
	alias = "Rice bread",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "mc_riceflour", count = 1 }
		},
	yieldCount = 1,
	difficulty = 27,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_suncake",
	alias = "Suncake",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "KwamaEgg", count = 1 },
		{ id = "Ingred_golden_sedge_01", count = 1 },
		{ id = "ingred_scrib_jelly_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 49,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_swamproll",
	alias = "Swamproll",
	ingreds = {
		{ id = "ingred_bc_spore_pod", count = 2 },
		{ id = "mc_riceflour", count = 1 },
		{ id = "ingred_bloat_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 41,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 0.5
	},
	
	{id = "mc_sweetbread",
	alias = "Sweetbread",
	ingreds = {
		{ id = "mc_riceflour", count = 1 },
		{ id = "ingred_comberry_01", count = 1 },
		{ id = "Ingred_sweetpulp_01", count = 1 },
		{ id = "KwamaEgg", count = 1 }
		},
	yieldCount = 1,
	difficulty = 45,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_sweetcake",
	alias = "Sweetcake",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "mc_sugar", count = 1 },
		{ id = "Ingred_sweetpulp_01", count = 1 },
		{ id = "KwamaEgg", count = 1 }
		},
	yieldCount = 1,
	difficulty = 49,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_trailcake",
	alias = "Trailcake",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "mc_riceflour", count = 1 },
		{ id = "ingred_comberry_01", count = 1 },
		{ id = "ingred_sweetpulp_01", count = 1}
		},
	yieldCount = 1,
	difficulty = 53,
	modifier = "misc_com_wood_spoon_02",
	group = "Baked Goods",
	taskTime = 1.5
	},
	
	{id = "mc_plains_pie",
	alias = "Plains pie",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "ingred_heather_01", count = 1 },
		{ id = "ingred_stoneflower_petals_01", count = 1 },
		{ id = "KwamaEgg", count = 1 }
		},
	yieldCount = 1,
	difficulty = 61,
	modifier = "misc_rollingpin_01",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_pot_pie",
	alias = "Racer pot pie",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "T_IngFood_MeatCliffracer_01", count = 1 },
		{ id = "ingred_ash_yam_01", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "Garlic", count = 1 }
		},
	yieldCount = 1,
	difficulty = 65,
	modifier = "misc_rollingpin_01",
	group = "Baked Goods",
	taskTime = 0.75
	},
	
	{id = "mc_quiche",
	alias = "Kwama quiche",
	ingreds = {
		{ id = "mc_sausagepod", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "Garlic", count = 1 },
		{ id = "KwamaEgg", count = 1 }
		},
	yieldCount = 1,
	difficulty = 69,
	modifier = "misc_rollingpin_01",
	group = "Baked Goods",
	taskTime = 0.5
	},
	
	{id = "mc_sweetyam_pie",
	alias = "Sweet yam pie",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "mc_sugar", count = 1 },
		{ id = "ingred_sweetpulp_01", count = 1 },
		{ id = "ingred_ash_yam_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 65,
	modifier = "misc_rollingpin_01",
	group = "Baked Goods",
	taskTime = 0.75
	},
	
	{id = "mc_berry_pie",
	alias = "Mixed berry pie",
	ingreds = {
		{ id = "mc_wheatflour", count = 1 },
		{ id = "mc_sugar", count = 1 },
		{ id = "ingred_comberry_01", count = 1 },
		{ id = "ingred_belladonna_01", count = 1 },
		{ id = "ingred_holly_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 73,
	modifier = "misc_rollingpin_01",
	group = "Baked Goods",
	taskTime = 1
	},
	
	{id = "mc_guarherdpie",
	alias = "Guarherd pie",
	ingreds = {
		{ id = "AnyRedMeat", count = 1 },
		{ id = "Onion", count = 1 },
		{ id = "ingred_trama_root_01", count = 1 },
		{ id = "Potato", count = 1 }
		},
	yieldCount = 1,
	difficulty = 77,
	modifier = "misc_rollingpin_01",
	group = "Baked Goods",
	taskTime = 1
	},

	{id = "mc_hackle-lo_powder",
	alias = "Process hackle-lo leaf: gives powder and coarse fiber",
	ingreds = {
		{ id = "ingred_hackle-lo_leaf_01", count = 20 }
		},
	byproduct = {{ id = "mc_coarsefiber", yield = 20 }},
	yieldCount = 10,
	difficulty = 33,
	group = "Miscellaneous",
	taskTime = .5
	},
	
	{id = "mc_starch",
	alias = "Process kresh fiber: gives fiber and starch",
	ingreds = {
		{ id = "ingred_kresh_fiber_01", count = 20 }
		},
	byproduct = {{ id = "mc_fiber", yield = 20 }},
	yieldCount = 10,
	difficulty = 27,
	group = "Miscellaneous",
	taskTime = 0.5
	},
	
	{id = "mc_sugar",
	alias = "Process marshmerrow: gives fiber and sugar",
	ingreds = {
		{ id = "ingred_marshmerrow_01", count = 20 }
		},
	byproduct = {{ id = "mc_fiber", yield = 20 }},
	yieldCount = 10,
	difficulty = 33,
	group = "Miscellaneous",
	taskTime = 0.5
	},	
	
	{id = "mc_sweetoil",
	alias = "Process scathecraw: gives sweet oil and coarse fiber",
	ingreds = {
		{ id = "ingred_scathecraw_01", count = 20 }
		},
	byproduct = {{ id = "mc_coarsefiber", yield = 20 }},
	yieldCount = 10,
	difficulty = 33,
	group = "Miscellaneous",
	taskTime = 1
	},

	{id = "mc_fiber",
	alias = "Process velk silk: gives fiber and coarse fiber",
	ingreds = {
		{ id = "mc_velksilk", count = 5 }
		},
	byproduct = {{ id = "mc_coarsefiber", yield = 5 }},
	yieldCount = 5,
	difficulty = 20,
	group = "Miscellaneous",
	taskTime = 0.25
	},	
	
	{id = "mc_lamp_oil",
	alias = "Render horker blubber: gives lamp oil & tallow",
	ingreds = {
		{ id = "mc_horker_blubber", count = 10 },
		{ id = "mc_sweetoil", count = 1 }
		},
	byproduct = {{ id = "mc_tallow", yield = 50 }},
	yieldCount = 5,
	difficulty = 33,
	group = "Miscellaneous",
	taskTime = 1
	},
	
	{id = "mc_chitin_glue",
	alias = "Brew a batch of chitin glue",
	ingreds = {
		{ id = "ingred_shalk_resin_01", count = 1 },
		{ id = "mc_starch", count = 50 }
		},
	yieldCount = 50,
	difficulty = 25,
	group = "Miscellaneous",
	taskTime = 0.5
	},
	
	{id = "mc_fiber",
	alias = "Process Cloth Scraps into Fiber",
	ingreds = {
		{ id = "mc_netch_acid", count = 1 },
		{ id = "mc_clothscraps", count = 100 }
		},
	yieldCount = 100,
	difficulty = 40,
	group = "Miscellaneous",
	taskTime = 0.5
	},
	
	{id = "p_cure_paralyzation_s",
	ingreds = {
		{ id = "ingred_willow_anther_01", count = 1 },
		{ id = "ingred_corkbulb_root_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Miscellaneous",
	taskTime = 2
	},
	
	{id = "p_cure_poison_s",
	ingreds = {
		{ id = "ingred_scrib_jelly_01", count = 1 },
		{ id = "ingred_roobrush_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Miscellaneous",
	taskTime = 2
	},
	
	{id = "p_cure_common_s",
	ingreds = {
		{ id = "ingred_gravedust_01", count = 1 },
		{ id = "ingred_green_lichen_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Miscellaneous",
	taskTime = 2
	},
	
	{id = "p_cure_blight_s",
	ingreds = {
		{ id = "ingred_ash_salts_01", count = 1 },
		{ id = "ingred_scrib_jelly_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Miscellaneous",
	taskTime = 2
	},
	
	{id = "p_water_walking_s",
	ingreds = {
		{ id = "ingred_coprinus_01", count = 1 },
		{ id = "ingred_scales_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 70,
	group = "Miscellaneous",
	taskTime = 2
	},
	
	{id = "p_water_breathing_s",
	ingreds = {
		{ id = "ingred_russula_01", count = 1 },
		{ id = "ingred_hackle-lo_leaf_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 70,
	group = "Miscellaneous",
	taskTime = 2
	},
	
	{id = "p_disease_resistance_s",
	ingreds = {
		{ id = "ingred_ash_yam_01", count = 1 },
		{ id = "ingred_resin_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 70,
	group = "Miscellaneous",
	taskTime = 2
	},
	
	{id = "p_levitation_s",
	ingreds = {
		{ id = "ingred_bc_coda_flower", count = 1 },
		{ id = "ingred_trama_root_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 70,
	group = "Miscellaneous",
	taskTime = 2
	}
		
	}

return makerlist