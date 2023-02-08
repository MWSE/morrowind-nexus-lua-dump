--[[ Sewing-group listing --
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		
	-- Class = Common, Expensive, Extravagant, Exquisite, Flawless, Misc
	-- Group = Cloth, Alit, Bear, Bristleback, Guar, Kagouti, Netch, Scamp, Wolf
	-- Location = Pants, Shoes, Shirt, Belt, Robe, Gloves, Skirt, Pillows, Other
		
	local makerlist = {}
	makerlist = {
		{id = "T_Nor_Cm_Belt_02",
		alias = "Blue & Gold Rippled Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false }
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Common",
		group = "Cloth",
		location = "Belt",
		taskTime = 0.5
		},
		
		{id = "T_Nor_Cm_Belt_04",
		alias = "Double Braided Tan Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Common",
		group = "Cloth",
		location = "Belt",
		taskTime = 0.5
		},
		
		{id = "common_belt_03",
		alias = "Light Cloth Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Common",
		group = "Cloth",
		location = "Belt",
		taskTime = 0.5
		},
		
		{id = "T_Nor_Cm_Belt_03",
		alias = "Studded Beige Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Common",
		group = "Cloth",
		location = "Belt",
		taskTime = 0.5
		},
		
		{id = "T_Nor_Cm_Belt_01",
		alias = "Woven Beige Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Common",
		group = "Cloth",
		location = "Belt",
		taskTime = 0.5
		},
		
		{id = "common_shoes_07",
		alias = "Cheap Burlap Shoes",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shoes",
		taskTime = 0.5
		},
		
		{id = "T_De_Cm_Shoes_01",
		alias = "Laced Slippers",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shoes",
		taskTime = 0.5
		},
		
		{id = "expensive_belt_01",
		alias = "Wide Brown Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		byProduct = {
			{id = "mc_clothscraps", yield = 4}
		},
		difficulty = 30,
		class = "Expensive",
		group = "Cloth",
		location = "Belt",
		taskTime = 0.75
		},
		
		{id = "T_Com_Ep_GloveL_01",
		alias = "Black Left Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 45,
		class = "Expensive",
		group = "Cloth",
		location = "Gloves",
		taskTime = 1.25
		},
		
		{id = "T_Com_Ep_GloveR_01",
		alias = "Black Right Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 45,
		class = "Expensive",
		group = "Cloth",
		location = "Gloves",
		taskTime = 1.25
		},
		
		{id = "expensive_glove_left_01",
		alias = "Blue/Silver Left Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 45,
		class = "Expensive",
		group = "Cloth",
		location = "Gloves",
		taskTime = 1.25
		},
		
		{id = "expensive_glove_right_01",
		alias = "Blue/Silver Right Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 45,
		class = "Expensive",
		group = "Cloth",
		location = "Gloves",
		taskTime = 1.25
		},
		
		{id = "T_Com_Ep_GloveL_02",
		alias = "Green/Gold Left Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 45,
		class = "Expensive",
		group = "Cloth",
		location = "Gloves",
		taskTime = 1.25
		},
		
		{id = "T_Com_Ep_GloveR_02",
		alias = "Green/Gold Right Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 45,
		class = "Expensive",
		group = "Cloth",
		location = "Gloves",
		taskTime = 1.25
		},
		
		{id = "expensive_pants_02",
		alias = "Fancy Blue Breeches",
		ingreds = {
			{id = "mc_prepared_cloth", count = 10},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Cloth",
		location = "Pants",
		taskTime = 1
		},
		
		{id = "expensive_shoes_02",
		alias = "Gold Slippers",
		ingreds = {
			{id = "mc_prepared_cloth", count = 7},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Cloth",
		location = "Shoes",
		taskTime = 1
		},
		
		{id = "T_De_Ep_Shoes_04",
		alias = "Wine Gondola Shoes",
		ingreds = {
			{id = "mc_prepared_cloth", count = 7},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Cloth",
		location = "Shoes",
		taskTime = 1
		},
		
		{id = "extravagant_belt_01",
		alias = "Gold Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Belt",
		taskTime = 1.5
		},
		
		{id = "T_Com_Et_GloveL_02",
		alias = "Blue and Gold Left Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 65,
		class = "Extravagant",
		group = "Cloth",
		location = "Gloves",
		taskTime = 2
		},
		
		{id = "T_Com_Et_GloveR_02",
		alias = "Blue and Gold Right Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 65,
		class = "Extravagant",
		group = "Cloth",
		location = "Gloves",
		taskTime = 2
		},
		
		{id = "extravagant_glove_left_01",
		alias = "Purple and Gold Left Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 65,
		class = "Extravagant",
		group = "Cloth",
		location = "Gloves",
		taskTime = 2
		},
		
		{id = "extravagant_glove_right_01",
		alias = "Purple and Gold Right Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 85,
		class = "Extravagant",
		group = "Cloth",
		location = "Gloves",
		taskTime = 2
		},
		
		{id = "mc_Exq_GloveL_01",
		alias = "Gold and Burgundy Left Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 32},
			{id = "ingred_ash_salts_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 85,
		class = "Exquisite",
		group = "Cloth",
		location = "Gloves",
		taskTime = 2
		},
		
		{id = "mc_Exq_GloveR_01",
		alias = "Gold and Burgundy Right Glove",
		ingreds = {
			{id = "mc_prepared_cloth", count = 32},
			{id = "ingred_ash_salts_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 85,
		class = "Exquisite",
		group = "Cloth",
		location = "Gloves",
		taskTime = 2
		},
		
		{id = "T_De_Et_Shoes_03",
		alias = "Black and White Gondola Shoes",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shoes",
		taskTime = 2.5
		},
		
		{id = "T_De_Et_Shoes_01",
		alias = "Burgundy Gondola Shoes",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shoes",
		taskTime = 2
		},
		
		{id = "extravagant_shoes_01",
		alias = "Cloth Slippers",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shoes",
		taskTime = 2
		},
		
		{id = "T_De_Et_Shoes_05",
		alias = "Gold Pattern Shoes",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shoes",
		taskTime = 2
		},
		
		{id = "T_De_Et_Shoes_04",
		alias = "Ted and Tan Shoes",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shoes",
		taskTime = 2
		},
		
		{id = "T_De_Et_Shoes_02",
		alias = "Red Shoes w/ Blue Chevrons",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shoes",
		taskTime = 2
		},
		
		{id = "T_Nor_Ex_Belt_02",
		alias = "Blue and Gold Embroidered Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 28},
			{id = "ingred_ash_salts_01", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 70,
		class = "Exquisite",
		group = "Cloth",
		location = "Belt",
		taskTime = 3
		},

		{id = "exquisite_belt_01",
		alias = "Bright Blue Belt",
		ingreds = {
			{id = "mc_prepared_cloth", count = 28},
			{id = "ingred_ash_salts_01", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 70,
		class = "Exquisite",
		group = "Cloth",
		location = "Belt",
		taskTime = 3
		},
		
		{id = "T_De_Ex_Shoes_01",
		alias = "Red and Gold Longtoes",
		ingreds = {
			{id = "mc_prepared_cloth", count = 26},
			{id = "ingred_ash_salts_01", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 80,
		class = "Exquisite",
		group = "Cloth",
		location = "Shoes",
		taskTime = 6
		},
		
		{id = "mc_flawless_belt_01",
		alias = "Flawless Belt #1",
		ingreds = {
			{id = "mc_prepared_cloth", count = 92},
			{id = "ingred_void_salts_01", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 90,
		class = "Flawless",
		group = "Cloth",
		location = "Belt",
		taskTime = 6
		},
		
		{id = "mc_flawless_belt_02",
		alias = "Flawless Belt #2",
		ingreds = {
			{id = "mc_prepared_cloth", count = 92},
			{id = "ingred_void_salts_01", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 90,
		class = "Flawless",
		group = "Cloth",
		location = "Belt",
		taskTime = 0.6
		},
		
		{id = "mc_flawless_belt_03",
		alias = "Flawless Belt #3",
		ingreds = {
			{id = "mc_prepared_cloth", count = 92},
			{id = "ingred_void_salts_01", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 90,
		class = "Flawless",
		group = "Cloth",
		location = "Belt",
		taskTime = 6
		},
		
		{id = "mc_padding",
		alias = "Armor Padding (from cloth)",
		ingreds = {
			{id = "mc_prepared_cloth", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.2
		},
		
		{id = "Misc_Uni_Pillow_02",
		alias = "Brown Pillow",
		ingreds = {
			{id = "mc_prepared_cloth", count = 1},
			{id = "mc_straw", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.25
		},
		
		{id = "mc_sack02",
		alias = "Cloth Bag",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.25
		},
		
		{id = "T_Nor_PillowWool_01",
		alias = "Faux Woolen Pillow",
		ingreds = {
			{id = "mc_prepared_cloth", count = 1},
			{id = "mc_straw", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.25
		},
		
		{id = "mc_sack01",
		alias = "Flat Burlap Sack",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.25
		},
		
		{id = "mc_sack04",
		alias = "Flat Canvas Sack",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.25
		},
		
		{id = "mc_bedroll",
		alias = "Portable Bedding",
		ingreds = {
			{id = "mc_prepared_cloth", count = 8},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 1
		},
		
		{id = "mc_rcushion01",
		alias = "Round Cushion #1",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_rcushion02",
		alias = "Round Cushion #2",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_rcushion03",
		alias = "Round Cushion #3",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_rcushion04",
		alias = "Round Cushion #4",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_rcushion05",
		alias = "Round Cushion #5",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_rcushion06",
		alias = "Round Cushion #6",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_rcushion07",
		alias = "Round Cushion #7",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 15,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "T_Imp_PillowSatinBlack_01",
		alias = "Satin Pillow",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "ingred_ash_salts_01", count = 1},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 35,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_practicemat",
		alias = "Sparring Mat",
		ingreds = {
			{id = "mc_prepared_cloth", count = 15},
			{id = "mc_straw", count = 15},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 30,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},
		
		{id = "mc_scushion01",
		alias = "Square Cushion #1",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion02",
		alias = "Square Cushion #2",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion03",
		alias = "Square Cushion #3",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion04",
		alias = "Square Cushion #4",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion05",
		alias = "Square Cushion #5",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion06",
		alias = "Square Cushion #6",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion07",
		alias = "Square Cushion #7",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion08",
		alias = "Square Cushion #8",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_scushion09",
		alias = "Square Cushion #9",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "mc_straw", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "mc_sack03",
		alias = "Standing Burlap Sack",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.25
		},
		
		{id = "T_Imp_PillowVelvetRed_01",
		alias = "Velvet Pillow",
		ingreds = {
			{id = "mc_prepared_cloth", count = 3},
			{id = "ingred_holly_01", count = 1 },
			{id = "mc_straw", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 25,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "Misc_Uni_Pillow_01",
		alias = "White Pillow",
		ingreds = {
			{id = "mc_prepared_cloth", count = 1},
			{id = "mc_straw", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Pillows",
		taskTime = 0.5
		},
		
		{id = "T_Nor_Cm_Shirt_01",
		alias = "Brown Shirt w/ Bearskin Vest",
		ingreds = {
			{id = "ingred_bear_pelt", count = 1},
			{id = "mc_prepared_cloth", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Bear",
		location = "Shirt",
		taskTime = 0.5
		},
		
		{id = "T_Nor_Ep_Shirt_01",
		alias = "Belted Brown Bear Tunic",
		ingreds = {
			{id = "ingred_bear_pelt", count = 2},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Bear",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Nor_Ep_Shirt_02",
		alias = "Tan Shirt w/ Light Bear Tunic",
		ingreds = {
			{id = "ingred_bear_pelt", count = 2},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Bear",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Com_Cm_Shirt_04",
		alias = "Blue Shirt w/ Bristleback Vest",
		ingreds = {
			{id = "ingred_boar_leather", count = 1},
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Com_Cm_Shirt_03",
		alias = "Tan Shirt w/ Bristleback Vest",
		ingreds = {
			{id = "ingred_boar_leather", count = 1},
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Imp_Ep_ShirtColWest_02",
		alias = "Grey Shirt w/ Bristleback Vest",
		ingreds = {
			{id = "ingred_boar_leather", count = 2},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Imp_Ep_ShirtColWest_03",
		alias = "Tan and Blue Shirt w/ Bristleback Vest",
		ingreds = {
			{id = "ingred_boar_leather", count = 2},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Imp_Ep_ShirtColWest_01",
		alias = "Tan and Burgundy Shirt w/ Bristleback Vest",
		ingreds = {
			{id = "ingred_boar_leather", count = 2},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Imp_Ep_ShirtColWest_04",
		alias = "Green Shirt w/ Guar Jerkin",
		ingreds = {
			{id = "ingred_guar_hide_01", count = 1},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Guar",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Imp_Ep_ShirtColWest_05",
		alias = "Red Shirt w/ Guar Jerkin",
		ingreds = {
			{id = "ingred_guar_hide_01", count = 1},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Guar",
		location = "Shirt",
		taskTime = 1
		},
		
		{id = "T_Nor_Cm_Pants_01",
		alias = "Speckled Grey Pants w/ Wolf Fringe",
		ingreds = {
			{id = "ingred_wolf_pelt", count = 1},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Wolf",
		location = "Pants",
		taskTime = 0.5
		},
		
		{id = "T_Nor_Cm_Pants_02",
		alias = "Spiral Grey Pants w/ Wolf Fringe",
		ingreds = {
			{id = "ingred_wolf_pelt", count = 1},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Wolf",
		location = "Pants",
		taskTime = 0.5
		},
		
		{id = "T_Nor_Et_Shirt_02",
		alias = "Brown and Burgundy Shirt w/ Wolf Trim",
		ingreds = {
			{id = "ingred_wolf_pelt", count = 3},
			{id = "mc_prepared_cloth", count = 10},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Wolf",
		location = "Shirt",
		taskTime = 3
		},
		
		{id = "T_Nor_Et_Shirt_01",
		alias = "Grey and Green Shirt w/ Wolf Trim",
		ingreds = {
			{id = "ingred_wolf_pelt", count = 3},
			{id = "mc_prepared_cloth", count = 10},
			{id = "ingred_holly_01", count = 1 },
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Wolf",
		location = "Shirt",
		taskTime = 3
		},
		
		{id = "mc_bale01",
		alias = "Crude bundle (Bale)",
		ingreds = {
			{id = "ingred_alit_hide_01", count = 1},
			{id = "mc_prepared_cloth", count = 1},
			{id = "mc_rope", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Misc",
		group = "Alit",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_sack05",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 5,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_sack06",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 7,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_sack07",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 7,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_sack08",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 7,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_sack09",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 7,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_sack10",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 7,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_sack11",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 7,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 0.5
		},

		{id = "mc_tent04",
		ingreds = {
			{id = "mc_prepared_cloth", count = 60},
			{id = "mc_log_pine", count = 24},
			{id = "misc_spool_01", count = 3}
		
		},
		yieldCount = 1,
		difficulty = 50,
		class = "Misc",
		group = "Cloth",
		location = "Other",
		taskTime = 4
		},

		{id = "mc_sack12",
		ingreds = {
			{id = "mc_prepared_cloth", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 10,
		class = "Containers",
		group = "Cloth",
		location = "Other",
		taskTime = 1
		},

		{id = "T_De_Cm_Pants_02",
		ingreds = {
			{id = "ingred_guar_hide_01", count = 3},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Guar",
		location = "Pants",
		taskTime = 1
		},

		{id = "T_De_Cm_Pants_03",
		ingreds = {
			{id = "ingred_guar_hide_01", count = 3},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Guar",
		location = "Pants",
		taskTime = 1
		},

		{id = "T_De_Cm_Pants_04",
		ingreds = {
			{id = "ingred_wolf_pelt", count = 3},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Wolf",
		location = "Pants",
		taskTime = 1
		},

		{id = "T_De_Cm_Pants_05",
		ingreds = {
			{id = "ingred_guar_hide_01", count = 3},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Guar",
		location = "Pants",
		taskTime = 1
		},

		{id = "T_De_Cm_Pants_06",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "gold_001", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Pants",
		taskTime = 1
		},

		{id = "T_De_Cm_Pants_10",
		ingreds = {
			{id = "ingred_kagouti_hide_01", count = 4},
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Kagouti",
		location = "Pants",
		taskTime = 1
		},

		{id = "T_De_Cm_Robe_06",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 30,
		class = "Common",
		group = "Cloth",
		location = "Pants",
		taskTime = 1
		},

		{id = "T_De_Cm_Shirt_03",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "ingred_netch_leather_01", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Netch",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_Shirt_06",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_Shirt_12",
		ingreds = {
			{id = "ingred_netch_leather_01", count = 2},
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Netch",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_Shirt_13",
		ingreds = {
			{id = "ingred_netch_leather_01", count = 2},
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Netch",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_Shirt_15",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_Shirt_16",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_Shirt_17",
		ingreds = {
			{id = "mc_prepared_cloth", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_ShirtDres_01",
		ingreds = {
			{id = "ingred_netch_leather_01", count = 2},
			{id = "mc_prepared_cloth", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Netch",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_ShirtDres_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 3},
			{id = "mc_iron_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_ShirtDres_03",
		ingreds = {
			{id = "mc_prepared_cloth", count = 2},
			{id = "ingred_kagouti_hide_01", count = 2},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Kagouti",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_ShirtInd_03",
		ingreds = {
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Shirt",
		taskTime = 1
		},

		{id = "T_De_Cm_skirt_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Skirt",
		taskTime = 1
		},

		{id = "T_De_Cm_skirt_04",
		ingreds = {
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Skirt",
		taskTime = 1
		},

		{id = "T_De_Cm_skirt_05",
		ingreds = {
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Skirt",
		taskTime = 1
		},

		{id = "T_De_Cm_skirt_06",
		ingreds = {
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Cloth",
		location = "Skirt",
		taskTime = 1
		},

		{id = "T_De_Ep_Pants_01",
		ingreds = {
			{id = "mc_prepared_cloth", count = 10},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Cloth",
		location = "Pants",
		taskTime = 2
		},

		{id = "T_De_Ep_Shirt_01",
		ingreds = {
			{id = "mc_prepared_cloth", count = 9},
			{id = "mc_iron_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Cloth",
		location = "Shirt",
		taskTime = 2
		},

		{id = "T_De_Ep_Shirt_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 9},
			{id = "mc_iron_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Cloth",
		location = "Shirt",
		taskTime = 2
		},

		{id = "T_De_Ep_Shirt_03",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "ingred_netch_leather_01", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Netch",
		location = "Shirt",
		taskTime = 2
		},

		{id = "T_De_Ep_Shirt_04",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "ingred_boar_leather", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 2
		},

		{id = "T_De_Ep_Shirt_05",
		ingreds = {
			{id = "mc_prepared_cloth", count = 5},
			{id = "ingred_wolf_pelt", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 40,
		class = "Expensive",
		group = "Wolf",
		location = "Shirt",
		taskTime = 2
		},

		{id = "T_De_Et_Shirt_04",
		ingreds = {
			{id = "mc_prepared_cloth", count = 18},
			{id = "ingred_kagouti_hide_01", count = 7},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_Shirt_05",
		ingreds = {
			{id = "mc_prepared_cloth", count = 25},
			{id = "gold_001", count = 6},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_Shirt_06",
		ingreds = {
			{id = "mc_prepared_cloth", count = 23},
			{id = "mc_iron_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_Shirt_07",
		ingreds = {
			{id = "mc_prepared_cloth", count = 25},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_Shirt_08",
		ingreds = {
			{id = "mc_prepared_cloth", count = 25},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_Shirt_09",
		ingreds = {
			{id = "mc_prepared_cloth", count = 23},
			{id = "mc_iron_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_Shirt_10",
		ingreds = {
			{id = "mc_prepared_cloth", count = 25},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_ShirtDres_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 20},
			{id = "ingred_boar_leather", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_ShirtDres_03",
		ingreds = {
			{id = "mc_prepared_cloth", count = 25},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Et_Skirt_01",
		ingreds = {
			{id = "mc_prepared_cloth", count = 18},
			{id = "ingred_netch_leather_01", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Netch",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Ex_Pants_01",
		ingreds = {
			{id = "mc_prepared_cloth", count = 53},
			{id = "gold_001", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 70,
		class = "Exquisite",
		group = "Cloth",
		location = "Pants",
		taskTime = 3
		},

		{id = "T_De_Ex_Pants_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 53},
			{id = "mc_silver_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 70,
		class = "Exquisite",
		group = "Cloth",
		location = "Pants",
		taskTime = 5
		},

		{id = "T_De_Ex_Shirt_01",
		ingreds = {
			{id = "mc_prepared_cloth", count = 33},
			{id = "gold_001", count = 6},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 70,
		class = "Exquisite",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_De_Ex_Shirt_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 33},
			{id = "gold_001", count = 4},
			{id = "mc_silver_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 70,
		class = "Exquisite",
		group = "Cloth",
		location = "Shirt",
		taskTime = 5
		},

		{id = "T_Imp_Et_PantsColWest_01",
		ingreds = {
			{id = "mc_prepared_cloth", count = 14},
			{id = "ingred_boar_leather", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Bristleback",
		location = "Pants",
		taskTime = 3
		},

		{id = "T_Imp_Et_PantsColWest_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 13},
			{id = "ingred_boar_leather", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Bristleback",
		location = "Pants",
		taskTime = 3
		},

		{id = "T_Imp_Et_PantsColWest_03",
		ingreds = {
			{id = "mc_prepared_cloth", count = 15},
			{id = "ingred_boar_leather", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Bristleback",
		location = "Pants",
		taskTime = 3
		},

		{id = "T_Imp_Et_ShirtColWest_03",
		ingreds = {
			{id = "mc_prepared_cloth", count = 15},
			{id = "ingred_boar_leather", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_Imp_Et_ShirtColWest_04",
		ingreds = {
			{id = "mc_prepared_cloth", count = 16},
			{id = "ingred_boar_leather", count = 4},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Bristleback",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_Imp_Et_ShirtColWest_05",
		ingreds = {
			{id = "mc_prepared_cloth", count = 25},
			{id = "mc_silver_ingot", count = 1},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_Imp_Et_ShirtColWest_06",
		ingreds = {
			{id = "mc_prepared_cloth", count = 22},
			{id = "gold_001", count = 5},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Shirt",
		taskTime = 3
		},

		{id = "T_Imp_Et_SkirtColWest_01",
		ingreds = {
			{id = "mc_prepared_cloth", count = 14},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Skirt",
		taskTime = 3
		},

		{id = "T_Imp_Et_SkirtColWest_02",
		ingreds = {
			{id = "mc_prepared_cloth", count = 13},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 60,
		class = "Extravagant",
		group = "Cloth",
		location = "Skirt",
		taskTime = 3
		},

		{id = "T_Rea_Cm_Shirt_06",
		ingreds = {
			{id = "ingred_bear_pelt", count = 1},
			{id = "mc_prepared_cloth", count = 3},
			{id = "misc_spool_01", count = 1, consumed = false}
		},
		yieldCount = 1,
		difficulty = 20,
		class = "Common",
		group = "Bear",
		location = "Shirt",
		taskTime = 1
		},
	}

return makerlist