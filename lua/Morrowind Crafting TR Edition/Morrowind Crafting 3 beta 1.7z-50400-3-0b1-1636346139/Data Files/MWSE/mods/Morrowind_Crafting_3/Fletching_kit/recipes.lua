--[[ Fletching-materials listing -- creating bolts/arrows/darts
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]

local makerlist = {}
makerlist = {
	{id = "T_De_Aena_Arrow_01",
	ingreds = {
		{ id = "mc_chitin_strips", count = 6 },
		{ id = "ingred_bonemeal_01", count = 2 },
		{ id = "ingred_shalk_resin_01", count = 1 }
		},
	yieldCount = 40,
	difficulty = 45,
	group = "Arrows",
	taskTime = 2
	},

	{id = "bonemold arrow",
	ingreds = {
		{ id = "ingred_bonemeal_01", count = 2 },
		{ id = "ingred_shalk_resin_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 40,
	group = "Arrows",
	taskTime = 1
	},
	
	{id = "chitin arrow",
	ingreds = {
		{ id = "mc_chitin_strips", count = 16 },
		{ id = "mc_chitin_glue", count = 4 }
		},
	yieldCount = 40,
	difficulty = 10,
	group = "Arrows",
	taskTime = 0.5
	},
	
	{id = "corkbulb arrow",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "ingred_corkbulb_root_01", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 5,
	group = "Arrows",
	taskTime = 0.5
	},
	
	{id = "daedric arrow",
	ingreds = {
		{ id = "mc_daedric_ebony", count = 1}
		},
	yieldCount = 12,
	difficulty = 125,
	group = "Arrows",
	taskTime = 4
	},
	
	{id = "ebony arrow",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 1}
		},
	yieldCount = 12,
	difficulty = 90,
	group = "Arrows",
	taskTime = 3
	},
	
	{id = "glass arrow",
	ingreds = {
		{ id = "ingred_raw_glass_01", count = 1}
		},
	yieldCount = 12,
	difficulty = 70,
	group = "Arrows",
	taskTime = 2
	},
	
	{id = "mc_heartwood_arrow",
	ingreds = {
		{ id = "ingred_heartwood_01", count = 1},
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_racer_plumes_01", count = 1}
		},
	yieldCount = 20,
	difficulty = 90,
	group = "Arrows",
	taskTime = 3.5
	},
			
	{id = "T_Imp_Legion_Arrow_01",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 55,
	group = "Arrows",
	taskTime = 1
	},
	
	{id = "iron arrow",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 20,
	group = "Arrows",
	taskTime = 0.5
	},
	
	{id = "mc_orcish_arrow",
	ingreds = {
		{ id = "mc_orichalcum_ingot", count = 1}
		},
	yieldCount = 12,
	difficulty = 60,
	group = "Arrows",
	taskTime = 1
	},
	
	{id = "silver arrow",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_silver_ingot", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 50,
	group = "Arrows",
	taskTime = 1
	},
	
	{id = "steel arrow",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 30,
	group = "Arrows",
	taskTime = 0.5
	},
	
	{id = "bonemold bolt",
	ingreds = {
		{ id = "ingred_bonemeal_01", count = 2 },
		{ id = "ingred_shalk_resin_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 40,
	group = "Bolts",
	taskTime = 1
	},
	
	{id = "corkbulb bolt",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "ingred_corkbulb_root_01", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 5,
	group = "Bolts",
	taskTime = 0.5
	},
	
	{id = "mc_bolt_daedric",
	ingreds = {
		{ id = "mc_daedric_ebony", count = 1}
		},
	yieldCount = 12,
	difficulty = 125,
	group = "Bolts",
	taskTime = 3
	},
	
	{id = "T_Dwe_Regular_Bolt_01",
	ingreds = {
		{ id = "mc_dwemer_ingot", count = 1}
		},
	yieldCount = 15,
	difficulty = 60,
	group = "Bolts",
	taskTime = 1.5
	},
	
	{id = "mc_bolt_ebony",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 1}
		},
	yieldCount = 12,
	difficulty = 90,
	group = "Bolts",
	taskTime = 2
	},
	
	{id = "mc_bolt_glass",
	ingreds = {
		{ id = "ingred_raw_glass_01", count = 1}
		},
	yieldCount = 12,
	difficulty = 70,
	group = "Bolts",
	taskTime = 1.5
	},
	
	{id = "mc_bolt_heartwood",
	ingreds = {
		{ id = "ingred_heartwood_01", count = 1},
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_racer_plumes_01", count = 1}
		},
	yieldCount = 20,
	difficulty = 90,
	group = "Bolts",
	taskTime = 2
	},
	
	{id = "BM Huntsmanbolt",
	ingreds = {
		{ id = "mc_log_pine", count = 1 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 10,
	group = "Bolts",
	taskTime = 0.25
	},
	
	{id = "T_Imp_Legion_Bolt_01",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 55,
	group = "Bolts",
	taskTime = 1.5
	},
	
	{id = "iron bolt",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 20,
	group = "Bolts",
	taskTime = 0.5
	},
	
	{id = "orcish bolt",
	ingreds = {
		{ id = "mc_orichalcum_ingot", count = 1}
		},
	yieldCount = 12,
	difficulty = 60,
	group = "Bolts",
	taskTime = 0.75
	},
	
	{id = "silver bolt",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_silver_ingot", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 50,
	group = "Bolts",
	taskTime = 1.25
	},
	
	{id = "steel bolt",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 20,
	difficulty = 30,
	group = "Bolts",
	taskTime = 0.75
	},
	
	{id = "daedric dart",
	ingreds = {
		{ id = "mc_daedric_ebony", count = 1}
		},
	yieldCount = 1,
	difficulty = 125,
	group = "Darts",
	taskTime = 1
	},
	
	{id = "centurion_projectile_dart",
	ingreds = {
		{ id = "mc_dwemer_ingot", count = 1}
		},
	yieldCount = 8,
	difficulty = 100,
	group = "Darts",
	taskTime = 2
	},
	
	{id = "ebony dart",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 1}
		},
	yieldCount = 1,
	difficulty = 110,
	group = "Darts",
	taskTime = 1
	},
	
	{id = "fine spring dart",
	ingreds = {
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_diamond_01", count = 1 }
		},
	yieldCount = 2,
	difficulty = 125,
	group = "Darts",
	taskTime = 4
	},
	
	{id = "T_Dwe_Regular_Dart_01",
	ingreds = {
		{ id = "mc_dwemer_ingot", count = 1}
		},
	yieldCount = 10,
	difficulty = 80,
	group = "Darts",
	taskTime = 1
	},
	
	{id = "silver dart",
	ingreds = {
		{ id = "mc_silver_ingot", count = 1 },
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 5,
	difficulty = 40,
	group = "Darts",
	taskTime = 1.5
	},
	
	{id = "spring dart",
	ingreds = {
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_pearl_01", count = 1 }
		},
	yieldCount = 2,
	difficulty = 115,
	group = "Darts",
	taskTime = 2
	},
	
	{id = "steel dart",
	ingreds = {
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 5,
	difficulty = 25,
	group = "Darts",
	taskTime = 0.5
	}

	}

return makerlist
