--[[ Crafting-materials listing -- Crafting bag
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		
	-- Groups = Apparatus, Containers, Glassware, Lighting, Wicker, Miscellaneous

local makerlist = {}
makerlist = {
	{id = "apparatus_a_alembic_01",
	ingreds = {
		{ id = "mc_sand", count = 16 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Apparatus",
	taskTime = 2
	},
	
	{id = "apparatus_j_alembic_01",
	ingreds = {
		{ id = "mc_sand", count = 10 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Apparatus",
	taskTime = 3
	},
	
	{id = "apparatus_m_alembic_01",
	ingreds = {
		{ id = "mc_sand", count = 8 },
		{ id = "mc_silver_ingot", count = 1 },
		{ id = "ingred_raw_glass_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 85,
	group = "Apparatus",
	taskTime = 4
	},
	
	{id = "apparatus_g_alembic_01",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_silver_ingot", count = 2 },
		{ id = "ingred_raw_glass_01", count = 2 }
		},
	yieldCount = 1,
	difficulty = 110,
	group = "Apparatus",
	taskTime = 5.5
	},

	{id = "T_De_Ebony_Alembic",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 8 },
		{ id = "mc_silver_ingot", count = 8 },
		{ id = "ingred_raw_glass_01", count = 8 }
		},
	yieldCount = 1,
	difficulty = 125,
	group = "Apparatus",
	taskTime = 8
	},
	
	{id = "apparatus_sm_alembic_01",
	ingreds = {
		{ id = "mc_silver_ingot", count = 12 },
		{ id = "ingred_raw_glass_01", count = 12 }
		},
	yieldCount = 1,
	difficulty = 135,
	group = "Apparatus",
	taskTime = 12
	},
	
	{id = "apparatus_a_calcinator_01",
	ingreds = {
		{ id = "mc_iron_ingot", count = 15 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Apparatus",
	taskTime = 2
	},
	
	{id = "apparatus_j_calcinator_01",
	ingreds = {
		{ id = "mc_iron_ingot", count = 10 }
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Apparatus",
	taskTime = 3
	},
	
	{id = "apparatus_m_calcinator_01",
	ingreds = {
		{ id = "mc_iron_ingot", count = 7 },
		{ id = "ingred_ash_salts_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 85,
	group = "Apparatus",
	taskTime = 4
	},
	
	{id = "apparatus_g_calcinator_01",
	ingreds = {
		{ id = "mc_iron_ingot", count = 5 },
		{ id = "ingred_diamond_01", count = 1 },
		{ id = "ingred_ash_salts_01", count = 2 }
		},
	yieldCount = 1,
	difficulty = 110,
	group = "Apparatus",
	taskTime = 5.5
	},

	{id = "T_De_Ebony_Calcinator",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 6 },
		{ id = "ingred_diamond_01", count = 10 },
		{ id = "ingred_ash_salts_01", count = 8 },
		{id = "mc_iron_ingot", count = 10}
		},
	yieldCount = 1,
	difficulty = 125,
	group = "Apparatus",
	taskTime = 8
	},
	
	{id = "apparatus_sm_calcinator_01",
	ingreds = {
		{ id = "mc_iron_ingot", count = 15 },
		{ id = "ingred_diamond_01", count = 12 },
		{ id = "ingred_fire_salts_01", count = 8 }
		},
	yieldCount = 1,
	difficulty = 135,
	group = "Apparatus",
	taskTime = 12
	},
	
	{id = "apparatus_a_mortar_01",
	ingreds = {
		{ id = "mc_sand", count = 8 },
		{ id = "ingred_resin_01", count = 4 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Apparatus",
	taskTime = 2
	},
	
	{id = "apparatus_j_mortar_01",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "ingred_resin_01", count = 2 },
		{ id = "ingred_raw_glass_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Apparatus",
	taskTime = 3
	},
	
	{id = "apparatus_m_mortar_01",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "ingred_raw_glass_01", count = 1 },
		{ id = "ingred_pearl_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 85,
	group = "Apparatus",
	taskTime = 4
	},
	
	{id = "apparatus_g_mortar_01",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "ingred_raw_glass_01", count = 1 },
		{ id = "ingred_diamond_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 110,
	group = "Apparatus",
	taskTime = 5.5
	},

	{id = "T_De_Ebony_Mortar",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 8 },
		{ id = "ingred_raw_glass_01", count = 8 },
		{ id = "ingred_diamond_01", count = 10 },
		{id = "ingred_pearl_01", count = 10}
		},
	yieldCount = 1,
	difficulty = 125,
	group = "Apparatus",
	taskTime = 8
	},
	
	{id = "apparatus_sm_mortar_01",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "ingred_raw_glass_01", count = 12 },
		{ id = "ingred_diamond_01", count = 12 }
		},
	yieldCount = 1,
	difficulty = 135,
	group = "Apparatus",
	taskTime = 12
	},
	
	{id = "apparatus_a_retort_01",
	ingreds = {
		{ id = "mc_sand", count = 12 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Apparatus",
	taskTime = 2
	},
	
	{id = "apparatus_j_retort_01",
	ingreds = {
		{ id = "mc_sand", count = 8 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Apparatus",
	taskTime = 3
	},
	
	{id = "apparatus_m_retort_01",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_raw_glass_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 85,
	group = "Apparatus",
	taskTime = 4
	},
	
	{id = "apparatus_g_retort_01",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_silver_ingot", count = 1 },
		{ id = "ingred_raw_glass_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 110,
	group = "Apparatus",
	taskTime = 5.5
	},

	{id = "T_De_Ebony_Retort",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 4 },
		{ id = "mc_silver_ingot", count = 10 },
		{ id = "ingred_raw_glass_01", count = 10 },
		{ id = "mc_sand", count = 20 }
		},
	yieldCount = 1,
	difficulty = 125,
	group = "Apparatus",
	taskTime = 8
	},
	
	{id = "apparatus_sm_retort_01",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "ingred_fire_salts_01", count = 10 },
		{ id = "ingred_frost_salts_01", count = 10 },
		{ id = "ingred_raw_glass_01", count = 12 }
		},
	yieldCount = 1,
	difficulty = 135,
	group = "Apparatus",
	taskTime = 12
	},
	
	{id = "mc_canister_b",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_stoneflower_petals_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_canister_c",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_muck_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_canister_g",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_green_lichen_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_canister_t",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_kwama_cuttle_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_canister_r",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_fire_petal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_canister_v",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_black_anther_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_canister_w",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_bonemeal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_canister_y",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_gold_kanet_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_crock_b",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_stoneflower_petals_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_crock_c",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_muck_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_crock_g",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_green_lichen_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_crock_t",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_kwama_cuttle_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_crock_r",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_fire_petal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_crock_v",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_black_anther_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_crock_w",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_bonemeal_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_crock_y",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_gold_kanet_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1.25
	},
	
	{id = "mc_jar_b",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_stoneflower_petals_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_jar_c",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_muck_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_jar_g",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_green_lichen_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_jar_t",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_kwama_cuttle_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_jar_r",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_fire_petal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_jar_v",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_black_anther_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_jar_w",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_bonemeal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "mc_jar_y",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_gold_kanet_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 40,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Nor_FlaskRed_02",
	alias = "Nordic Red Flask",
	ingreds = {
		{ id = "mc_sand", count = 3 },
		{ id = "ingred_fire_petal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Nor_FlaskRed_04",
	alias = "Nordic Wide Red Flask",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "ingred_fire_petal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1
	},
	
	{id = "T_Nor_FlaskGreen_02",
	alias = "Nordic Green Flask",
	ingreds = {
		{ id = "mc_sand", count = 3 },
		{ id = "ingred_green_lichen_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Nor_FlaskGreen_04",
	alias = "Nordic Wide Green Flask",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "ingred_green_lichen_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Nor_FlaskBlue_02",
	alias = "Nordic Blue Flask",
	ingreds = {
		{ id = "mc_sand", count = 3 },
		{ id = "ingred_stoneflower_petals_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Nor_FlaskBlue_04",
	alias = "Nordic Wide Blue Flask",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "ingred_stoneflower_petals_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Com_PotionBottle_01",
	alias = "Green Glass Bottle",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_green_lichen_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 60,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Com_PotionBottle_02",
	alias = "Fine Purple Glass Bottle",
	ingreds = {
		{ id = "mc_sand", count = 7 },
		{ id = "ingred_black_anther_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 70,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Com_PotionBottle_03",
	alias = "Red Glass Bottle",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_fire_petal_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 60,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Com_PotionBottle_04",
	alias = "Blue Glass Bottle",
	ingreds = {
		{ id = "mc_sand", count = 5 },
		{ id = "ingred_stoneflower_petals_01", count = 1 }
				},
	yieldCount = 1,
	difficulty = 60,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket08",
	ingreds = {
		{ id = "mc_straw", count = 30 },
		{id = "mc_rope", count = 1},
		{id = "mc_log_pine", count = 1}
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 3
	},
	
	{id = "mc_basket04",
	ingreds = {
		{ id = "mc_straw", count = 10 }
				},
	yieldCount = 1,
	difficulty = 25,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket01",
	ingreds = {
		{ id = "mc_straw", count = 20 }
				},
	yieldCount = 1,
	difficulty = 30,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket09",
	ingreds = {
		{ id = "mc_straw", count = 20 }
				},
	yieldCount = 1,
	difficulty = 50,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket10",
	ingreds = {
		{ id = "mc_straw", count = 12 }
				},
	yieldCount = 1,
	difficulty = 35,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket11",
	ingreds = {
		{ id = "mc_straw", count = 10 },
		{id = "mc_log_scrap", count = 1},
		{id = "misc_spool_01", count = 1}
				},
	yieldCount = 1,
	difficulty = 25,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket12",
	ingreds = {
		{ id = "mc_straw", count = 15 },
		{id = "mc_log_pine", count = 1},
		{id = "misc_spool_01", count = 1}
				},
	yieldCount = 1,
	difficulty = 25,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket13",
	ingreds = {
		{ id = "mc_straw", count = 10 },
		{id = "mc_log_scrap", count = 1},
		{id = "misc_spool_01", count = 1}
				},
	yieldCount = 1,
	difficulty = 25,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_basket14",
	ingreds = {
		{ id = "mc_straw", count = 10 },
		{id = "mc_log_scrap", count = 1},
		{id = "misc_spool_01", count = 2}
				},
	yieldCount = 1,
	difficulty = 25,
	group = "Containers",
	taskTime = 1
	},

	{id = "mc_chest31",
	ingreds = {
		{ id = "mc_straw", count = 20 },
		{id = "mc_log_scrap", count = 1}
				},
	yieldCount = 1,
	difficulty = 45,
	group = "Containers",
	taskTime = 3
	},
	
	{id = "misc_beaker_01",
	ingreds = {
		{ id = "mc_sand", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 0.5
	},
	
	{id = "misc_de_bowl_bugdesign_01",
	ingreds = {
		{ id = "mc_sand", count = 10 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Glassware",
	taskTime = 1
	},
	
	{id = "T_Rga_GlasswareBowl_01",
	ingreds = {
		{ id = "mc_sand", count = 8 }
		},
	yieldCount = 1,
	difficulty = 35,
	group = "Glassware",
	taskTime = 1
	},
	
	{id = "T_Rga_GlasswarePlate_01",
	ingreds = {
		{ id = "mc_sand", count = 6 }
		},
	yieldCount = 1,
	difficulty = 30,
	group = "Glassware",
	taskTime = 1
	},
	
	{id = "misc_skooma_vial",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 20,
	group = "Glassware",
	taskTime = 0.5
	},
	
	{id = "Misc_DE_glass_green_01",
	ingreds = {
		{ id = "mc_sand", count = 4 }
		},
	yieldCount = 1,
	difficulty = 25,
	group = "Glassware",
	taskTime = 0.5
	},

	{id = "Misc_inkwell",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 10,
	group = "Glassware",
	taskTime = 0.5
	},
	
	{id = "Misc_Com_Bottle_04",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_straw", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 1
	},
	
	{id = "misc_com_bottle_10",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_straw", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 1
	},
	
	{id = "misc_com_bottle_15",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_straw", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 1
	},
	
	{id = "Misc_Com_Bottle_08",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 10,
	group = "Glassware",
	taskTime = 0.25
	},
	
	{id = "misc_com_bottle_05",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 10,
	group = "Glassware",
	taskTime = 0.25
	},
	
	{id = "Misc_Com_Bottle_14",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 10,
	group = "Glassware",
	taskTime = 0.25
	},
	
	{id = "misc_com_bottle_03",
	ingreds = {
		{ id = "mc_sand", count = 4 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 0.25
	},
	
	{id = "misc_com_bottle_07",
	ingreds = {
		{ id = "mc_sand", count = 4 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 0.25
	},
	
	{id = "misc_com_bottle_12",
	ingreds = {
		{ id = "mc_sand", count = 4 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 0.25
	},

	{id = "mc_basin01",
	ingreds = {
		{ id = "mc_sand", count = 40 },
		{id ="mc_iron_ingot", count = 10}
		},
	yieldCount = 1,
	difficulty = 55,
	group = "Glassware",
	taskTime = 3
	},

	{id = "mc_cistern01e",
	ingreds = {
		{ id = "mc_sand", count = 50 },
		{id = "mc_iron_ingot", count = 2},
		{id = "mc_log_scrap", count = 2}
		},
	yieldCount = 1,
	difficulty = 55,
	group = "Glassware",
	taskTime = 3
	},
	
	{id = "misc_flask_01",
	alias = "Short, thin flask",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 15,
	group = "Glassware",
	taskTime = 0.75
	},
	
	{id = "misc_flask_03",
	alias = "Short, wide flask",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 20,
	group = "Glassware",
	taskTime = 0.5
	},
	
	{id = "misc_flask_04",
	alias = "Tall, thin flask",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 25,
	group = "Glassware",
	taskTime = 0.5
	},
	
	{id = "misc_flask_02",
	alias = "Tall, wide flask",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	group = "Glassware",
	taskTime = 0.75
	},

	{id = "misc_com_plate_01",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.5
	},

	{id = "misc_com_plate_02",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.5
	},

	{id = "misc_com_plate_03",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.5
	},

	{id = "misc_com_plate_04",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.5
	},

	{id = "misc_com_plate_05",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.25
	},

	{id = "misc_com_plate_06",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.5
	},

	{id = "misc_com_plate_07",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.25
	},

	{id = "misc_com_plate_08",
	ingreds = {
		{ id = "mc_sand", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	group = "Glassware",
	taskTime = 0.25
	},
	
	{id = "misc_de_bowl_glass_yellow_01",
	ingreds = {
		{ id = "mc_sand", count = 8 }
		},
	yieldCount = 1,
	difficulty = 30,
	group = "Glassware",
	taskTime = 0.75
	},
	
	{id = "misc_de_glass_yellow_01",
	ingreds = {
		{ id = "mc_sand", count = 4 }
		},
	yieldCount = 1,
	difficulty = 20,
	group = "Glassware",
	taskTime = 0.5
	},
	
	{id = "misc_lw_bowl",
	ingreds = {
		{ id = "mc_sand", count = 6 },
		{ id = "ingred_raw_glass_01", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	group = "Glassware",
	taskTime = 2
	},
	
	{id = "misc_lw_cup",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "ingred_raw_glass_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	group = "Glassware",
	taskTime = 1.5
	},
	
	{id = "misc_lw_flask",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "ingred_raw_glass_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 70,
	group = "Glassware",
	taskTime = 1.75
	},
	
	{id = "misc_lw_platter",
	ingreds = {
		{ id = "mc_sand", count = 6 },
		{ id = "ingred_raw_glass_01", count = 2 }
		},
	yieldCount = 1,
	difficulty = 90,
	group = "Glassware",
	taskTime = 2.5
	},
	
	{id = "mc_ashlamp01",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "ingred_bc_ampoule_pod", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "mc_ashlamp02",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "ingred_kwama_cuttle_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "mc_ashlamp03",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "ingred_fire_petal_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "mc_ashlamp04",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "Ingred_golden_sedge_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "mc_ashlamp05",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "ingred_black_anther_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "mc_ashlamp06",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "ingred_green_lichen_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "mc_ashlamp07",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "ingred_stoneflower_petals_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "light_de_buglamp_01_off",
	ingreds = {
		{ id = "mc_clay", count = 2 },
		{ id = "mc_fiber", count = 1 },
		{ id = "mc_lamp_oil", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 0.5
	},
	
	{id = "T_Imp_Var_ColLantern02_256",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "mc_tallow", count = 2 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "T_Imp_Var_ColLantern04_256",
	ingreds = {
		{ id = "mc_sand", count = 4 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_tallow", count = 2 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Lighting",
	taskTime = 1.25
	},
	
	{id = "T_Imp_Var_ColLantern05_256",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_tallow", count = 2 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "light_de_lantern_02",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_bc_ampoule_pod", count = 1 },
		{ id = "mc_tallow", count = 2 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "light_de_lantern_06",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "ingred_scathecraw_01", count = 1 },		
		{ id = "mc_tallow", count = 2 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "Light_De_Lantern_01",
	ingreds = {
		{ id = "sc_paper plain", count = 2 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "mc_fiber", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Lighting",
	taskTime = 1.25
	},
	
	{id = "light_de_lantern_07",
	ingreds = {
		{ id = "sc_paper plain", count = 2 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_stoneflower_petals_01", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "mc_fiber", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Lighting",
	taskTime = 1.25
	},
	
	{id = "light_de_lantern_11",
	ingreds = {
		{ id = "sc_paper plain", count = 2 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_fire_petal_01", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "mc_fiber", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Lighting",
	taskTime = 1.25
	},
	
	{id = "light_de_lantern_05",
	ingreds = {
		{ id = "sc_paper plain", count = 2 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "mc_fiber", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "light_de_lantern_10",
	ingreds = {
		{ id = "sc_paper plain", count = 2 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_stoneflower_petals_01", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "mc_fiber", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "light_de_lantern_14",
	ingreds = {
		{ id = "sc_paper plain", count = 2 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "ingred_fire_petal_01", count = 1 },
		{ id = "mc_lamp_oil", count = 1 },
		{ id = "mc_fiber", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "light_com_lantern_01",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "mc_tallow", count = 4 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 2,
	difficulty = 45,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "light_com_lantern_02",
	ingreds = {
		{ id = "mc_sand", count = 2 },
		{ id = "mc_log_hickory", count = 1 },
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "mc_tallow", count = 4 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 2,
	difficulty = 45,
	group = "Lighting",
	taskTime = 1
	},
	
	{id = "torch_256",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 },
		{ id = "mc_iron_ingot", count = 1 },
		{ id = "mc_tallow", count = 2 }
		},
	yieldCount = 2,
	difficulty = 20,
	group = "Lighting",
	taskTime = 0.1
	},
	
	{id = "mc_basket02",
	ingreds = {
		{ id = "mc_straw", count = 4 }
		},
	yieldCount = 2,
	difficulty = 35,
	group = "Wicker",
	taskTime = 1
	},
	
	{id = "mc_basket03",
	ingreds = {
		{ id = "mc_straw", count = 4 }
		},
	yieldCount = 2,
	difficulty = 30,
	group = "Wicker",
	taskTime = 0.75
	},
	
	{id = "misc_com_basket_01",
	ingreds = {
		{ id = "mc_straw", count = 4 }
		},
	yieldCount = 2,
	difficulty = 40,
	group = "Wicker",
	taskTime = 1
	},
	
	{id = "misc_com_basket_02",
	ingreds = {
		{ id = "mc_straw", count = 4 }
		},
	yieldCount = 2,
	difficulty = 35,
	group = "Wicker",
	taskTime = 1
	},
	
	{id = "misc_de_basket_01",
	ingreds = {
		{ id = "mc_straw", count = 4 }
		},
	yieldCount = 2,
	difficulty = 25,
	group = "Wicker",
	taskTime = .75
	},
	
	{id = "sc_paper plain",
	ingreds = {
		{ id = "mc_fiber", count = 10 },
		{ id = "Ingred_sweetpulp_01", count = 5 },
		{ id = "mc_starch", count = 4}
		},
	yieldCount = 8,
	difficulty = 10,
	group = "Miscellaneous",
	taskTime = 0.25
	},
	
	{id = "mc_parchment",
	ingreds = {
		{ id = "ingred_netch_leather_01", count = 3 },
		{ id = "mc_netch_acid", count = 1}
		},
	yieldCount = 3,
	difficulty = 30,
	group = "Miscellaneous",
	taskTime = 0.75
	},
	
	{id = "mc_vellum",
	ingreds = {
		{ id = "ingred_scamp_skin_01", count = 1 },
		{ id = "mc_netch_acid", count = 1}
		},
	yieldCount = 1,
	difficulty = 50,
	group = "Miscellaneous",
	taskTime = 1.25
	},
	
	{id = "misc_quill",
	ingreds = {
		{ id = "ingred_racer_plumes_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 4,
	group = "Miscellaneous",
	taskTime = 0.1
	},

	{id = "mc_basket15",
	ingreds = {
		{ id = "mc_straw", count = 4 }
		},
	yieldCount = 1,
	difficulty = 20,
	group = "Containers",
	taskTime = 1
	},

	{id = "T_Rga_Wicker_Shield",
	ingreds = {
		{id = "mc_straw", count = 30},
		{id = "mc_log_hickory", count = 1}
		},
	yieldCount = 1,
	difficulty = 30,
	group = "Wicker",
	taskTime = 1
	}
}

return makerlist
