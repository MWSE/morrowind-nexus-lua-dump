--[[ Brewingusing the standard kegstand listing
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		
		-- Kegstand misc = mc_kegstand
	
	local makerlist = {}
	makerlist = {
		{id = "mc_kegstand_p_brandy",
		product = "potion_cyro_brandy_01",
		alias = "Cyrodilic Brandy",
		ingreds = {
			{id = "ingred_void_salts_01", count = 4},
			{id = "ingred_comberry_01", count = 10},
			{id = "ingred_wickwheat_01", count = 10},
			{id = "mc_ryeflour", count = 5},
			{id = "ingred_coprinus_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 110,
		group = "Liquor",
		taskTime = 4
		},
		
		{id = "mc_kegstand_p_flin",
		product = "Potion_Cyro_Whiskey_01",
		alias = "Flin",
		ingreds = {
			{id = "ingred_dreugh_wax_01", count = 4},
			{id = "ingred_wickwheat_01", count = 10},
			{id = "mc_riceflour", count = 5},
			{id = "ingred_comberry_01", count = 10},
			{id = "ingred_coprinus_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 110,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_greef",
		product = "potion_comberry_brandy_01",
		alias = "Greef",
		ingreds = {
			{id = "potion_comberry_wine_01", count = 6},
			{id = "mc_sugar", count = 2},
			{id = "ingred_fire_petal_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 80,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_mazte",
		product = "Potion_Local_Brew_01",
		alias = "Mazte",
		ingreds = {
			{id = "ingred_wickwheat_01", count = 15},
			{id = "mc_sugar", count = 4},
			{id = "ingred_meadow_rye_01", count = 4},
			{id = "ingred_russula_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 60,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_shein",
		product = "Potion_comberry_wine_01",
		alias = "Shein",
		ingreds = {
			{id = "ingred_comberry_01", count = 10},
			{id = "ingred_fire_petal_01", count = 2},
			{id = "mc_sugar", count = 4},
			{id = "ingred_russula_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 90,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_sujamma",
		product = "Potion_local_liquor_01",
		alias = "Sujamma",
		ingreds = {
			{id = "ingred_saltrice_01", count = 10},
			{id = "mc_potato_raw", count = 5},
			{id = "mc_sugar", count = 3},
			{id = "ingred_russula_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 90,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_ungorth",
		product = "T_Orc_Drink_LiquorUngorth_02",
		alias = "Ungorth",
		ingreds = {
			{id = "ingred_scathecraw_01", count = 4},
			{id = "ingred_saltrice_01", count = 10},
			{id = "mc_sugar", count = 2},
			{id = "ingred_russula_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 85,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_veig",
		product = "T_Nor_Drink_SnowberryaleVeig_01",
		alias = "Veig",
		ingreds = {
			{id = "ingred_holly_01", count = 4},
			{id = "ingred_wickwheat_01", count = 10},
			{id = "mc_sugar", count = 2},
			{id = "ingred_coprinus_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 60,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_jagga",
		product = "T_We_Drink_PigmilkbeerJagga_01",
		alias = "Jagga",
		ingreds = {
			{id = "mc_sow_milk", count = 8},
			{id = "ingred_holly_01", count = 2},
			{id = "ingred_belladonna_01", count = 4},
			{id = "ingred_russula_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 70,
		group = "Liquor",
		taskTime = 4
		},

		{id = "mc_kegstand_p_goya",
		product = "T_De_Drink_BourbonGoya_01",
		alias = "Goya",
		ingreds = {
			{id = "ingred_sweetpulp_01", count = 4},
			{id = "ingred_marshmerrow_01", count = 10},
			{id = "ingred_belladonna_01", count = 4},
			{id = "mc_riceflour", count = 4},
			{id = "ingred_coprinus_01", count = 1}
		},
		yieldCount = 1,
		difficulty = 75,
		group = "Liquor",
		taskTime = 4
		}

	}
	return makerlist