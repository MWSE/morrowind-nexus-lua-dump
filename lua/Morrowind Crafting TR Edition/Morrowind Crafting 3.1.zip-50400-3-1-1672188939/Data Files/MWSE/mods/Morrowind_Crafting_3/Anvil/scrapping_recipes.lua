--[[ Scrapping-material listing -- scrapping metal items (weapons/armor)
		Part of Morrowind Crafting 3.0
		Toccatta and Drac
		wpnType = number associated with weapon types - only needed for weapons that share a common .nif --]]
		
	local scraplist = {}
	scraplist = {
		{id = "adamantium boots",
		nif = "A\\A_Adamantium_Boots_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 6,
		taskTime = 0.5
		},

		{id = "adamantium_bracer_left",
		nif = "A\\A_Adamantium_Bracer_GND.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.3
		},

		{id = "adamantium_bracer_right",
		nif = "A\\A_Adamantium_Bracer_GND.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.3
		},

		{id = "adamantium_cuirass",
		nif = "A\\A_Adamantium_Cuirass_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 1
		},

		{id = "adamantium_greaves",
		nif = "A\\A_Adamantium_Greaves_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 5,
		taskTime = 1
		},

		{id = "adamantium_helm",
		nif = "A\\A_adamantium_helm.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.25
		},

		{id = "addamantium_helm",
		nif = "A\\A_adamantium_helm.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 2,
		taskTime = 0.25
		},
		
		{id = "adamantium_pauldron_left",
		nif = "A\\A_Adamantium_Pauldron_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.1
		},

		{id = "adamantium_pauldron_right",
		nif = "A\\A_Adamantium_Pauldron_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.1
		},

		{id = "BM_NordicMail_Boots",
		nif = "a\\A_NordicMail_M_Boot_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_cuirass",
		nif = "a\\A_NordicMail_M_C_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 14,
		taskTime = 1
		},

		{id = "BM_NordicMail_gauntletL",
		nif = "a\\A_NordicMail_M_Ga_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_gauntletR",
		nif = "a\\A_NordicMail_M_Ga_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = .2
		},

		{id = "BM_NordicMail_greaves",
		nif = "a\\A_NordicMail_Greaves_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 7,
		taskTime = .2
		},

		{id = "BM_NordicMail_Helmet",
		nif = "a\\A_NordicMail_M_Helmet.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_PauldronL",
		nif = "a\\A_NordicMail_Pauldron_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_PauldronR",
		nif = "a\\A_NordicMail_Pauldron_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_Shield",
		nif = "a\\A_Nord_Shield.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Boots_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_BT_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Cuirass_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_CU_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Greaves_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_GR_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Helm_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_HE_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_GauntletL_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_GT_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_PauldronL_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_PL_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_GauntletR_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_GT_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_PauldronR_01",
		nif = "Sky\\a\\Sky_A_Guardarmor_PL_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Boots_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_BT_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Cuirass_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_CU_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Greaves_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_GR_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Helm_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_HE_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_GauntletL_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_GT_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_PauldronL_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_PL_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_GauntletR_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_GT_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_PauldronR_01",
		nif = "Sky\\a\\Sky_A_Nord_Steel_PL_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_Boots_01",
		nif = "TR\\a\\tr_a_nordic_boot_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "nordic_iron_cuirass",
		nif = "a\\A_NordicIron_C_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_Greaves_01",
		nif = "TR\\a\\tr_a_nordic_grea_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "nordic_iron_helm",
		nif = "a\\A_NordicIron_Helm.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_GauntletL_01",
		nif = "TR\\a\\tr_a_nordic_G_L_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_PauldronL_01",
		nif = "TR\\a\\tr_a_nordic_pauldr_cl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_GauntletR_01",
		nif = "TR\\a\\tr_a_nordic_G_R_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_PauldronR_01",
		nif = "TR\\a\\tr_a_nordic_pauldr_cl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Boots_01",
		nif = "sky\\a\\sky_a_ringmail01_bt_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Cuirass_01",
		nif = "sky\\a\\sky_a_ringmail01_cu_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "BM riekling lance",
		nif = "w\\IceMspear.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "nordic_ringmail_cuirass",
		nif = "a\\A_Ringmail_Cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Greaves_01",
		nif = "sky\\a\\sky_a_ringmail01_gr_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Helmet_01",
		nif = "sky\\a\\sky_a_ringmail01_he_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "daedric_boots",
		nif = "a\\A_Daedric_Boots_GND.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 19}
			},
		taskTime = 0.2
		},

		{id = "daedric_cuirass",
		nif = "a\\A_Daedric_cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 13,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 21}
			},
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_HelmConsolat_01",
		nif = "tr\\a\\tr_a_dae_face_sheog.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount =1,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},

		{id = "daedric_god_helm",
		nif = "a\\A_Daedric_god_h.NIF",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},

		{id = "daedric_fountain_helm",
		nif = "a\\A_Daedric_fountain_h.NIF",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},
		
		{id = "mc_daedric_clavicus",
		nif = "a\\A_Masque_Clavicus_Vile.NIF",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_HelmRebellion_01",
		nif = "tr\\a\\tr_a_dae_face_dagon.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},
		
		{id = "daedric_terrifying_helm",
		nif = "a\\A_Daedric_terrifying_h.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},

		{id = "daedric_gauntlet_left",
		nif = "a\\A_Daedric_gauntlet_GND.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},

		{id = "daedric_gauntlet_right",
		nif = "a\\A_Daedric_gauntlet_GND.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
		},
		taskTime = 0.2
		},

		{id = "daedric_greaves",
		nif = "a\\A_Daedric_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 7,
		byproduct = {
			{id = "mc_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 18}
		},
		taskTime = 0.2
		},

		{id = "daedric_pauldron_left",
		nif = "a\\A_Daedric_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 8}
		},
		taskTime = 0.2
		},
		

		{id = "daedric_pauldron_right",
		nif = "a\\A_Daedric_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 8}
		},
		taskTime = 0.2
		},

		{id = "daedric_shield",
		nif = "a\\Shield_Daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 5,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 13}
		},
		taskTime = 0.2
		},

		{id = "daedric_towershield",
		nif = "a\\Towershield_Daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 8,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 10}
		},
		taskTime = 0.2
		},
			
		{id = "ebony_boots",
		nif = "a\\A_Ebony_Boot_GND.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_bracer_left",
		nif = "a\\A_Ebony_Bracer_w.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "ebony_bracer_right",
		nif = "a\\A_Ebony_Bracer_w.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "ebony_closed_helm",
		nif = "a\\A_Ebony_Helmet.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_De_Ebony_HelmOpen_01",
		nif = "TR\\a\\TR_a_ebony_helm_o.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_cuirass",
		nif = "a\\A_Ebony_Cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 13,
		taskTime = 0.2
		},

		{id = "ebony_greaves",
		nif = "a\\A_Ebony_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "ebony_pauldron_left",
		nif = "a\\A_Ebony_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_pauldron_right",
		nif = "a\\A_Ebony_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_shield",
		nif = "a\\Shield_ebony.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "ebony_towershield",
		nif = "a\\TowerShield_ebony.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "glass_boots",
		nif = "a\\A_Glass_Boots_GND.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_bracer_left",
		nif = "a\\A_Glass_Bracer_W.nif",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass_bracer_right",
		nif = "a\\A_Glass_Bracer_W.nif",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass_cuirass",
		nif = "a\\A_Glass_cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "glass_greaves",
		nif = "a\\A_Glass_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass_helm",
		nif = "a\\A_Glass_Helmet.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_pauldron_left",
		nif = "a\\A_Glass_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_pauldron_right",
		nif = "a\\A_Glass_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_shield",
		nif = "a\\Shield_Glass.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "glass_towershield",
		nif = "a\\Towershield_Glass.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "silver_dukesguard_cuirass",
		nif = "a\\A_silver_duke_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "silver_cuirass",
		nif = "a\\A_Silver_Cuir_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "helsethguard_boots",
		nif = "a\\A_HelsethGuard_Boots_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "helsethguard_cuirass",
		nif = "a\\A_HelsethGuard_cur_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "helsethguard_gauntlet_left",
		nif = "a\\A_HelsethGuard_gauntl_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "helsethguard_gauntlet_right",
		nif = "a\\A_HelsethGuard_gauntl_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "helsethguard_greaves",
		nif = "a\\A_HelsethGuard_Greave_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "helsethguard_helmet",
		nif = "a\\A_HelsethGuard_Helm.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "helsethguard_pauldron_left",
		nif = "a\\A_HelsethGuard_Pauld_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "helsethguard_pauldron_right",
		nif = "a\\A_HelsethGuard_Pauld_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "imperial boots",
		nif = "a\\A_Imperial_A_Boot_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "imperial cuirass_armor",
		nif = "a\\A_Imperial_M_Cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "imperial_greaves",
		nif = "a\\A_Imperial_Greaves_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "imperial helmet armor",
		nif = "a\\A_Imperial_M_Helmet.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial left gauntlet",
		nif = "a\\A_Imperial_A_Gauntlet_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial left pauldron",
		nif = "a\\A_Imperial_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "imperial right gauntlet",
		nif = "a\\A_Imperial_A_Gauntlet_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial right pauldron",
		nif = "a\\A_Imperial_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "imperial shield",
		nif = "a\\A_Shield_Imperial.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Imp_Chain_Boots_01",
		nif = "tr\\a\\tr_a_chain_boots_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "imperial_chain_coif_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial_chain_cuirass",
		nif = "a\\A_M_ImperialChain_C_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "imperial_chain_greaves",
		nif = "a\\A_M_ImperialChain_Gr_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Chain_GauntletL_01",
		nif = "tr\\a\\tr_a_chain_gntlets_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial_chain_pauldron_left",
		nif = "a\\A_M_ImperialChain_Pa_UA.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Chain_GauntletR_02",
		nif = "tr\\a\\tr_a_chain_gntlets_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial_chain_pauldron_right",
		nif = "a\\A_M_ImperialChain_Pa_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Imp_Ebony_Boots",
		nif = "TR\\a\\TR_A_ImpEbon_Boots_G.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_Cuirass",
		nif = "TR\\a\\TR_A_ImpEbon_C_GND.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_BracerL",
		nif = "TR\\a\\TR_A_ImpEbon_Brc.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_PauldronL",
		nif = "TR\\a\\TR_A_ImpEbon_Pld.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_BracerR",
		nif = "TR\\a\\TR_A_ImpEbon_Brc.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_PauldronR",
		nif = "TR\\a\\TR_A_ImpEbon_Pld.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Boots_01",
		nif = "tr\\a\\tr_a_silver_boots_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Greaves_01",
		nif = "tr\\a\\tr_a_silver_greav_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "silver_helm",
		nif = "a\\A_Helm_silver.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Helm_Mask",
		nif = "pc\\a\\pc_a_silver_mask.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Cap_01",
		nif = "pc\\a\\pc_a_silver_cap_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Cap_02",
		nif = "pc\\a\\pc_a_silver_cap_r_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_CuirassRed_01",
		nif = "pc\\a\\pc_a_silver_cuir_r_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_BracerL_01",
		nif = "tr\\a\\tr_a_silver_bracer_W.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_PauldronL_01",
		nif = "tr\\a\\tr_a_silver_pauld_CL.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_BracerR_01",
		nif = "tr\\a\\tr_a_silver_bracer_W.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_PauldronR_01",
		nif = "tr\\a\\tr_a_silver_pauld_CL.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "indoril boots",
		-- nif = "a\\A_Indoril_M_boot_GND.nif",
		nif = "va\\va_indoril_boot_GND.nif", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "indoril cuirass",
		-- nif = "a\\A_Indoril_M_Cuirass_GND.nif",
		nif = "va\\va_indoril_Cuirass_GND.nif", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_De_Ordinator_Greaves_01",
		nif = "TR\\a\\TR_a_ord_grv_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "indoril helmet",
		-- nif = "a\\A_Indoril_M_Helmet.nif",
		nif = "va\\va_elite_helm_i.NIF", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "indoril left gauntlet",
		-- nif = "a\\A_Indoril_M_Gauntlet_GND.nif",
		nif = "va\\va_indoril_Gauntlet_GND.nif", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "indoril pauldron left",
		-- nif = "a\\A_Indoril_M_Pauldron_GND.nif",
		nif = "va\\va_indoril_Pauldron_GND.nif", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril pauldron right",
		-- nif = "a\\A_Indoril_M_Pauldron_GND.nif",
		nif = "va\\va_indoril_Pauldron_GND.nif", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril right gauntlet",
		-- nif = "a\\A_Indoril_M_Gauntlet_GND.nif",
		nif = "va\\va_indoril_Gauntlet_GND.nif", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "indoril shield",
		-- nif = "a\\Shield_Indoril.nif",
		nif = "va\\va_Shield_indoril.nif", -- VA ordinator armor
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_boots",
		nif = "a\\A_AlmIndoril_Boot_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_cuirass",
		nif = "a\\A_AlmIndoril_Cuirass_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 19,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_gauntlet_l",
		nif = "a\\A_AlmIndoril_Gauntlet_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_gauntlet_r",
		nif = "a\\A_AlmIndoril_Gauntlet_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_greaves",
		nif = "a\\A_AlmIndoril_Greaves_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 12,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_helmet",
		nif = "a\\A_AlmIndoril_Helmet.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_pauldron_l",
		nif = "a\\A_AlmIndoril_Pauldron_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_pauldron_r",
		nif = "a\\A_AlmIndoril_Pauldron_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_shield",
		nif = "a\\Shield_AmIndoril.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Boots_01",
		nif = "TR\\a\\TR_a_Necrom_Boots.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Cuirass_01",
		nif = "tr\\a\\tr_a_nec_cuirass_01_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_CuirassCloak_01",
		nif = "tr\\f\\tr_help_deprec_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Greaves_01",
		nif = "TR\\a\\TR_a_Necrom_Greaves.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Helm_01",
		nif = "TR\\a\\TR_a_nec_helmet.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_PauldronL_01",
		nif = "TR\\a\\TR_A_Necrom_Pauldron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_PauldronR_01",
		nif = "TR\\a\\TR_A_Necrom_Pauldron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Shield_01",
		nif = "TR\\a\\TR_a_NecO_Shield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "iron boots",
		nif = "a\\A_Iron_Boot_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Boots_01",
		nif = "TR\\a\\TR_a_Iron_Boot_G_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Boots_02",
		nif = "TR\\a\\TR_a_Iron_Boot_G_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "iron_bracer_left",
		nif = "a\\A_Iron_Bracer_W.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerL_01",
		nif = "TR\\a\\TR_a_Iron_Bracer_W_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerL_02",
		nif = "TR\\a\\TR_a_Iron_Bracer_W_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron_bracer_right",
		nif = "a\\A_Iron_Bracer_W.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerR_01",
		nif = "TR\\a\\TR_a_Iron_Bracer_W_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerR_02",
		nif = "TR\\a\\TR_a_Iron_Bracer_W_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron_cuirass",
		nif = "a\\A_Iron_Cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Cuirass_01",
		nif = "TR\\a\\TR_a_Iron_Cuirass_G_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Cuirass_02",
		nif = "TR\\a\\TR_a_Iron_Cuirass_G_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "iron_gauntlet_left",
		nif = "a\\A_Iron_Gauntlet_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "iron_gauntlet_right",
		nif = "a\\A_Iron_Gauntlet_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "iron_greaves",
		nif = "a\\A_Iron_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Greaves_01",
		nif = "TR\\a\\TR_a_Iron_Grves_GND_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Greaves_02",
		nif = "TR\\a\\TR_a_Iron_Grves_GND_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "iron_helmet",
		nif = "a\\A_Iron_Helm_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_01",
		nif = "TR\\a\\TR_a_Iron_Helm1_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_02",
		nif = "TR\\a\\TR_a_Iron_Helm1_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_Open",
		nif = "pc\\a\\pc_a_iron_helm_o.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron_pauldron_left",
		nif = "a\\A_Iron_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronL_01",
		nif = "TR\\a\\TR_a_Iron_Pldron_CL_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronL_02",
		nif = "TR\\a\\TR_a_Iron_Pldron_CL_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Com_IronSpike_PauldronL_01",
		nif = "TR\\a\\TR_a_IronSpiked_PldCl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "iron_pauldron_right",
		nif = "a\\A_Iron_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronR_01",
		nif = "TR\\a\\TR_a_Iron_Pldron_CL_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronR_02",
		nif = "TR\\a\\TR_a_Iron_Pldron_CL_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_IronSpike_PauldronR_01",
		nif = "TR\\a\\TR_a_IronSpiked_PldCl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "iron_shield",
		nif = "a\\Shield_iron.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_Aka_Regular_Shield_01",
		nif = "TR\\a\\tr_a_blades_shield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "iron_towershield",
		nif = "a\\TowerShield_iron.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_Boots_01",
		nif = "pc\\a\\PC_a_newt_boot_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "newtscale_cuirass",
		nif = "a\\A_Newstscale_C_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_Greaves_01",
		nif = "pc\\a\\PC_a_newt_greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_Helm_01",
		nif = "pc\\a\\pc_a_newt_helm.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_GauntletL_01",
		nif = "pc\\a\\PC_a_newt_glove_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_PauldronL_01",
		nif = "pc\\a\\PC_a_newt_pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_GauntletR_01",
		nif = "pc\\a\\PC_a_newt_glove_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_PauldronR_01",
		nif = "pc\\a\\PC_a_newt_pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "orcish_boots",
		nif = "a\\A_Orcish_Boots_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "orcish_bracer_left",
		nif = "a\\A_Orcish_Bracer_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "orcish_bracer_right",
		nif = "a\\A_Orcish_Bracer_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "orcish_cuirass",
		nif = "a\\A_Orcish_Cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 12,
		taskTime = 0.2
		},

		{id = "orcish_greaves",
		nif = "a\\A_Orcish_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "orcish_helm",
		nif = "a\\A_Orcish_Helmet.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_HelmOpen_01",
		nif = "TR\\a\\TR_a_orcish_helm_o.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "orcish_pauldron_left",
		nif = "a\\A_Orcish_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "orcish_pauldron_right",
		nif = "a\\A_Orcish_Pauldron_UA.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "orcish_towershield",
		nif = "a\\Towershield_Orcish.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "orcish warhammer",
		nif = "w\\W_Orcish_warhammer.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 15,
		taskTime = 0.5
		},

		{id = "orcish battle axe",
		nif = "w\\W_Orcish_battleaxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.5
		},
		
		{id = "T_Com_Chain_Cuirass_01",
		nif = "TR\\a\\TR_a_chain_cuir_gnd01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Com_Chain_Cuirass_02",
		nif = "TR\\a\\TR_a_chain_cuir_gnd02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Com_Chain_Cuirass_03",
		nif = "TR\\a\\TR_a_chain_cuir_gnd03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "T_Rga_CrownGuard1_Boots_01",
		nif = "Sky\\a\\Sky_A_Redguard_BT_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_Greaves_01",
		nif = "sky\\a\\sky_a_redguard_gr_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_Helm_01",
		nif = "Sky\\a\\Sky_A_Redguard_HE_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_PauldronL_01",
		nif = "Sky\\a\\Sky_A_Redguard_PL_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_Cuirass_01",
		nif = "Sky\\a\\Sky_A_Redguard_CU_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_PauldronR_01",
		nif = "Sky\\a\\Sky_A_Redguard_PL_G.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_Boots_01",
		nif = "pc\\a\\PC_A_dragon_Boots_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_cuirass_01",
		nif = "a\\A_Dragonscale_Cuir_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "dragonscale_cuirass",
		nif = "a\\A_Dragonscale_Cuir_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_Greaves_01",
		nif = "pc\\a\\PC_A_dragon_Greav_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_helm_01",
		nif = "a\\A_Dragonscale_Helm.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "dragonscale_helm",
		nif = "a\\A_Dragonscale_Helm.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_BarcerL_01",
		nif = "pc\\a\\PC_a_dragon_brac_l_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_PauldronL_01",
		nif = "pc\\a\\PC_a_dragon_pauld_CL_L.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_BarcerR_01",
		nif = "pc\\a\\PC_a_dragon_brac_r_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_PauldronR_01",
		nif = "pc\\a\\PC_a_dragon_pauld_CL_R.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "dragonscale_towershield",
		nif = "a\\Towershield_Dragonscale.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_boots",
		nif = "a\\A_Steel_Boots_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel_cuirass",
		nif = "a\\A_Steel_Cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_01",
		nif = "TR\\a\\TR_A_Steel_Cuirass_G_2.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_02",
		nif = "TR\\a\\TR_A_Steel_Cuirass_G_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_03",
		nif = "TR\\a\\TR_A_Steel_Cuirass_G_4.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_04",
		nif = "TR\\a\\TR_A_Steel_Cuirass_G_5.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "steel_gauntlet_left",
		nif = "a\\A_Steel_Gauntlet_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel_gauntlet_right",
		nif = "a\\A_Steel_Gauntlet_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel_greaves",
		nif = "a\\A_Steel_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "steel_helm",
		nif = "a\\A_Steel_Helmet.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Helm_01",
		nif = "TR\\a\\TR_A_Steel_Helmet_05.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Helm_Open_01",
		nif = "pc\\a\\pc_a_steel_helm_o_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Helm_Open_02",
		nif = "pc\\a\\pc_a_steel_helm_o_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel_pauldron_left",
		nif = "a\\A_Steel_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronL_01",
		nif = "TR\\a\\TR_A_Steel_Pldron_CL_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronL_02",
		nif = "TR\\a\\TR_A_Steel_Pldron_CL_4.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronL_03",
		nif = "TR\\a\\TR_A_Steel_Pldron_CL_5.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_SteelSpike_PauldronL_01",
		nif = "TR\\a\\TR_a_SteelSpiked_PldCl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_pauldron_right",
		nif = "a\\A_Steel_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronR_01",
		nif = "TR\\a\\TR_A_Steel_Pldron_CL_3.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronR_02",
		nif = "TR\\a\\TR_A_Steel_Pldron_CL_4.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronR_03",
		nif = "TR\\a\\TR_A_Steel_Pldron_CL_5.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_SteelSpike_PauldronR_01",
		nif = "TR\\a\\TR_a_SteelSpiked_PldCl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_shield",
		nif = "a\\shield_steel.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_towershield",
		nif = "a\\TowerShield_steel.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "templar boots",
		nif = "a\\A_Templar_M_Boot_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "templar bracer left",
		nif = "a\\A_Templar_M_W_Bracer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "templar bracer right",
		nif = "a\\A_Templar_M_W_Bracer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "templar_cuirass",
		nif = "a\\A_Templar_M_Cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "templar_greaves",
		nif = "a\\A_Templar_Greaves_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "templar_helmet_armor",
		nif = "a\\A_Templar_M_Helmet.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "templar_pauldron_left",
		nif = "a\\A_Templar_M_CL_Pauldron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "templar_pauldron_right",
		nif = "a\\A_Templar_M_CL_Pauldron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Templar_ShieldTower_01",
		nif = "pc\\a\\PC_A_Templar_Shield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "mc_dwemer_boots",
		nif = "mc\\mc_Dwemer_Boots_GND.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "mc_dwemer_bracer_left",
		nif = "mc\\mc_Dwemer_Bracer_W_GND.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_bracer_right",
		nif = "mc\\mc_Dwemer_Bracer_W_GND.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_cuirass",
		nif = "mc\\mc_Dwemer_Cuir_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 11,
		taskTime = 0.2
		},		

		{id = "mc_dwemer_greaves",
		nif = "mc\\mc_Dwemer_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "mc_dwemer_helm",
		nif = "mc\\mc_Dwemer_Helmet.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "mc_dwemer_pauldron_left",
		nif = "mc\\mc_Dwemer_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_pauldron_right",
		nif = "mc\\mc_Dwemer_Pauldron_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_shield",
		nif = "mc\\mc_shield_dwemer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_towershield",
		nif = "mc\\mc_a_dwrv_twrshield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "dwemer_boots",
		nif = "a\\A_Dwemer_Boots_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "dwemer_bracer_left",
		nif = "a\\A_Dwemer_Bracer_W.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_bracer_right",
		nif = "a\\A_Dwemer_Bracer_W.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_cuirass",
		nif = "a\\A_Dwemer_Cuir_GND.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 11,
		taskTime = 0.2
		},		

		{id = "dwemer_greaves",
		nif = "a\\A_Dwemer_Greaves_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "dwemer_helm",
		nif = "a\\A_Dwemer_Helmet.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "dwemer_pauldron_left",
		nif = "a\\A_Dwemer_Pauldron_UA.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_pauldron_right",
		nif = "a\\A_Dwemer_Pauldron_UA.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_shield",
		nif = "a\\Shield_Dwemer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "adamantium_axe",
		nif = "w\\W_Adamantium_Axe.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 16,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_DoubleAxe_01",
		nif = "TR\\w\\TR_w_adamant_doubleaxe.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 16,
		taskTime = 0.2
		},
		
		{id = "T_Com_Adamant_Broadsword_01",
		nif = "TR\\w\\TR_w_adamant_bsword.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "adamantium_claymore",
		nif = "w\\W_Adamantium_Claymore.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 23,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Club_01",
		nif = "TR\\w\\TR_w_adamant_club.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Com_Adamant_Crossbow_01",
		nif = "TR\\w\\TR_w_adamant_crossbow.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 0.2
		},		

		{id = "T_Com_Adamant_Dagger_01",
		nif = "TR\\w\\TR_w_adamant_dagger.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_DaiKatana_01",
		nif = "TR\\w\\TR_w_adamant_dkatana.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 18,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Gisern",
		nif = "pc\\w\\pc_w_admnt_gisern.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Halberd_01",
		nif = "TR\\w\\TR_w_adamant_halberd.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},
	
		{id = "T_Com_Adamant_Katana_01",
		nif = "TR\\w\\TR_w_adamant_katana.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 15,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Bow_01",
		nif = "TR\\w\\TR_w_adamant_bow.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Longsword_01",
		nif = "TR\\w\\TR_w_adamant_lsword.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "adamantium_mace",
		nif = "w\\W_Adamantium_Mace.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Saber_01",
		nif = "TR\\w\\TR_w_adamant_saber.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},		

		{id = "T_Com_Adamant_Scimitar_01",
		nif = "TR\\w\\TR_w_adamant_scimtar.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "adamantium_shortsword",
		nif = "w\\W_Adamantium_ShortSword.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "adamantium_spear",
		nif = "w\\W_Adamantium_Spear.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Staff_01",
		nif = "TR\\w\\TR_w_adamant_staff.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 5,
		taskTime = 0.2
		},		

		{id = "T_Com_Adamant_Tanto_01",
		nif = "TR\\w\\TR_w_adamant_tanto.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 4,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_Star",
		nif = "pc\\w\\pc_w_admnt_star.nif",
		wpnType = 11,
		qtyReq = 4,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_Wakizashi_01",
		nif = "TR\\w\\TR_w_adamant_wakazashi.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_WarAxe_01",
		nif = "TR\\w\\TR_w_adamant_waraxe.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 9,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_Warhammer_01",
		nif = "TR\\w\\TR_w_adamant_warhammer.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 21,
		taskTime = 0.2
		},	
		
		{id = "BM Huntsman axe",
		nif = "w\\W_Huntsman_waraxe.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "BM huntsman longsword",
		nif = "w\\W_Huntsman_longsword.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "BM Huntsman Spear",
		nif = "w\\W_Huntsman_spear.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "BM Huntsman war axe",
		nif = "w\\W_Huntsman_waraxeM.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_ThrowingAxe_01",
		nif = "sky\\w\\sky_throwing_axe_l.nif",
		wpnType = 11,
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "BM nordic silver axe",
		nif = "w\\W_Nord_waraxe.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "BM nordic silver battleaxe",
		nif = "w\\W_Nord_battleaxe.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 12,
		taskTime = 0.2
		},

		{id = "BM nordic silver claymore",
		nif = "w\\W_Nord_claymore.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "BM nordic silver dagger",
		nif = "w\\W_Nord_dagger.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "BM nordic silver longsword",
		nif = "w\\W_Nord_longsword.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "BM nordic silver mace",
		nif = "w\\W_Nord_mace.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},

		{id = "BM nordic silver shortsword",
		nif = "w\\W_Nord_shortsword.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_Com_Iron_ThrowingKnife_01",
		nif = "w\\w_knife_iron.nif",
		wpnType = 11,
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "daedric battle axe",
		nif = "w\\W_battleaxe_daedric.NIF",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 9,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 3},
			{id = "mc_scrap_iron", yield = 28}
			},
		taskTime = 0.2
		},

		{id = "daedric claymore",
		nif = "w\\W_Claymore_Daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 14,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 20}
			},
		taskTime = 0.2
		},

		{id = "daedric club",
		nif = "w\\W_club_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 3},
			{id = "mc_scrap_iron", yield = 17}
			},
		taskTime = 0.2
		},

		{id = "daedric dagger",
		nif = "w\\W_Dagger_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 2}
			},
		taskTime = 0.2
		},

		{id = "daedric dai-katana",
		nif = "w\\W_Dai-katana_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 20,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 6}
			},
		taskTime = 0.2
		},
		
		{id = "daedric katana",
		nif = "w\\W_katana_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 9,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 13}
			},
		taskTime = 0.2
		},

		{id = "daedric long bow",
		nif = "w\\W_longbow_daedric.NIF",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 8,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 2}
			},
		taskTime = 0.2
		},

		{id = "T_Dae_Regular_Longspear_01",
		nif = "w\\w_longspear_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 14}
			},
		taskTime = 0.2
		},		

		{id = "T_Dae_Regular_Longsword_01",
		nif = "TR\\w\\TR_w_daedra_lsword_02.NIF",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 6,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 19}
			},
		taskTime = 0.2
		},
		
		{id = "daedric longsword",
		nif = "w\\W_Longsword_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 6,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 19}
			},
		taskTime = 0.2
		},

		{id = "daedric mace",
		nif = "w\\W_mace_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 15}
			},
		taskTime = 0.2
		},

		{id = "T_Dae_Regular_Naginata_01",
		nif = "TR\\w\\TR_w_daedra_naginata.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 15}
			},
		taskTime = 0.2
		},		

		{id = "T_Dae_Regular_Saber_01",
		nif = "TR\\w\\TR_w_daedra_saber.NIF",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 13}
			},
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_Scimitar_02",
		nif = "TR\\w\\TR_w_daedra_scimi_02.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 14}
			},
		taskTime = 0.2
		},
		
		{id = "daedric shortsword",
		nif = "w\\W_Shortsword_Daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 7}
			},
		taskTime = 0.2
		},

		{id = "daedric spear",
		nif = "w\\W_spear_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 14}
			},
		taskTime = 0.2
		},

		{id = "daedric staff",
		nif = "w\\W_staff_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 7}
			},
		taskTime = 0.2
		},

		{id = "daedric tanto",
		nif = "w\\W_tanto_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 3}
			},
		taskTime = 0.2
		},
		
		{id = "daedric wakizashi",
		nif = "w\\W_wakazashi_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 8,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 4}
			},
		taskTime = 0.2
		},

		{id = "daedric war axe",
		nif = "w\\W_waraxe_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 3},
			{id = "mc_scrap_iron", yield = 21}
			},
		taskTime = 0.2
		},

		{id = "daedric warhammer",
		nif = "w\\W_warhammer_daedric.nif",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 4},
			{id = "mc_scrap_iron", yield = 32}
			},
		taskTime = 0.2
		},

		{id = "T_Com_DaedSteel_Broadsword_01",
		nif = "TR\\w\\TR_w_steel_dae_bsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 6,
		taskTime = 0.2
		},		

		{id = "T_Com_DaedSteel_Claymore_01",
		nif = "TR\\w\\TR_w_steel_dae_cmore.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 13,
		taskTime = 0.2
		},	

		{id = "T_Com_DaedSteel_Dagger_01",
		nif = "TR\\w\\TR_w_steel_dae_dagg.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 2,
		taskTime = 0.2
		},	

		{id = "T_Com_DaedSteel_Longsword_01",
		nif = "TR\\w\\TR_w_steel_dae_lsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 10,
		taskTime = 0.2
		},	

		{id = "T_Com_DaedSteel_Shortsword_01",
		nif = "TR\\w\\TR_w_steel_dae_ssword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 5,
		taskTime = 0.2
		},	

		{id = "dwarven battle axe",
		nif = "w\\W_Dwemer_battleaxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 10,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Broadsword_01",
		nif = "TR\\w\\TR_w_dwrv_bsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},			
		
		{id = "dwarven claymore",
		nif = "w\\W_Dwemer_claymore.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 12,
		taskTime = 0.2
		},	

		{id = "dwarven crossbow",
		nif = "w\\W_Crossbow_Dwemer.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Dagger_01",
		nif = "TR\\w\\TR_w_dwrv_dagger.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2
		},			
		
		{id = "dwarven halberd",
		nif = "w\\W_Dwemer_halberd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Junkmace_01",
		nif = "TR\\w\\TR_w_dwrv_junk_mace.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Longspear_01",
		nif = "w\\w_dwemer_longspear.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Longsword_01",
		nif = "TR\\w\\TR_w_dwrv_lsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},	
		
		{id = "dwarven mace",
		nif = "w\\W_Dwemer_mace.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Staff_01",
		nif = "TR\\w\\tr_w_dwrv_staff.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},			
		
		{id = "dwarven shortsword",
		nif = "w\\W_Dwemer_shortsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 2,
		taskTime = 0.2
		},	

		{id = "dwarven spear",
		nif = "w\\W_Dwemer_spear.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 2,
		taskTime = 0.2
		},			
		
		{id = "dwarven war axe",
		nif = "w\\W_Dwemer_waraxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 4,
		taskTime = 0.2
		},	

		{id = "dwarven warhammer",
		nif = "w\\W_Dwemer_warhammer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},	

		{id = "T_De_Ebony_Halberd_01",
		nif = "TR\\w\\tr_w_ebony_halberd.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Battleaxe_01",
		nif = "pc\\w\\pc_w_ebon_battleaxe.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "ebony broadsword",
		nif = "w\\W_broadsword_ebony.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Claymore_01",
		nif = "TR\\w\\TR_w_ebony_claymore.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 14,
		taskTime = 0.2
		},		

		{id = "T_De_Ebony_Dagger_01",
		nif = "TR\\w\\tr_w_ebony_dagger.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_DaiKatana_01",
		nif = "TR\\w\\TR_w_ebony_dkatana.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 19,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Halberd_02",
		nif = "pc\\w\\pc_w_ebon_halberd.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Katana_01",
		nif = "TR\\w\\tr_w_ebony_katana.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "ebony longsword",
		nif = "w\\W_Longsword_ebony.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "ebony mace",
		nif = "w\\W_mace_ebony.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "Ebony Scimitar",
		nif = "w\\W_Ebony_Scimitar.NIF",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "ebony shortsword",
		nif = "w\\W_Shortsword_Ebony.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Shortsword_02",
		nif = "pc\\w\\pc_w_ebon_ssword2.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},		
		
		{id = "ebony spear",
		nif = "w\\W_longspear_ebony.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "ebony staff",
		nif = "w\\W_staff_ebony.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Tanto_01",
		nif = "TR\\w\\tr_w_ebony_tanto.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "ebony throwing star",
		nif = "w\\W_Star_Ebony.NIF",
		wpnType = 11,
		qtyReq = 10,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},			

		{id = "T_De_Ebony_Wakizashi_01",
		nif = "TR\\w\\tr_w_ebony_wakizashi.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "ebony war axe",
		nif = "w\\W_waraxe_ebony.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Warhammer_01",
		nif = "pc\\w\\pc_w_ebon_whammer.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},		

		{id = "T_De_Ebony_Scythe",
		nif = "pc\\w\\pc_w_ebon_warscythe.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_BattleAxe_01",
		nif = "TR\\w\\tr_w_glass_battleaxe.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "glass claymore",
		nif = "w\\w_claymore_crystal.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "glass dagger",
		nif = "w\\W_dagger_glass.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_DaiKatana_01",
		nif = "TR\\w\\tr_w_glass_dkatana.NIF",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Katana_01",
		nif = "TR\\w\\tr_w_glass_katana.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass halberd",
		nif = "w\\W_halberd_glass.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass longsword",
		nif = "w\\W_Longsword_crystal.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_De_UNI_GlassShortsword",
		nif = "tr\\f\\tr_help_deprec_01.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Spear_01",
		nif = "TR\\w\\tr_w_glass_spear.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass staff",
		nif = "w\\W_staff_glass.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Tanto_01",
		nif = "TR\\w\\tr_w_glass_tanto.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass throwing knife",
		nif = "w\\W_knife_glass.nif",
		wpnType = 11,
		qtyReq = 5,
		yieldID = "ingred_raw_glass_01",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass throwing star",
		nif = "w\\W_Star_Glass.NIF",
		wpnType = 11,
		qtyReq = 10,
		yieldID = "ingred_raw_glass_01",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Wakizashi_01",
		nif = "TR\\w\\tr_w_glass_wakazashi.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass war axe",
		nif = "w\\W_waraxe_glass.nif",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Cleaver_01",
		nif = "TR\\w\\tr_w_cook_cleaver_AY.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Knife_01",
		nif = "TR\\w\\tr_w_cook_knife_00AY.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Knife_02",
		nif = "TR\\w\\tr_w_cook_knife_01AY.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Knife_03",
		nif = "TR\\w\\tr_w_cook_knife_02AY.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "imperial broadsword",
		nif = "w\\W_Broadsword_Imperial.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Broadsword_01",
		nif = "TR\\w\\TR_w_imp_bsword_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Broadsword_02",
        nif = "TR\\w\\TR_w_imp_bsword_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Broadsword_03",
        nif = "TR\\w\\TR_w_imp_bsword_04.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Dagger_01",
        nif = "TR\\w\\TR_w_imp_dagger.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "imperial shortsword",
        nif = "w\\W_Shortsword_Imperial.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "T_Imp_Legion_Longsword_01",
        nif = "pc\\w\\pc_w_imp_lsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_RoyalLongsword_01",
        nif = "TR\\w\\TR_w_imp_roy_lsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Saber_01",
        nif = "TR\\w\\TR_w_imp_saber.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "iron battle axe",
        nif = "w\\W_BATTLEAXE_IRON.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "iron broadsword",
        nif = "w\\W_BROADSWORD_IRON.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Broadsword_01",
        nif = "TR\\w\\TR_w_iron_bsword_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Broadsword_02",
        nif = "TR\\w\\TR_w_iron_bsword_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Broadsword_03",
        nif = "TR\\w\\TR_w_iron_bsword_04.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "iron claymore",
        nif = "w\\W_Iron_Claymore.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "iron club",
        nif = "w\\W_CLUB_IRON.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron dagger",
        nif = "w\\W_iron_dagger.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Dagger_01",
        nif = "TR\\w\\TR_w_iron_dagger_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Dagger_02",
        nif = "TR\\w\\TR_w_iron_dagger_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron fork",
        nif = "w\\W_De_Fork.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "iron halberd",
        nif = "w\\W_halberd_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Hoe_01",
        nif = "pc\\w\\pc_farm_hoe_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "Iron Long Spear",
        nif = "w\\w_spear_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron longsword",
        nif = "w\\W_Iron_Longsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "iron mace",
        nif = "w\\w_mace_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Morningstar_01",
        nif = "TR\\w\\TR_w_iron_morningstar.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Pitchfork_01",
        nif = "pc\\w\\pc_pitchfork_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron saber",
        nif = "w\\W_SABER_IRON.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Saber_01",
        nif = "TR\\w\\TR_w_iron_saber_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Saber_02",
        nif = "TR\\w\\TR_w_iron_saber_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Saber_03",
        nif = "TR\\w\\TR_w_iron_saber_04.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Scimitar_01",
        nif = "TR\\w\\TR_w_iron_scimitar.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Scythe_01",
        nif = "pc\\w\\pc_scythe_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron shortsword",
        nif = "w\\W_Iron_shortsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Shovel_01",
        nif = "pc\\w\\pc_shovel_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron spear",
        nif = "w\\w_spear_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron tanto",
        nif = "w\\W_Tanto.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_01",
        nif = "TR\\w\\tr_w_iron_tanto_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_02",
        nif = "TR\\w\\TR_w_iron_tanto_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_03",
        nif = "TR\\w\\TR_w_iron_tanto_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_04",
        nif = "TR\\w\\TR_w_iron_tanto_04.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron throwing knife",
        nif = "w\\W_KNIFE_IRON.nif",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_ThrowingKnife_02",
        nif = "TR\\w\\TR_w_iron_tknife_02.nif",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Trovel_01",
        nif = "pc\\w\\pc_farm_trovel_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron wakizashi",
        nif = "w\\W_wakizashi_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "iron war axe",
        nif = "w\\W_WARAXE_IRON.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_WarAxe_01",
        nif = "Sky\\w\\Sky_Iron_Waraxe_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "iron warhammer",
        nif = "w\\w_warhammer_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "miner's pick",
        nif = "w\\W_miner_pick.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "steel miner's pick",
        nif = "w\\W_miner_pick.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Rea_Regular_Halberd_01",
        nif = "Sky\\w\\Sky_RM_Halberd_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Rea_Regular_WarAxe_01",
        nif = "Sky\\w\\Sky_RM_Waraxe_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Rea_Regular_Warhammer_01",
        nif = "Sky\\w\\Sky_RM_Warhammer_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_WarAxe_01",
        nif = "TR\\w\\TR_w_nord_axe_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},

		{id = "nordic battle axe",
        nif = "w\\W_Nordic_BattleAxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 13,
		taskTime = 0.2
		},

		{id = "nordic broadsword",
        nif = "w\\W_Nordic_Broadsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "nordic claymore",
        nif = "w\\W_Nordic_Claymore.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 14,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Dagger_01",
        nif = "TR\\w\\TR_w_nord_dagger.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Longsword_01",
        nif = "TR\\w\\TR_w_nord_lsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Seax_01",
        nif = "TR\\w\\TR_w_seax_steel.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Shortsword_01",
        nif = "TR\\w\\TR_w_nord_ssword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Spear_01",
        nif = "TR\\w\\TR_w_nord_spear.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Warhammer_01",
        nif = "TR\\w\\TR_w_nord_whammer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 16,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_ThrowingAxe_01",
        nif = "sky\\w\\sky_throwing_axe.nif",
		qtyReq = 8,
		yieldID = "mc_scrap_orcish",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "Orcish warhammer",
        nif = "w\\W_Orcish_warhammer.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 14,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Bow_01",
        nif = "Sky\\w\\Sky_Orc_Bow_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "Orcish battle axe",
        nif = "w\\W_Orcish_battleaxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Claymore_01",
        nif = "TR\\w\\TR_w_orcish_claymore.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "T_Orc_Regular_Halberd_01",
        nif = "TR\\w\\TR_w_orcish_halberd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Longsword_01",
        nif = "TR\\w\\TR_w_orcish_lsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Mace_01",
        nif = "TR\\w\\TR_w_orcish_mace.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},

		{id = "T_Orc_Regular_Spear_01",
		nif = "TR\\w\\TR_w_orcish_spear_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Spear_02",
		nif = "TR\\w\\TR_w_orcish_spear_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "silver claymore",
		nif = "w\\W_Silver_Claymore.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "silver dagger",
		nif = "w\\W_silver_dagger.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Dagger_01",
		nif = "tr\\w\\tr_w_silver_dagger_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Dagger_02",
		nif = "tr\\w\\tr_w_silver_dagger_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "silver longsword",
		nif = "w\\W_Longsword_Silver.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Mace_01",
		nif = "TR\\w\\TR_w_silver_mace.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Mace_02",
		nif = "pc\\w\\pc_w_silver_mace.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Saber_01",
		nif = "TR\\w\\TR_w_silver_saber.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Saber_02",
		nif = "pc\\w\\pc_w_silver_saber.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "silver shortsword",
		nif = "w\\W_silver_Shortsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "silver spear",
		nif = "w\\W_silver_spear.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "silver staff",
		nif = "w\\W_silver_staff.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "silver throwing star",
		nif = "w\\W_silver_star.NIF",
		qtyReq = 5,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "silver war axe",
		nif = "w\\W_silver_waraxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel axe",
		nif = "w\\W_WarAxe_Steel.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "steel battle axe",
		nif = "w\\W_steel_battleaxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "steel broadsword",
		nif = "w\\W_Broadsword_Imperial.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "steel claymore",
		nif = "w\\W_claymore.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "steel club",
		nif = "w\\W_spikedClub.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "steel crossbow",
		nif = "w\\W_Crossbow_Steel.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel dagger",
		nif = "w\\W_Dagger_dragon.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Dagger_01",
		nif = "TR\\w\\TR_w_steel_dagger_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel dai-katana",
		nif = "w\\W_Daikatana.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel halberd",
		nif = "w\\W_HALBERD_STEEL.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel katana",
		nif = "w\\W_N_Katana.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "steel longbow",
		nif = "w\\W_longbow_steel.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel longsword",
		nif = "w\\W_Broadsword_leafblade.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel mace",
		nif = "w\\W_mace.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "steel saber",
		nif = "w\\W_Saber.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Scimitar_01",
		nif = "TR\\w\\TR_w_steel_scimitar.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel shortsword",
		nif = "w\\W_shortsword00.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "steel spear",
		nif = "w\\W_spear.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel staff",
		nif = "w\\W_staff00.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel tanto",
		nif = "w\\W_Tanto.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel throwing knife",
		nif = "w\\W_Dagger_dragon.nif",
		wpnType = 11,
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Knife_01",
		nif = "w\\w_steel_knife.nif",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel throwing star",
		nif = "w\\W_Steel_star .NIF",
		wpnType = 11,
		qtyReq = 12,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel wakizashi",
		nif = "w\\W_Wakizashi.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel war axe",
		nif = "w\\W_WarAxe_Steel.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel warhammer",
		nif = "w\\W_Warhammer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_gear00",
		nif = "m\\misc_dwrv_gear00.nif",
		qtyReq = 1,
		yieldID = "ingred_scrap_metal_01",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "misc_com_silverware_knife",
		nif = "m\\Misc_Com_Silverware_Knife.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareKnife_01",
		nif = "TR\\m\\TR_misc_silv_knife_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_com_silverware_fork",
		nif = "m\\Misc_Com_Silverware_Fork.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareFork_01",
		nif = "TR\\m\\TR_misc_silv_fork_02.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_com_silverware_spoon",
		nif = "m\\Misc_Com_Silverware_Spoon.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareSpoon_01",
		nif = "TR\\m\\TR_misc_silv_spoon_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareBottle_01",
		nif = "TR\\m\\TR_misc_silv_bottle_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "Misc_Imp_Silverware_Bowl",
		nif = "m\\Misc_Silverware_Bowl.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverBowl_01",
		nif = "Sky\\m\\Sky_Misc_Slv_Bwl_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverBowl_02",
		nif = "sky\\m\\sky_misc_slv_bwl_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_cup",
		nif = "m\\Misc_Silverware_Cup.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "Misc_Imp_Silverware_Cup_01",
		nif = "m\\Misc_Silverware_Cup_01.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareCup_01",
		nif = "TR\\m\\TR_misc_silv_cup_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareCup_02",
		nif = "TR\\m\\TR_misc_silv_cup_02.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareCup_03",
		nif = "TR\\m\\TR_misc_silv_cup_03.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareDish_01",
		nif = "TR\\m\\TR_misc_silv_dish_01.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareDish_02",
		nif = "TR\\m\\TR_misc_silv_dish_02.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverGoblet_01",
		nif = "sky\\m\\sky_misc_slv_gob_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_pitcher",
		nif = "m\\Misc_Silverware_Pitcher.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_plate_01",
		nif = "m\\Misc_Silverware_Plate_01.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_plate_02",
		nif = "m\\Misc_Silverware_Plate_02.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_plate_03",
		nif = "m\\Misc_Silverware_Plate_03.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
			
		{id = "T_Imp_SilverWarePlate_01",
		nif = "TR\\m\\TR_misc_silv_plate_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_02",
		nif = "TR\\m\\TR_misc_silv_plate_04.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_03",
		nif = "TR\\m\\TR_misc_silv_plate_05.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_04",
		nif = "TR\\m\\TR_misc_silv_plate_06.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_05",
		nif = "TR\\m\\TR_misc_silv_plate_07.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_06",
		nif = "TR\\m\\TR_misc_silv_plate_08.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverPlate_01",
		nif = "Sky\\m\\Sky_Misc_Slv_Plt_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverPlate_02",
		nif = "sky\\m\\sky_misc_slv_plt_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverPlate_03",
		nif = "sky\\m\\sky_misc_slv_plt_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePot_01",
		nif = "TR\\m\\TR_misc_silv_pot_01.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareVase_01",
		nif = "TR\\m\\TR_misc_silv_vase_02.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverVase_01",
		nif = "sky\\m\\sky_misc_slv_vs_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverVase_02",
		nif = "sky\\m\\sky_misc_slv_vs_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "misc_com_metal_goblet_01",
		nif = "m\\Misc_Com_Metal_Goblet_01.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_goblet_02",
		nif = "m\\Misc_Com_Metal_Goblet_02.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_tankard_01",
		nif = "m\\Misc_Com_Tankard_01.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Imp_TankardNavy_01",
		nif = "tr\\m\\misc_impn_tankard_01.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "Misc_Com_Pitcher_Metal_01",
		nif = "m\\Misc_Com_Pitcher_Metal_01.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_03",
		nif = "m\\Misc_Com_Metal_Plate_03.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_04",
		nif = "m\\Misc_Com_Metal_Plate_04.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_05",
		nif = "m\\Misc_Com_Metal_Plate_05.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_07",
		nif = "m\\Misc_Com_Metal_Plate_07.NIF",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Imp_SilverWareTankard_01",
		nif = "tr\\m\\tr_misc_silv_tank_01.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_black",
		nif = "mc\\mc_candle_1sil_black.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_blue",
		nif = "mc\\mc_candle_1sil_blue.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_green",
		nif = "mc\\mc_candle_1sil_green.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_orange",
		nif = "mc\\mc_candle_1sil_orange.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_purple",
		nif = "mc\\mc_candle_1sil_purple.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_red",
		nif = "mc\\mc_candle_1sil_red.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_white",
		nif = "mc\\mc_candle_1sil_white.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_yellow",
		nif = "mc\\mc_candle_1sil_yellow.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "TR_m3_i3_316_Com_Candle_14_off",
		nif = "l\\Light_Com_Candle_14.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_03",
		nif = "l\\Light_Com_Candle_03.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_03_64",
		nif = "l\\Light_Com_Candle_03.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_08",
		nif = "l\\Light_Com_Candle_08.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_08_64",
		nif = "l\\Light_Com_Candle_08.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_14",
		nif = "l\\Light_Com_Candle_14.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_14_77",
		nif = "l\\Light_Com_Candle_14.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_15",
		nif = "l\\Light_Com_Candle_15.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_black",
		nif = "mc\\mc_candle_3sil_black.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_blue",
		nif = "mc\\mc_candle_3sil_blue.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_green",
		nif = "mc\\mc_candle_3sil_green.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_orange",
		nif = "mc\\mc_candle_3sil_orange.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_purple",
		nif = "mc\\mc_candle_3sil_purple.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_red",
		nif = "mc\\mc_candle_3sil_red.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_white",
		nif = "mc\\mc_candle_3sil_white.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_yellow",
		nif = "mc\\mc_candle_3sil_yellow.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10",
		nif = "l\\LIght_Com_Candle_10.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10_off",
		nif = "l\\LIght_Com_Candle_10.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10_64",
		nif = "l\\LIght_Com_Candle_10.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10_128",
		nif = "l\\LIght_Com_Candle_10.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_16",
		nif = "l\\Light_Com_Candle_16.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_16_77",
		nif = "l\\Light_Com_Candle_16.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Dwe_Regular_ShieldTower_01",
		nif = "TR\\a\\TR_a_dwrv_twrshield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "misc_dwrv_mug00",
		nif = "m\\misc_dwrv_mug00.nif",
		qtyReq = 7,
		yieldID = "mc_scrap_dwemer",
		byproduct = {
			{ id = "mc_scrap_iron", yield = 5 }
					},
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_goblet00",
		nif = "m\\misc_dwrv_goblet00.nif",
		qtyReq = 4,
		yieldID = "mc_scrap_dwemer",
		byproduct = {
			{ id = "mc_scrap_iron", yield = 6 }
					},
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_goblet10",
		nif = "m\\misc_dwrv_goblet10.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		byproduct = {
			{ id = "mc_scrap_iron", yield = 1 }
					},
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_pitcher00",
		nif = "m\\misc_dwrv_pitcher00.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		byproduct = {
			{ id = "mc_scrap_iron", yield = 4 }
					},
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_bowl00",
		nif = "m\\misc_dwrv_bowl00.nif",
		qtyReq = 4,
		yieldID = "mc_scrap_dwemer",
		byproduct = {
			{ id = "mc_scrap_iron", yield = 5 }
					},
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel dart",
		nif = "w\\W_dart_steel.NIF",
		wpnType = 11,
		qtyReq = 10,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_MetalBlank_01",
		nif = "Sky\\m\\Sky_Misc_Blank_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "mc_bucket01",
		nif = "mc\\mc_dwrv_bucket00.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "mc_torchholder01",
		nif = "mc\\mc_Torch_Ring_01.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "mc_torchholder02",
		nif = "mc\\mc_Torch_Ring_02.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "DarkBrotherhood Helm",
		nif = "a\\A_DarkBrotherhood_Helmet.NIF",
		qtyReq = 1,
		yieldID = "T_Dwe_ExplodoEye_01",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "BM riekling sword",
		nif = "w\\W_IceMsword2.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "BM_ice_minion_lance",
		nif = "w\\IceMspear.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "BM riekling sword_rusted",
		nif = "w\\W_IceMsword2.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Ayl_Regular_Dagger_01",
		nif = "pc\\w\\pc_w_ayl_dagger01.nif",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		byproduct = {
			{id = "mc_scrap_silver", yield = 1}
					},
		yieldCount = 3,
		taskTime = 0.5},

		{id = "T_Ayl_Regular_Longblade_01",
		nif = "pc\\w\\pc_w_ayl_blade02.nif",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		byproduct = {
			{id = "ingred_pearl_01", yield = 3}
					},
		yieldCount = 6,
		taskTime = 0.5},

		{id = "T_Ayl_Regular_Longbow_01",
		nif = "pc\\w\\pc_w_ayleid_bow.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Ayl_Regular_Shortblade_01",
		nif = "pc\\w\\pc_w_ayl_blade01.nif",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		byproduct = {
			{id = "ingred_pearl_01", yield = 3}
					},
		yieldCount = 4,
		taskTime = 0.5},

		{id = "T_Ayl_Regular_Spear_01",
		nif = "pc\\w\\pc_w_ayl_spear01.nif",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		yieldCount = 5,
		byproduct = {
			{id = "mc_scrap_iron", yield = 2}
					},
		taskTime = 0.2},

		{id = "T_Ayl_Regular_WarAxe_01",
		nif = "pc\\w\\pc_w_ayl_axe01.nif",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		yieldCount = 5,
		byproduct = {
			{id = "mc_scrap_iron", yield = 2}
					},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Broadsword_01",
		nif = "TR\\w\\tr_w_breton_bsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Claymore_01",
		nif = "TR\\w\\tr_w_breton_claymore.nif",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_iron", yield = 8}
					},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Dagger_01",
		nif = "TR\\w\\tr_w_breton_dagger.nif",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_iron", yield = 1}
					},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Longsword_01",
		nif = "TR\\w\\tr_w_breton_lsword.nif",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_iron", yield = 5}
					},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Shortsword_01",
		nif = "TR\\w\\tr_w_breton_ssword.nif",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_iron", yield = 3}
					},
		taskTime = 0.2},

		{id = "T_Bre_Fine_Dagger_01",
		nif = "sky\\w\\sky_bre_fine_dagger.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Adamant_Arrow_01",
		nif = "tr\\w\\tr_w_adamant_arrow.nif",
		qtyReq = 40,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Adamant_Bolt_01",
		nif = "tr\\w\\tr_w_adamant_bolt.nif",
		qtyReq = 40,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Adamant_DoubleAxe_02",
		nif = "tr\\w\\tr_w_adamant_baxe_uni.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 12,
		taskTime = 0.2},

		{id = "T_Com_Farm_Sledgehammer_01",
		nif = "sky\\m\\sky_Misc_Hammer_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Gold_Dagger_01",
		nif = "TR\\w\\TR_w_gold_dagger.nif",
		qtyReq = 1,
		yieldID = "Gold_001",
		yieldCount = 60,
		taskTime = 0.4},

		{id = "T_Com_Iron_GreatMace_01",
		nif = "tr\\w\\tr_w_iron_gmace_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Com_Iron_GSword_01",
		nif = "sky\\w\\sky_w_iron_gsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2},

		{id = "T_Com_Iron_Staff_01",
		nif = "tr\\w\\tr_w_iron_staff_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Com_Iron_Warpick_01",
		nif = "tr\\w\\tr_w_iron_wpick_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Com_Steel_Broadsword_01",
		nif = "tr\\w\\tr_w_steel_bsword_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Com_Steel_Longsword_01",
		nif = "tr\\w\\tr_w_steel_lsword_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Com_Steel_Shortsword_01",
		nif = "tr\\w\\tr_w_steel_sshort_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Com_Steel_Shortsword_02",
		nif = "tr\\w\\tr_w_steel_sshort_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Dae_Regular_Broadsword_01",
		nif = "tr\\w\\tr_w_daedric_bsword.nif",
		qtyReq = 1,
		yieldID = "mc_ingot_daedric",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 1},
			{id = "mc_scrap_iron", yield = 12}
			},
		taskTime = 0.2},

		{id = "T_Dae_Regular_GSword_01",
		nif = "tr\\w\\tr_w_daedra_claymore_g.nif",
		qtyReq = 1,
		yieldID = "mc_ingot_daedric",
		yieldCount = 8,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 15}
			},
		taskTime = 0.2},

		{id = "T_Dae_Regular_Halberd_01",
		nif = "tr\\w\\tr_w_daedra_halberd.nif",
		qtyReq = 1,
		yieldID = "mc_ingot_daedric",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_daesteel", yield = 2},
			{id = "mc_scrap_iron", yield = 16}
			},
		taskTime = 0.2},

		{id = "T_De_Ebony_Bow_01",
		nif = "tr\\w\\tr_w_ebony_bow.nif",
		qtyReq = 1,
		yieldID = "mc_ingot_ebony",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_De_Glass_Mace_01",
		nif = "tr\\w\\tr_w_glass_mace.nif",
		qtyReq = 1,
		yieldID = "mc_ingot_glass",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_De_Glass_Warhammer_01",
		nif = "tr\\w\\tr_w_glass_warhammer.nif",
		qtyReq = 1,
		yieldID = "mc_ingot_glass",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_De_Ind_BellHammer_01",
		nif = "tr\\w\\tr_w_ind_bell_ham.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 16,
		taskTime = 0.2},

		{id = "T_De_RedHero_CeremonialBlade_01",
		nif = "TR\\w\\TR_w_Red_Hero_Blade.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Dwe_Regular_Arrow_01",
		nif = "TR\\w\\tr_w_dwrv_arrow.nif",
		qtyReq = 40,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_BattleAxe_01",
		nif = "Sky\\w\\sky_direnni_axe_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_He_Direnni_Halberd_01",
		nif = "Sky\\w\\sky_direnni_axe_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_He_Direnni_Longsword_01",
		nif = "Sky\\w\\sky_direnni_sword_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_He_Direnni_Shortsword_01",
		nif = "Sky\\w\\sky_direnni_sword_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_Staff_01",
		nif = "Sky\\w\\sky_direnni_staff_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Legion_Katana_01",
		nif = "PC\\w\\pc_w_imp_katana.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Legion_Shortsword_01",
		nif = "PC\\w\\pc_w_imp_ssword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_Legion_WarAxe_01",
		nif = "PC\\w\\pc_w_imp_waraxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Silver_Halberd_01",
		nif = "tr\\w\\tr_w_silver_halberd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_Silver_Katana_01",
		nif = "tr\\w\\tr_w_silver_katana.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Silver_Longbow_01",
		nif = "tr\\w\\tr_w_silver_longbow.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Silver_WarHammer_01",
		nif = "tr\\w\\tr_w_silver_warhammer.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Nor_FineSteel_Seax_01",
		nif = "sky\\w\\sky_fine_steel_seax.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Huntsman_Shortsword_01",
		nif = "tr\\w\\tr_w_hunstman_shortsw.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Iron_Seax_01",
		nif = "TR\\w\\TR_w_seax_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Iron_Spear_01",
		nif = "sky\\w\\sky_nord_iron_spear.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Regular_Longsword_01",
		nif = "sky\\w\\sky_steel_longsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Iron_Seax_01",
		nif = "TR\\w\\TR_w_seax_iron.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 12,
		taskTime = 0.2},

		{id = "BM huntsman axe",
		nif = "w\\W_Huntsman_waraxe.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "BM huntsman war axe",
		nif = "w\\W_Huntsman_waraxeM.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2},

		{id = "T_Nor_Silver_Bow_01",
		nif = "tr\\w\\tr_w_nord_bow.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Steel_Waraxe_01",
		nif = "sky\\w\\sky_nord_steel_waraxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Nor_Steel_Warhammer_01",
		nif = "sky\\w\\sky_nord_steel_warham.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 12,
		taskTime = 0.2},

		{id = "T_Orc_Regular_WarAxeThooted_01",
		nif = "Sky\\w\\Sky_Orc_THD_Axe_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Rga_Steel_Saber_01",
		nif = "pc\\w\\pc_w_steel_saber.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_2hsword",
		nif = "pc\\w\\pc_rga_yoku_2hsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_Lsword_01",
		nif = "pc\\w\\pc_rga_yoku_lsword.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_Spear_01",
		nif = "pc\\w\\pc_rga_yoku_spear.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_Waraxe_01",
		nif = "pc\\w\\pc_rga_yoku_waraxe.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Tsa_Regular_Katana_01",
		nif = "pc\\w\\PC_w_tsa_katana01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Ayl_Saliache_Boots_01",
		nif = "pc\\a\\pc_a_ayl_boots_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 2}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_BracerL_01",
		nif = "pc\\a\\pc_a_ayl_bracer_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 1}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_BracerR_01",
		nif = "pc\\a\\pc_a_ayl_bracer_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 1}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Cuirass_01",
		nif = "pc\\a\\pc_a_ayl_cuir_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 3}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Greaves_01",
		nif = "pc\\a\\pc_a_ayl_greav_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 2}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Helm_01",
		nif = "pc\\a\\pc_a_ayl_helm_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 1}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_PauldronR_01",
		nif = "pc\\a\\pc_a_ayl_pauldr_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 1}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_PauldronL_01",
		nif = "pc\\a\\pc_a_ayl_pauldr_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {
			{id = "T_IngMine_Spinel_01", yield = 1}
					},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Shield_01",
		nif = "pc\\a\\pc_a_ayl_shield01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.3},

		{id = "T_Com_Steel_Helm_Open_02",
		nif = "pc\\a\\pc_a_steel_helm_o_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.3},

		{id = "T_De_NativeEbony_Boots_01",
		nif = "TR\\a\\Tr_a_NatEbon_Boot_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_Cuirass_01",
		nif = "TR\\a\\Tr_a_NatEbon_chest_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_iron", yield = 3}
					},
		taskTime = 0.4},

		{id = "T_De_NativeEbony_GauntletL_01",
		nif = "TR\\a\\Tr_a_NatEbon_hand_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_GauntletR_01",
		nif = "TR\\a\\Tr_a_NatEbon_hand_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_Greaves_01",
		nif = "TR\\a\\Tr_a_NatEbon_Grv_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 2,
		byproduct = {
			{id = "mc_scrap_iron", yield = 2}
					},
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmClosed_01",
		nif = "TR\\a\\Tr_a_NatEbon_Helm_C01.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmClosed_02",
		nif = "TR\\a\\Tr_a_NatEbon_Helm_C02.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_PauldronL_01",
		nif = "TR\\a\\Tr_a_NatEbon_Pauld_CL.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_PauldronR_01",
		nif = "TR\\a\\Tr_a_NatEbon_Pauld_CL.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmOpen_01",
		nif = "TR\\a\\Tr_a_NatEbon_Helm_O01.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmOpen_02",
		nif = "TR\\a\\Tr_a_NatEbon_Helm_O02.nif",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_Necrom_Cuirass_02",
		nif = "TR\\a\\TR_a_nec_cuirass_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.4},

		{id = "T_De_Necrom_GauntletL_01",
		nif = "TR\\a\\tr_a_nec_gaunt_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_Necrom_GauntletR_01",
		nif = "TR\\a\\tr_a_nec_gaunt_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_Dwe_Regular_ShieldTower_01",
		nif = "TR\\a\\TR_a_dwrv_twrshield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_iron", yield = 3}
					},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Boots",
		nif = "TR\\a\\tr_a_DwrvScrp_bootsGND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_iron", yield = 3}
					},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Bracer_L",
		nif = "TR\\a\\tr_a_DwrvScrp_bracer_w.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Bracer_R",
		nif = "TR\\a\\tr_a_DwrvScrp_bracer_w.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Cuirass",
		nif = "TR\\a\\tr_a_DwrvScrp_chestGND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 4,
		byproduct = {
			{id = "mc_scrap_iron", yield = 3}
					},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Greaves",
		nif = "TR\\a\\tr_a_DwrvScrp_grvs_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_iron", yield = 2}
					},
		taskTime = 0.3},

		{id = "T_Dwe_Scrap_helmet",
		nif = "TR\\a\\tr_a_DwrvScrp_helmet.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Pauldron_L",
		nif = "TR\\a\\tr_a_DwrvScrp_pld_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_iron", yield = 1}
					},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Pauldron_R",
		nif = "TR\\a\\tr_a_DwrvScrp_pld_GND.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_iron", yield = 1}
					},
		taskTime = 0.2},

		{id = "T_He_Direnni_Boots_01",
		nif = "Sky\\a\\sky_a_direnni_bt_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_He_Direnni_BracerL_01",
		nif = "Sky\\a\\sky_a_direnni_br_g.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_BracerR_01",
		nif = "Sky\\a\\sky_a_direnni_br_g.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_Cuirass_01",
		nif = "Sky\\a\\sky_a_direnni_cu_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		byproduct = {
			{id = "mc_scrap_silver", yield = 1}
					},
		taskTime = 0.4},

		{id = "T_He_Direnni_Greaves_01",
		nif = "Sky\\a\\sky_a_direnni_gr_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_He_Direnni_Helm_01",
		nif = "Sky\\a\\sky_a_direnni_he_g.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_PauldronL_01",
		nif = "Sky\\a\\sky_a_direnni_pl_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_PauldronR_01",
		nif = "Sky\\a\\sky_a_direnni_pl_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_01",
		nif = "pc\\a\\pc_a_chain_strid_c_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_02",
		nif = "pc\\a\\pc_a_chain_mass_c_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_03",
		nif = "pc\\a\\pc_a_chain_brum_c_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_04",
		nif = "pc\\a\\pc_a_chain_kvat_c_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_Helm_01",
		nif = "pc\\a\\pc_a_chain_strid_h_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_Helm_02",
		nif = "pc\\a\\pc_a_chain_mass_h_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},


		{id = "T_Imp_Chainmail_Helm_03",
		nif = "pc\\a\\pc_a_chain_brum_h_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},
		
		{id = "T_Imp_Chainmail_Helm_04",
		nif = "pc\\a\\pc_a_chain_kvat_h_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Ebony_Helmet_01",
		nif = "tr\\a\\tr_a_ImpEbon_Helm_01.nif",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		byproduct = {
			{id = "mc_scrap_iron", yield = 4}
					},
		taskTime = 0.2},

		{id = "T_Imp_Gold_Cuirass_01",
		nif = "tr\\a\\tr_a_gold_cuirass_gnd.nif",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 300,
		byproduct = {
			{id = "mc_scrap_iron", yield = 6}
					},
		taskTime = 4},

		{id = "T_Imp_Gold_Helm_01",
		nif = "tr\\a\\tr_a_gold_helm.nif",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 280,
		byproduct = {
			{id = "mc_scrap_iron", yield = 1}
					},
		taskTime = 2},

		{id = "T_Imp_Gold_PauldronL_01",
		nif = "tr\\a\\tr_a_gold_pauldron.nif",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 250,
		byproduct = {
			{id = "mc_scrap_iron", yield = 2}
					},
		taskTime = 2},

		{id = "T_Imp_Gold_PauldronR_01",
		nif = "tr\\a\\tr_a_gold_pauldron.nif",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 250,
		byproduct = {
			{id = "mc_scrap_iron", yield = 2}
					},
		taskTime = 2},

		{id = "T_Imp_GuardTown1_Boots_01",
		nif = "pc\\a\\pc_A_GuardBoots.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_Cuirass_01",
		nif = "pc\\a\\PC_A_Str_Cuirass_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.6},

		{id = "T_Imp_GuardTown1_GauntletL_01",
		nif = "pc\\a\\pc_a_str_gauntl_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_GauntletR_01",
		nif = "pc\\a\\pc_a_str_gauntl_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_Helm_01",
		nif = "pc\\a\\pc_A_GuardHelmGC_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_HelmAnv_01",
		nif = "pc\\a\\pc_A_GuardHelmAnv_hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_HelmStr_01",
		nif = "pc\\a\\pc_a_stirk_helm.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_HelmSut_01",
		nif = "pc\\a\\pc_A_GuardHelmSut_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_PauldrL_01",
		nif = "pc\\a\\pc_a_str_pauld.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_PauldrR_01",
		nif = "pc\\a\\pc_a_str_pauld.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_ShieldAnv_01",
		nif = "pc\\a\\pc_a_anvil_shield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_Boots_01",
		nif = "pc\\a\\pc_A_GuardBoots.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_Cuirass_01",
		nif = "pc\\a\\pc_A_Str_Cuirass_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.6},

		{id = "T_Imp_GuardTown2_GauntletL_01",
		nif = "pc\\a\\pc_a_str_gauntl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_GauntletR_01",
		nif = "pc\\a\\pc_a_str_gauntl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_Helm_01",
		nif = "pc\\a\\pc_a_str_gauntl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_HelmArt_01",
		nif = "pc\\a\\pc_A_GuardHelmArt_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_HelmBru_01",
		nif = "pc\\a\\pc_A_GuardHelmBru_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_HelmCho_01",
		nif = "pc\\a\\pc_A_GuardHelmCho_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_PauldrL_01",
		nif = "pc\\a\\pc_a_str_pauld_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_PauldrR_01",
		nif = "pc\\a\\pc_a_str_pauld_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_Boots_01",
		nif = "pc\\a\\pc_A_GuardBoots.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_Cuirass_01",
		nif = "pc\\a\\PC_A_Str_Cuirass_gnd.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.6},

		{id = "T_Imp_GuardTown3_GauntletL_01",
		nif = "pc\\a\\pc_a_str_gauntl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_GauntletR_01",
		nif = "pc\\a\\pc_a_str_gauntl.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_Helm_01",
		nif = "pc\\a\\pc_A_GuardHelmWW_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_HelmKva_01",
		nif = "pc\\a\\pc_A_GuardHelmKva_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_HelmSar_01",
		nif = "pc\\a\\pc_A_GuardHelmSar_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_HelmSkn_01",
		nif = "pc\\a\\pc_A_GuardHelmSkn_Hr.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_PauldrL_01",
		nif = "pc\\a\\pc_a_pauld_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_PauldrR_01",
		nif = "pc\\a\\pc_a_pauld_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Mananaut_Helm_01",
		nif = "pc\\a\\PC_a_Imp_MnautHelm_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {
			{id = "mc_fish_bladder", yield = 3}
					},
		taskTime = 0.4},

		{id = "T_Imp_Reman_Boots_01",
		nif = "pc\\a\\pc_a_reman_boots_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.4},

		{id = "T_Imp_Reman_BracerL_01",
		nif = "pc\\a\\pc_a_reman_bracer_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_BracerR_01",
		nif = "pc\\a\\pc_a_reman_bracer_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Cuirass_01",
		nif = "pc\\a\\pc_a_reman_cuir_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Greaves_01",
		nif = "pc\\a\\pc_a_reman_greav_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Helm_01",
		nif = "pc\\a\\pc_a_reman_helm_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_PauldronL_01",
		nif = "pc\\a\\pc_a_reman_pauldr_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Reman_PauldronR_01",
		nif = "pc\\a\\pc_a_reman_pauldr_g.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Shield_01",
		nif = "pc\\a\\pc_a_reman_shield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_Templar_ShieldTower_01",
		nif = "pc\\a\\PC_A_Templar_Shield.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Nor_Companion_Boots_01",
		nif = "Sky\\a\\Sky_A_Companion_BT_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.4},

		{id = "T_Nor_Companion_Cuirass_01",
		nif = "Sky\\a\\Sky_A_Companion_CU_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.4},

		{id = "T_Nor_Companion_GauntletL_01",
		nif = "Sky\\a\\Sky_A_Companion_GT_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Companion_GauntletR_01",
		nif = "Sky\\a\\Sky_A_Companion_GT_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Companion_Greaves_01",
		nif = "Sky\\a\\Sky_A_Companion_GR_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Nor_Companion_Helm_01",
		nif = "Sky\\a\\Sky_A_Companion_HE_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Companion_PauldronL_01",
		nif = "Sky\\a\\Sky_A_Companion_PL_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Orc_Regular_HelmOpen_01",
		nif = "TR\\a\\TR_a_orcish_helm_o.NIF",
		qtyReq = 1,
		yieldID = "mc_scrap_orichalcum",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Boots_01",
		nif = "Sky\\a\\Sky_A_Wormmouth_BT_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.4},

		{id = "T_Rea_Wormmouth_BracerL_01",
		nif = "Sky\\a\\Sky_A_Wormmouth_BR_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_BracerR_01",
		nif = "Sky\\a\\Sky_A_Wormmouth_BR_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Cuirass_01",
		nif = "Sky\\a\\Sky_A_Wormmouth_CU_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Greaves_01",
		nif = "Sky\\a\\Sky_A_Wormmouth_GR_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Helm_01",
		nif = "Sky\\a\\Sky_A_Wormmouth_HE_G",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_PauldronL_01",
		nif = "sky\\a\\sky_a_wormmouth_pl_g",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_PauldronR_01",
		nif = "sky\\a\\sky_a_wormmouth_pl_g",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rga_Alikr_Buckler",
		nif = "pc\\a\\pc_a_rga_alik_buck.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_De_Scales_01",
		nif = "TR\\m\\TR_misc_de_scales_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_De_Scales_02",
		nif = "TR\\m\\TR_misc_de_scales_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_SilverScales_01",
		nif = "TR\\m\\TR_misc_com_scales_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2},

		{id = "T_Imp_SilverScales_02",
		nif = "TR\\m\\TR_misc_com_scales_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_01",
		nif = "TR\\m\\TR_misc_com_weight_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 10,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_02",
		nif = "TR\\m\\TR_misc_com_weight_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_03",
		nif = "TR\\m\\TR_misc_com_weight_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_04",
		nif = "TR\\m\\TR_misc_com_weight_04.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_De_Weight_01",
		nif = "TR\\m\\TR_misc_de_weight_01.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_De_Weight_02",
		nif = "TR\\m\\TR_misc_de_weight_02.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_De_Weight_03",
		nif = "TR\\m\\TR_misc_de_weight_03.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_De_Weight_04",
		nif = "TR\\m\\TR_misc_de_weight_04.nif",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Javelin_01",
		nif = "pc\\w\\pc_w_reman_javelin.nif",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "centurion_projectile_dart",
		nif = "w\\W_DwarvenSphereDart.NIF",
		qtyReq = 12,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "mc_arrow_dwe",
		nif = "TR\\w\\tr_w_dwrv_arrow.nif",
		qtyReq = 12,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Regular_Bolt_01",
		nif = "TR\\w\\tr_w_dwrv_bolt.nif",
		qtyReq = 24,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Regular_Dart_01",
		nif = "w\\W_DwarvenSphereDart.NIF",
		qtyReq = 45,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},
	}

return scraplist