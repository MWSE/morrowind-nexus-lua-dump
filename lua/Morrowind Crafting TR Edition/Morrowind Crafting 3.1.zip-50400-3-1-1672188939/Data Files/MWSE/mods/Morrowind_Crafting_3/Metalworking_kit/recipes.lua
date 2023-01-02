--[[ Metalworking-group listing
		Part of Morrowind Crafting 3.0
		Group = Armorer, Containers, Furniture, Ingots, Kitchen, Lighting, Miscellaneous, Security, Silverware
		Toccatta and Drac --]]
	
	local makerlist = {}
	makerlist = {
		{id = "repair_prongs",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Armorer",
		taskTime = 0.2
		},
	
		{id = "hammer_repair",
		ingreds = {
			{id = "mc_iron_ingot", count = 2},
			{id = "mc_log_ash", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Armorer",
		taskTime = 0
		},
		
		{id = "repair_journeyman_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Armorer",
		taskTime = 0
		},
		
		{id = "repair_master_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 90,
		group = "Armorer",
		taskTime = 0
		},
		
		{id = "repair_grandmaster_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 110,
		group = "Armorer",
		taskTime = 0
		},
		
		{id = "repair_secretmaster_01a",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 130,
		group = "Armorer",
		taskTime = 0
		},
	
		{id = "mc_barrel03",
		ingreds = {
			{id = "mc_iron_ingot", count = 21}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_barrel04",
		ingreds = {
			{id = "mc_iron_ingot", count = 11}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_cabinet02",
		ingreds = {
			{id = "mc_iron_ingot", count = 26}
		},
		yieldCount = 1,
		difficulty = 80,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_Rcabinet02",
		ingreds = {
			{id = "mc_iron_ingot", count = 20},
			{id = "mc_dwemer_ingot", count = 6}
		},
		yieldCount = 1,
		difficulty = 95,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_chest08",
		ingreds = {
			{id = "mc_iron_ingot", count = 11}
		},
		yieldCount = 1,
		difficulty = 55,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_chest09",
		ingreds = {
			{id = "mc_iron_ingot", count = 6}
		},
		yieldCount = 1,
		difficulty = 60,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_desk04",
		ingreds = {
			{id = "mc_iron_ingot", count = 21}
		},
		yieldCount = 1,
		difficulty = 75,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_drawers05",
		ingreds = {
			{id = "mc_iron_ingot", count = 31}
		},
		yieldCount = 1,
		difficulty = 80,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_table24",
		ingreds = {
			{id = "mc_iron_ingot", count = 13}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_wardrobe06",
		ingreds = {
			{id = "mc_iron_ingot", count = 31}
		},
		yieldCount = 1,
		difficulty = 90,
		group = "Containers",
		taskTime = 0
		},
		
		{id = "mc_bed12",
		ingreds = {
			{id = "mc_iron_ingot", count = 23},
			{id = "mc_prepared_cloth", count = 8},
			{id = "mc_straw", count = 4},
		},
		yieldCount = 1,
		difficulty = 55,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_bench09",
		ingreds = {
			{id = "mc_iron_ingot", count = 11}
		},
		yieldCount = 1,
		difficulty = 23,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_bench10",
		ingreds = {
			{id = "mc_iron_ingot", count = 8}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_bookshelf05",
		ingreds = {
			{id = "mc_iron_ingot", count = 31}
		},
		yieldCount = 1,
		difficulty = 27,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_chair07",
		ingreds = {
			{id = "mc_iron_ingot", count = 9}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_exhaust_hood01",
		ingreds = {
			{id = "mc_iron_ingot", count = 51}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_stool06",
		ingreds = {
			{id = "mc_iron_ingot", count = 6}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_stool07",
		ingreds = {
			{id = "mc_iron_ingot", count = 7}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_table25",
		ingreds = {
			{id = "mc_iron_ingot", count = 26}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_table26",
		ingreds = {
			{id = "mc_iron_ingot", count = 21}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Furniture",
		taskTime = 0
		},
		
		{id = "mc_table27",
		ingreds = {
			{id = "mc_iron_ingot", count = 9}
		},
		yieldCount = 1,
		difficulty = 35,
		group = "Furniture",
		taskTime = 0
		},

		{id = "mc_adamantium_ingot",
		alias = "Adamantium ingot (Adamantium scrap)",
		ingreds = {
			{id = "mc_scrap_adamantium", count = 1},
			{ id = "mc_crucible", count = 1}
		},
		yieldCount = 1,
		difficulty = 15,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_adamantium_ingot",
		alias = "Batch melt adamantium scrap into ingots",
		ingreds = {
			{id = "mc_scrap_adamantium", count = 1},
			{ id = "mc_crucible", count = 1}
		},
		yieldCount = 1,
		autocomplete = true,
		difficulty = 15,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_dae_steel_ingot",
		alias = "Daedric steel ingot (Daedric steel scrap)",
		ingreds = {
			{ id = "mc_scrap_daesteel", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		difficulty = 20,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_dae_steel_ingot",
		alias = "Batch melt Daedric steel scrap into ingots",
		ingreds = {
			{ id = "mc_scrap_daesteel", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		autocomplete = true,
		difficulty = 20,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_dwemer_ingot",
		alias = "Dwemer ingot (Dwemer scrap)",
		ingreds = {
			{ id = "mc_scrap_dwemer", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		difficulty = 15,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_dwemer_ingot",
		alias = "Batch melt Dwemer scrap into ingots",
		ingreds = {
			{ id = "mc_scrap_dwemer", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		autocomplete = true,
		difficulty = 15,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_iron_ingot",
		alias = "Iron ingot (Iron scrap)",
		ingreds = {
			{ id = "mc_scrap_iron", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		difficulty = 5,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_iron_ingot",
		alias = "Batch melt iron scrap into ingots",
		ingreds = {
			{ id = "mc_scrap_iron", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		autocomplete = true,
		difficulty = 5,
		group = "Ingots",
		taskTime = 0
		},

		{id = "mc_iron_ingot",
		alias = "Iron ingot (TR Metal Blank)",
		ingreds = {
			{ id = "T_Com_MetalBlank_01", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 5,
		difficulty = 10,
		group = "Ingots",
		taskTime = 0
		},

		{id = "mc_iron_ingot",
		alias = "Iron ingot (TR Iron Ingot)",
		ingreds = {
			{ id = "T_Com_MetalPieceIron_01", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 10,
		difficulty = 5,
		group = "Ingots",
		taskTime = 0
		},

		{id = "mc_orichalcum_ingot",
		alias = "Orichalcum ingot (Orichalcum scrap)",
		ingreds = {
			{ id = "mc_scrap_orcish", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		difficulty = 15,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_orichalcum_ingot",
		alias = "Batch melt orichalcum scrap into ingots",
		ingreds = {
			{ id = "mc_scrap_orcish", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		autocomplete = true,
		difficulty = 15,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_silver_ingot",
		alias = "Silver ingot (Silver scrap)",
		ingreds = {
			{ id = "mc_scrap_silver", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		difficulty = 10,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "mc_silver_ingot",
		alias = "Batch melt silver scrap into ingots",
		ingreds = {
			{ id = "mc_scrap_silver", count = 1 },
			{ id = "mc_crucible", count = 1}
			},
		yieldCount = 1,
		autocomplete = true,
		difficulty = 10,
		group = "Ingots",
		taskTime = 0
		},
		
		{id = "misc_com_metal_goblet_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 15,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "misc_com_metal_goblet_02",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 15,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "Misc_Com_Bucket_Metal",
		ingreds = {
			{id = "mc_iron_ingot", count = 4}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "misc_com_iron_ladle",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "T_Com_IronPot_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "T_Com_IronPot_02",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "T_Com_IronPot_03",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "mc_pot01",
		ingreds = {
			{id = "mc_iron_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "mc_cauldron01",
		ingreds = {
			{id = "mc_iron_ingot", count = 8},
			{id = "mc_log_scrap", count=6}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Kitchen",
		taskTime = 1
		},
		
		{id = "mc_cauldron02",
		ingreds = {
			{id = "mc_iron_ingot", count = 32}
		},
		yieldCount = 1,
		difficulty = 55,
		group = "Kitchen",
		taskTime = 3
		},

		{id = "mc_cauldron03",
		ingreds = {
			{id = "mc_iron_ingot", count = 44}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Kitchen",
		taskTime = 5
		},

		{id = "mc_cauldron04",
		ingreds = {
			{id = "mc_iron_ingot", count = 104}
		},
		yieldCount = 1,
		difficulty = 95,
		group = "Kitchen",
		taskTime = 8
		},

		{id = "mc_cauldron05",
		ingreds = {
			{id = "mc_iron_ingot", count = 32}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Kitchen",
		taskTime = 3
		},
		
		{id = "misc_com_metal_plate_03",
		ingreds = {
			{id = "mc_iron_ingot", count = 2},
			{id = "Gold_001", count = 1}
		},
		yieldCount = 4,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},
				
		{id = "misc_com_metal_plate_04",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 4,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "misc_com_metal_plate_05",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 4,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "misc_com_metal_plate_07",
		ingreds = {
			{id = "mc_iron_ingot", count = 2},
			{id = "Gold_001", count = 1}
		},
		yieldCount = 4,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "mc_saucepan",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_log_hickory", count = 1}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "mc_skillet",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_log_hickory", count = 1}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Kitchen",
		taskTime = 0
		},
		
		{id = "misc_com_tankard_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Kitchen",
		taskTime = 0
		},

		{id = "T_Imp_TankardNavy_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Kitchen",
		taskTime = 0
		},

		{id = "mc_candle_wire_black",
		alias = "Iron Stand Candle, Black",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_lichen_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 7,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_wire_blue",
		alias = "Iron Stand Candle, Blue",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_stoneflower_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 7,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_wire_green",
		alias = "Iron Stand Candle, Green",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bittergreen_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 7,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_wire_orange",
		alias = "Iron Stand Candle, Orange",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_kwama_cuttle_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 7,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_wire_purple",
		alias = "Iron Stand Candle, Purple",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_anther_01", count = 1}
		},
		yieldCount = 7,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_wire_red",
		alias = "Iron Stand Candle, Red",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_fire_petal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 7,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_wire_white",
		alias = "Iron Stand Candle, White",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bonemeal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 7,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_wire_yellow",
		alias = "Iron Stand Candle, Yellow",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_gold_kanet_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 7,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_black",
		alias = "Fancy Floor Lamp, Black",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_lichen_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_blue",
		alias = "Fancy Floor Lamp, Blue",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_stoneflower_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_green",
		alias = "Fancy Floor Lamp, Green",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bittergreen_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_orange",
		alias = "Fancy Floor Lamp, Orange",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_kwama_cuttle_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_purple",
		alias = "Fancy Floor Lamp, Purple",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_anther_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_red",
		alias = "Fancy Floor Lamp, Red",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_fire_petal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_white",
		alias = "Fancy Floor Lamp, White",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bonemeal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_fancy_yellow",
		alias = "Fancy Floor Lamp, Yellow",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_gold_kanet_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_black",
		alias = "Floor Candelabra, Black",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_black_lichen_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_blue",
		alias = "Floor Candelabra, Blue",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_stoneflower_petals_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_green",
		alias = "Floor Candelabra, Green",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_bittergreen_petals_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_orange",
		alias = "Floor Candelabra, Orange",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_kwama_cuttle_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_purple",
		alias = "Floor Candelabra, Purple",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_black_anther_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_red",
		alias = "Floor Candelabra, Red",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_fire_petal_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_white",
		alias = "Floor Candelabra, White",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_bonemeal_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_multi_yellow",
		alias = "Floor Candelabra, Yellow",
		ingreds = {
			{id = "mc_iron_ingot", count = 11},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_gold_kanet_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_black",
		alias = "Silver Candlestick, Black",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_lichen_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_blue",
		alias = "Silver Candlestick, Blue",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_stoneflower_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_green",
		alias = "Silver Candlestick, Green",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bittergreen_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_orange",
		alias = "Silver Candlestick, Orange",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_kwama_cuttle_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_purple",
		alias = "Silver Candlestick, Purple",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_anther_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_red",
		alias = "Silver Candlestick, Red",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_fire_petal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_white",
		alias = "Silver Candlestick, White",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bonemeal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_1sil_yellow",
		alias = "Silver Candlestick, Yellow",
		ingreds = {
			{id = "mc_silver_ingot", count = 3},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_gold_kanet_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_black",
		alias = "Silver Candlestick, Black",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_black_lichen_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_blue",
		alias = "Silver Candlestick, Blue",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_stoneflower_petals_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_green",
		alias = "Silver Candlestick, Green",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_bittergreen_petals_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_orange",
		alias = "Silver Candlestick, Orange",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_kwama_cuttle_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_purple",
		alias = "Silver Candlestick, Purple",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_black_anther_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_red",
		alias = "Silver Candlestick, Red",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_fire_petal_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_white",
		alias = "Silver Candlestick, White",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_bonemeal_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_candle_3sil_yellow",
		alias = "Silver Candlestick, Yellow",
		ingreds = {
			{id = "mc_silver_ingot", count = 4},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1},
			{id = "ingred_gold_kanet_01", count = 3}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_black",
		alias = "Simple Floor Lamp, Black",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_lichen_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_blue",
		alias = "Simple Floor Lamp, Blue",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_stoneflower_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_green",
		alias = "Simple Floor Lamp, Green",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bittergreen_petals_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_orange",
		alias = "Simple Floor Lamp, Orange",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_kwama_cuttle_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_purple",
		alias = "Simple Floor Lamp, Purple",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_black_anther_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_red",
		alias = "Simple Floor Lamp, Red",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_fire_petal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_white",
		alias = "Simple Floor Lamp, White",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_bonemeal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lamp_simple_yellow",
		alias = "Simple Floor Lamp, Yellow",
		ingreds = {
			{id = "mc_iron_ingot", count = 12},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1},
			{id = "ingred_gold_kanet_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_chandelier01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_log_ash", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Lighting",
		taskTime = 0
		},

		{id = "mc_chandelier02",
		ingreds = {
			{id = "mc_iron_ingot", count = 4},
			{id = "mc_tallow", count = 4},
			{id = "Thread", count = 1}
		},
		yieldCount = 1,
		difficulty = 60,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_sconce01",
		ingreds = {
			{id = "mc_iron_ingot", count = 3},
			{id = "mc_log_oak", count = 1}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_sconce02",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_log_oak", count = 1},
			{id = "mc_tallow", count = 2},
			{id = "Thread", count = 1}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_sconce03",
		ingreds = {
			{id = "mc_iron_ingot", count = 3},
			{id = "mc_log_oak", count = 1},
			{id = "mc_tallow", count = 6},
			{id = "Thread", count = 1}
		},
		yieldCount = 1,
		difficulty = 35,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_sconce04",
		ingreds = {
			{id = "mc_iron_ingot", count = 3},
			{id = "mc_log_oak", count = 1},
			--{id = "mc_lamp_oi1", count = 3},
			{id = "mc_fiber", count = 1}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_sconce05",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			--{id = "mc_lamp_oi1", count = 3},
			{id = "mc_fiber", count = 1}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_light_ring01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 15,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lantern_hook01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_log_ash", count = 1}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lantern_hook02",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 15,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_lantern_hook03",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_torchholder01",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Lighting",
		taskTime = 0
		},
		
		{id = "mc_torchholder02",
		ingreds = {
			{id = "mc_iron_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Lighting",
		taskTime = 0
		},

		{id = "T_Com_Var_TikiTorch_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 2},
			{id = "mc_log_ash", count = 2},
			{id = "mc_lamp_oil", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Lighting",
		taskTime = 1
		},
		
		{id = "mc_masonry_kit",
		ingreds = {
			{id = "mc_iron_ingot", count = 5},
			{id = "mc_log_oak", count = 1},
			{id = "ingred_guar_hide_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Miscellaneous",
		taskTime = 0
		},

		{id = "T_Dwe_ExplodoEye_01",
		ingreds = {
			{id = "mc_dwemer_ingot", count = 3},
			{id = "ingred_raw_glass_01", count = 1},
		},
		yieldCount = 4,
		difficulty = 70,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_Com_Saw_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 2},
			{id = "mc_log_hickory", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_De_Weight_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_De_Weight_02",
		ingreds = {
			{id = "mc_iron_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_De_Weight_03",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_De_Weight_04",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_De_Scales_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 7}
		},
		yieldCount = 1,
		difficulty = 75,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_De_Scales_02",
		Alias = "Scales, angled",
		ingreds = {
			{id = "mc_iron_ingot", count = 7}
		},
		yieldCount = 1,
		difficulty = 75,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "misc_shears_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_Com_EmbalmingScissor_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 2,
		difficulty = 30,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_Imp_SilverWeight_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 10}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_Imp_SilverWeight_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_Imp_SilverWeight_03",
		ingreds = {
			{id = "mc_silver_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_Imp_SilverWeight_04",
		ingreds = {
			{id = "mc_silver_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 10,
		group = "Miscellaneous",
		taskTime = 0
		},
		
		{id = "T_Imp_SilverScales_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 10}
		},
		yieldCount = 1,
		difficulty = 80,
		group = "Miscellaneous",
		taskTime = 0
		},

		{id = "T_Imp_SilverwareTankard_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 45,
		group = "Silverware",
		taskTime = 0
		},
		
		{id = "T_Imp_SilverScales_02",
		alias = "Silver scales (angled)",
		ingreds = {
			{id = "mc_silver_ingot", count = 10}
		},
		yieldCount = 1,
		difficulty = 80,
		group = "Miscellaneous",
		taskTime = 0
		},

		{id = "mc_spearholder01",
		ingreds = {
			{id = "mc_iron_ingot", count = 10}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Miscellaneous",
		taskTime = 2
		},

		{id = "mc_weaponrack01",
		ingreds = {
			{id = "mc_iron_ingot", count = 2},
			{id = "mc_log_pine", count = 2}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Miscellaneous",
		taskTime = 0.5
		},

		{id = "mc_anvil",
		ingreds = {
			{id = "mc_clay", count = 30},
			{id = "mc_sand", count = 100},
			{id = "mc_log_scrap", count = 45},
			{id = "mc_iron_ingot", count = 162},
			{id = "ingred_resin_01", count = 16}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Miscellaneous",
		taskTime = 24
		},
		
		{id = "pick_apprentice_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Security",
		taskTime = 0.25
		},
		
		{id = "pick_journeyman_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Security",
		taskTime = 0.5
		},
		
		{id = "pick_master",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 90,
		group = "Security",
		taskTime = 1
		},
		
		{id = "pick_grandmaster",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 110,
		group = "Security",
		taskTime = 2
		},
		
		{id = "pick_secretmaster",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 130,
		group = "Security",
		taskTime = 3
		},
		{id = "probe_apprentice_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Security",
		taskTime = 0.25
		},
		
		{id = "probe_journeyman_01",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Security",
		taskTime = 0.5
		},
		
		{id = "probe_master",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 90,
		group = "Security",
		taskTime = 1
		},
		
		{id = "probe_grandmaster",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 110,
		group = "Security",
		taskTime = 1.5
		},
		
		{id = "probe_secretmaster",
		ingreds = {
			{id = "mc_iron_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 130,
		group = "Security",
		taskTime = 3
		},
		
		{id = "misc_com_silverware_knife",
		ingreds = {
			{id = "mc_silver_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Silverware",
		taskTime = .25
		},
		
		{id = "T_Imp_SilverWareKnife_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Silverware",
		taskTime = 0.25
		},
		
		{id = "misc_com_silverware_fork",
		ingreds = {
			{id = "mc_silver_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Silverware",
		taskTime = 0.25
		},
		
		{id = "T_Imp_SilverWareFork_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Silverware",
		taskTime = 0.25
		},
		
		{id = "misc_com_silverware_spoon",
		ingreds = {
			{id = "mc_silver_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Silverware",
		taskTime = 0.25
		},
		
		{id = "T_Imp_SilverWareSpoon_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 1}
		},
		yieldCount = 1,
		difficulty = 20,
		group = "Silverware",
		taskTime = 0.25
		},
		
		{id = "T_Imp_SilverWareBottle_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Silverware",
		taskTime = 2
		},
		
		{id = "Misc_Imp_Silverware_Bowl",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Silverware",
		taskTime = 1.5
		},
		
		{id = "T_Nor_SilverBowl_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Silverware",
		taskTime = 1.5
		},
		
		{id = "T_Nor_SilverBowl_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Silverware",
		taskTime = 1.5
		},
		
		{id = "misc_imp_silverware_cup",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 35,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "Misc_Imp_Silverware_Cup_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 37,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWareCup_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 35,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWareCup_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 35,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWareCup_03",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 35,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWareDish_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWareDish_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 40,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Nor_SilverGoblet_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Silverware",
		taskTime = 2
		},
		
		{id = "misc_imp_silverware_pitcher",
		ingreds = {
			{id = "mc_silver_ingot", count = 7}
		},
		yieldCount = 1,
		difficulty = 55,
		group = "Silverware",
		taskTime = 3
		},
		
		{id = "misc_imp_silverware_plate_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "misc_imp_silverware_plate_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWarePlate_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWarePlate_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWarePlate_03",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWarePlate_04",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWarePlate_05",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWarePlate_06",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Nor_SilverPlate_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 3}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Nor_SilverPlate_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Nor_SilverPlate_03",
		ingreds = {
			{id = "mc_silver_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 30,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWarePot_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 2}
		},
		yieldCount = 1,
		difficulty = 25,
		group = "Silverware",
		taskTime = 1
		},
		
		{id = "T_Imp_SilverWareVase_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 7}
		},
		yieldCount = 1,
		difficulty = 60,
		group = "Silverware",
		taskTime = 3
		},
		
		{id = "T_Nor_SilverVase_01",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Silverware",
		taskTime = 3
		},
		
		{id = "T_Nor_SilverVase_02",
		ingreds = {
			{id = "mc_silver_ingot", count = 5}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Silverware",
		taskTime = 3
		},
		
		{id = "rrfm_silver_pitcher",
		ingreds = {
			{id = "mc_silver_ingot", count = 7}
		},
		yieldCount = 1,
		difficulty = 50,
		group = "Silverware",
		taskTime = 3
		},

		{id = "mc_jewelry_kit",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_sack12", count = 1}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Miscellaneous",
		taskTime = 6
		},

		{id = "mc_organic_kit",
		ingreds = {
			{id = "mc_iron_ingot", count = 3},
			{id = "ingred_guar_hide_01", count = 2},
			{id = "ingred_dreugh_wax_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 60,
		group = "Miscellaneous",
		taskTime = 4
		},

		{id = "mc_sewing_kit",
		ingreds = {
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_basket15", count = 1}
		},
		yieldCount = 1,
		difficulty = 65,
		group = "Miscellaneous",
		taskTime = 3
		},

		{id = "mc_smelter",
		ingreds = {
			{id = "apparatus_a_calcinator_01", count = 1},
			{id = "mc_dwemer_ingot", count = 1},
			{id = "mc_iron_ingot", count = 1},
			{id = "mc_crucible", count = 1}
		},
		yieldCount = 1,
		difficulty = 80,
		group = "Miscellaneous",
		taskTime = 6
		},

		{id = "mc_carpentry_kit",
		ingreds = {
			{id = "mc_iron_ingot", count = 4},
			{id = "mc_log_oak", count = 2},
			{id = "mc_chest02", count = 1},
			{id = "ingred_boar_leather", count = 4}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Miscellaneous",
		taskTime = 4
		},

		{id = "mc_crafting_kit",
		ingreds = {
			{id = "mc_iron_ingot", count = 4},
			{id = "ingred_boar_leather", count = 2},
			{id = "mc_prepared_cloth", count = 6},
			{id = "ingred_kagouti_hide_01", count = 2}
		},
		yieldCount = 1,
		difficulty = 75,
		group = "Miscellaneous",
		taskTime = 4
		},

		{id = "mc_potterywheel02",
		ingreds = {
			{ id = "mc_log_scrap", count = 7 },
			{ id = "mc_iron_ingot", count = 7 }
			},
		yieldCount = 1,
		difficulty = 85,
		class = "Tools",
		group = "Scrapwood",
		taskTime = 7
		},

	}
	return makerlist