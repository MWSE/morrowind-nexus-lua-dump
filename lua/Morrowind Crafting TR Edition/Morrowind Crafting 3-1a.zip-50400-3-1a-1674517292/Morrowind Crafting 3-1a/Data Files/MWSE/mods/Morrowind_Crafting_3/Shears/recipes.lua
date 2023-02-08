--[[ Shears - convertring cloth & bolts to cloth ready for sewing --
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		-- Group
			
	local makerlist = {}
	makerlist = {
		{id = "misc_de_cloth10",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "misc_de_cloth11",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "misc_de_foldedcloth00",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothPlain_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothPlain_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothPlainFolded_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothBrown_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothBrownFolded_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothGreen_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothGreenFolded_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothPurple_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothPurpleFolded_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothRed_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothRedFolded_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothYellow_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
		
		{id = "T_Com_ClothYellowFolded_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		taskTime = 0
		},
			
		{id = "misc_clothbolt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "misc_clothbolt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "misc_clothbolt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Clothbolt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Clothbolt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Clothbolt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Nor_Clothbolt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Nor_Clothbolt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Nor_Clothbolt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Silkbolt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Silkbolt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Silkbolt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Silkbolt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "T_Imp_Silkbolt_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 40,
		taskTime = 0
		},
		
		{id = "common_pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_pants_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_pants_03_b",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_pants_03_c",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_pants_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_pants_04_b",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_pants_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Pants_08",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColWest_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 6}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColNorth_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColNorth_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColNorth_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Pants_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Pants_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Pants_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColWest_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Com_Cm_Pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Pants_07",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColWest_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_PantsColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Pants_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_pants_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "Expensive_pants_Mournhold",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "exquisite_pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "extravagant_pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "extravagant_pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_flawless_pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_Pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "common_robe_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_02_h",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_02_r",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_02_rr",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_02_t",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_02_tt",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_03_a",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_03_b",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_05_a",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_05_b",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_05_c",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "common_robe_EOT",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},

		{id = "mc_common_robe_unique",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Robe_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Dress_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Robe_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "expensive_robe_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "expensive_robe_02_a",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "expensive_robe_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "exquisite_robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 5,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_01_a",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_01_b",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_01_c",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_01_h",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_01_r",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_01_t",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "extravagant_robe_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "Helseth's Robe",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 5,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "mc_flawless_robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 5,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Cm_Robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "T_De_Cm_Robe_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_Robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_RobeNecromPriest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 4,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ex_Robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 5,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ex_RobeNecrom_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 5,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_02_h",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_02_hh",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_02_r",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_02_rr",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_02_t",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_02_tt",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_03_c",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_04_a",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_04_b",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_04_c",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_shirt_gondolier",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 6,
		byProduct = {
			{id = "mc_clothscraps", yield = 9}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_ShirtColWest_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_ShirtColWest_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Nor_Cm_Shirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_ShirtInd_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_ShirtInd_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_ShirtColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Com_Cm_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Cm_ShirtColWest_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_shirt_01_e",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "Expensive_shirt_Mournhold",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "exquisite_shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "extravagant_shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "extravagant_shirt_01_r",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "extravagant_shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "mc_flawless_shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_ShirtDres_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_ShirtInd_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_ShirtInd_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "common_skirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_skirt_04_c",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_skirt_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "common_skirt_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_skirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_skirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "expensive_skirt_Mournhold",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "exquisite_skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "extravagant_skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "extravagant_skirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "mc_flawless_skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Cm_Skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Cm_SkirtInd_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Cm_SkirtInd_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Com_Ep_Skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Cm_SkirtInd_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Cm_SkirtInd_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ep_SkirtDresWarrior_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ep_SkirtHlaWarrior_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ep_SkirtIndWarrior_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ep_SkirtRedWarrior_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ep_SkirtTelvWarrior_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_SkirtRedHero_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 9,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_SkirtRedHero_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 9,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ex_SkirtNecrom_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 6,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_ShirtColWest_08",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_ShirtColWest_07",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_ShirtColWest_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_ShirtColWest_09",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_ShirtColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_07",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtLegion_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_09",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_08",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtLegion_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtLegion_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Cm_SkirtColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Ep_Pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Ep_PantsColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Ep_PantsColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Ep_Pants_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Rga_Ep_Pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Ep_Pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
				
		{id = "T_Com_Ep_Robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
				
		{id = "T_Nor_Ep_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Ep_Shirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ep_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ep_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ep_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ep_Skirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ep_Skirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ep_Skirt_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ep_Skirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Et_Pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Et_Pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},		
		
		{id = "T_Rga_Et_Robe_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Et_Dress_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "robe_lich_unique",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Et_Dress_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Com_Et_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Et_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Et_ShirtColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Et_ShirtColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Et_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Et_Skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_De_Ep_SkirtNecromOrdinat_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 6,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},		
		
		{id = "T_Com_Et_Skirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ex_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ex_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ex_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ex_Skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ex_Skirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Ex_Skirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 3,
		byProduct = {
			{id = "mc_clothscraps", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "mc_shalk_shell",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 20,
		taskTime = 0
		},
		
		{id = "T_IngCrea_BeetleShell_01",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 2,
		taskTime = 0
		},
		
		{id = "T_IngCrea_BeetleShell_02",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 2,
		taskTime = 0
		},
		
		{id = "T_IngCrea_BeetleShell_03",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 2,
		taskTime = 0
		},
		
		{id = "T_IngCrea_BeetleShell_04",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 2,
		taskTime = 0
		},
		
		{id = "T_IngCrea_CephalopodShell_01",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 8,
		taskTime = 0
		},
		
		{id = "T_IngCrea_ShellMolecrab_01",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 4,
		taskTime = 0
		},
		
		{id = "T_IngCrea_ShellMolecrab_02",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 4,
		taskTime = 0
		},
		
		{id = "T_IngCrea_ShellParastylus_01",
		qtyReq = 1,
		yieldID = "mc_chitin_strips",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Belt_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Belt_04",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "common_belt_03",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Belt_03",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Belt_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "common_shoes_07",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "T_De_Cm_Shoes_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "expensive_belt_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Com_Ep_GloveL_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Com_Ep_GloveR_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "expensive_glove_left_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "expensive_glove_right_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Com_Ep_GloveL_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Com_Ep_GloveR_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "expensive_shoes_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "T_De_Ep_Shoes_04",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "extravagant_belt_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Com_Et_GloveL_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Com_Et_GloveR_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "extravagant_glove_left_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "extravagant_glove_right_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "mc_Exq_GloveL_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "mc_Exq_GloveR_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_De_Et_Shoes_03",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "T_De_Et_Shoes_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "extravagant_shoes_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "T_De_Et_Shoes_05",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "T_De_Et_Shoes_04",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "T_De_Et_Shoes_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "T_Nor_Ex_Belt_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},

		{id = "exquisite_belt_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_De_Ex_Shoes_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 6,
		taskTime = 0
		},
		
		{id = "mc_flawless_belt_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "mc_flawless_belt_02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "mc_flawless_belt_03",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 13,
		taskTime = 0
		},
		
		{id = "misc_uni_pillow_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 1},
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "Misc_Uni_Pillow_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 1},
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_sack02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_PillowWool_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 1,
		byProduct = {
			{id = "mc_straw", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "mc_sack01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "mc_sack04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "mc_bedroll",
		alias = "Portable Bedding",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 12,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_rcushion01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_rcushion02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_rcushion03",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_rcushion04",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_rcushion05",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_rcushion06",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_rcushion07",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_PillowSatinBlack_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_practicemat",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 7,
		byProduct = {
			{id = "mc_clothscraps", yield = 12},
			{id = "mc_straw", yield = 7}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion02",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion03",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion04",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion05",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion06",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion07",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion08",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_scushion09",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		byProduct = {
			{id = "mc_straw", yield = 2}
		},
		taskTime = 0
		},
		
		{id = "mc_sack03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_PillowVelvetRed_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 4,
		byProduct = {
			{id = "mc_straw", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "Misc_Uni_Pillow_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 1,
		byProduct = {
			{id = "mc_straw", yield = 1}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},
		
		{id = "T_Nor_Ep_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Ep_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Cm_Shirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Com_Cm_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Ep_ShirtColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Ep_ShirtColWest_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Ep_ShirtColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Ep_ShirtColWest_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Imp_Ep_ShirtColWest_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Cm_Pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Et_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "T_Nor_Et_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		
		{id = "mc_bale01",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},

		{id = "mc_sack05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "mc_sack06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
		{id = "mc_sack07",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "mc_sack08",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "mc_sack09",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "mc_sack10",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "mc_sack11",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "mc_tent04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 45,
		byProduct = {
			{id = "mc_clothscraps", yield = 23}
		},
		taskTime = 0
		},

		{id = "mc_sack12",
		qtyReq = 1,
		yieldID = "mc_clothscraps",
		yieldCount = 3,
		taskTime = 0
		},

		{id = "T_De_Cm_Pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Pants_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Pants_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Pants_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Pants_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Pants_10",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Robe_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 2,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Shirt_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Shirt_12",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Shirt_13",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Shirt_15",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Shirt_16",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_Shirt_17",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_ShirtDres_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_ShirtDres_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_ShirtDres_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_ShirtInd_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_skirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_skirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_skirt_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Cm_skirt_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ep_Pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ep_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ep_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ep_Shirt_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ep_Shirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ep_Shirt_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Shirt_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Shirt_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Shirt_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Shirt_07",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Shirt_08",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Shirt_09",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Shirt_10",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_ShirtDres_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_ShirtDres_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Et_Skirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ex_Pants_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ex_Pants_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ex_Shirt_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_De_Ex_Shirt_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_PantsColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_PantsColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_PantsColWest_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_ShirtColWest_03",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_ShirtColWest_04",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_ShirtColWest_05",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_ShirtColWest_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_SkirtColWest_01",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Imp_Et_SkirtColWest_02",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},

		{id = "T_Rea_Cm_Shirt_06",
		qtyReq = 1,
		yieldID = "mc_prepared_cloth",
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 3}
		},
		taskTime = 0
		},
	}

return makerlist
