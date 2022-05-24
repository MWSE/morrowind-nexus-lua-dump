--[[ Scrapping-material listing -- scrapping metal items (weapons/armor)
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		
	local scraplist = {}
	scraplist = {
		{id = "adamantium boots",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 6,
		taskTime = 0.5
		},

		{id = "adamantium_bracer_left",
		qtyReq = 2,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.3
		},

		{id = "adamantium_bracer_right",
		qtyReq = 2,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.3
		},

		{id = "adamantium_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 1
		},

		{id = "adamantium_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 5,
		taskTime = 1
		},

		{id = "adamantium_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.25
		},

		{id = "addamantium_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 2,
		taskTime = 0.25
		},
		
		{id = "adamantium_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.1
		},

		{id = "adamantium_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
		taskTime = 0.1
		},

		{id = "BM_NordicMail_Boots",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 14,
		taskTime = 1
		},

		{id = "BM_NordicMail_gauntletL",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_gauntletR",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = .2
		},

		{id = "BM_NordicMail_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 7,
		taskTime = .2
		},

		{id = "BM_NordicMail_Helmet",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_PauldronL",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_PauldronR",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "BM_NordicMail_Shield",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "nordic_iron_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "nordic_iron_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "BM riekling lance",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "nordic_ringmail_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Helmet_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "daedric_boots",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "daedric_cuirass",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_HelmConsolat_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount =1,
		taskTime = 0.2
		},

		{id = "daedric_god_helm",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "T_Dae_Regular_HelmHumiliat_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_HelmHumiliat_02",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "daedric_fountain_helm",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "mc_daedric_clavicus",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_HelmRebellion_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "daedric_terrifying_helm",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "daedric_gauntlet_left",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "daedric_gauntlet_right",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "daedric_greaves",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "daedric_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "daedric_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "daedric_shield",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "daedric_towershield",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_ShieldTower_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Lord_Boots_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Lord_Helm_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Lord_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Lord_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Lord_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Lord_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "ebony_boots",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_bracer_left",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "ebony_bracer_right",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "ebony_closed_helm",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_De_Ebony_HelmOpen_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_cuirass",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 13,
		taskTime = 0.2
		},

		{id = "ebony_greaves",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "ebony_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "ebony_shield",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "ebony_towershield",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "glass_boots",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_bracer_left",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass_bracer_right",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass_cuirass",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "glass_greaves",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass_helm",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass_shield",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "glass_towershield",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "silver_dukesguard_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "silver_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "helsethguard_boots",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "helsethguard_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "helsethguard_gauntlet_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "helsethguard_gauntlet_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "helsethguard_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "helsethguard_helmet",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "helsethguard_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "helsethguard_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "imperial boots",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "imperial cuirass_armor",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "imperial_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "imperial helmet armor",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial left gauntlet",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial left pauldron",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "imperial right gauntlet",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial right pauldron",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "imperial shield",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Imp_Chain_Boots_01",
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
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "imperial_chain_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Chain_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial_chain_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Chain_GauntletR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "imperial_chain_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Imp_Legion_ShortswordBroke_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Imp_Legion_BroadswordBroke_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_Boots",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_Cuirass",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_BracerL",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_PauldronL",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_BracerR",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_PauldronR",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "silver_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Helm_Mask",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Cap_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Cap_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_BracerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_BracerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "indoril boots",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "indoril cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_De_Ordinator_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "indoril helmet",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "indoril left gauntlet",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "indoril pauldron left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril pauldron right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril right gauntlet",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "indoril shield",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_boots",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_cuirass",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 19,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_gauntlet_l",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_gauntlet_r",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_greaves",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 12,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_helmet",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_pauldron_l",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_pauldron_r",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "indoril_MH_guard_shield",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_CuirassCloak_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_De_Necrom_Shield_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColIron1_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "iron boots",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Boots_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "iron_bracer_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerL_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron_bracer_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_BracerR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Cuirass_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "iron_gauntlet_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "iron_gauntlet_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "iron_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Greaves_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "iron_helmet",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_Open",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronL_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Com_IronSpike_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "iron_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_PauldronR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_IronSpike_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "iron_shield",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_Aka_Regular_Shield_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "iron_towershield",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "newtscale_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Newtscale_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "orcish_boots",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "orcish_bracer_left",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "orcish_bracer_right",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "orcish_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 12,
		taskTime = 0.2
		},

		{id = "orcish_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "orcish_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_HelmOpen_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "orcish_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "orcish_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "orcish_towershield",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "orcish warhammer",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 15,
		taskTime = 0.5
		},

		{id = "orcish battle axe",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.5
		},
		
		{id = "T_Com_Chain_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Com_Chain_Cuirass_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Com_Chain_Cuirass_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_BracerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_BracerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_ColSteel1_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Rga_CrownGuard1_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "dragonscale_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "dragonscale_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_BarcerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_BarcerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Dragonscale_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "dragonscale_towershield",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_boots",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Cuirass_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "steel_gauntlet_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel_gauntlet_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "steel_helm",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Helm_Open_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronL_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronL_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_SteelSpike_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_PauldronR_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_SteelSpike_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_shield",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel_towershield",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "templar boots",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "templar bracer left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "templar bracer right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "templar_cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "templar_greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "templar_helmet_armor",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "templar_pauldron_left",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "templar_pauldron_right",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Templar_ShieldTower_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "mc_dwemer_boots",
		qtyReq=2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "mc_dwemer_bracer_left",
		qtyReq=2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_bracer_right",
		qtyReq=2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_cuirass",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 11,
		taskTime = 0.2
		},		

		{id = "mc_dwemer_greaves",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "mc_dwemer_helm",
		qtyReq=2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "mc_dwemer_pauldron_left",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_pauldron_right",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_shield",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "mc_dwemer_towershield",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "dwemer_boots",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "dwemer_bracer_left",
		qtyReq=2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_bracer_right",
		qtyReq=2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_cuirass",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 11,
		taskTime = 0.2
		},		

		{id = "dwemer_greaves",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "dwemer_helm",
		qtyReq=2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "dwemer_pauldron_left",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_pauldron_right",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "dwemer_shield",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "adamantium_axe",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 16,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_DoubleAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 16,
		taskTime = 0.2
		},
		
		{id = "T_Com_Adamant_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "adamantium_claymore",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 23,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Club_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Com_Adamant_Crossbow_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 0.2
		},		

		{id = "T_Com_Adamant_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_DaiKatana_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 18,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Gisern",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Halberd_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},
	
		{id = "T_Com_Adamant_Katana_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 15,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Bow_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "adamantium_mace",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Saber_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},		

		{id = "T_Com_Adamant_Scimitar_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "adamantium_shortsword",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "adamantium_spear",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "T_Com_Adamant_Staff_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 5,
		taskTime = 0.2
		},		

		{id = "T_Com_Adamant_Tanto_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 4,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_Star",
		qtyReq = 4,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_Wakizashi_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 10,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_WarAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 9,
		taskTime = 0.2
		},	

		{id = "T_Com_Adamant_Warhammer_01",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 21,
		taskTime = 0.2
		},	
		
		{id = "BM Huntsman axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "BM huntsman longsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "BM huntsman spear",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "BM Huntsman war axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_ThrowingAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "BM nordic silver axe",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "BM nordic silver battleaxe",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 12,
		taskTime = 0.2
		},

		{id = "BM nordic silver claymore",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "BM nordic silver dagger",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "BM nordic silver longsword",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "BM nordic silver mace",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},

		{id = "BM nordic silver shortsword",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_Imp_Silver_DaggerBroken_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Imp_Legion_ShortswordBroke_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Com_Iron_ThrowingKnife_01",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "daedric battle axe",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "daedric claymore",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 14,
		taskTime = 0.2
		},

		{id = "daedric club",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "daedric dagger",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "daedric dai-katana",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 20,
		taskTime = 0.2
		},

		{id = "T_Dae_Regular_Scimitar_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 15,
		taskTime = 0.2
		},		

		{id = "T_Dae_Regular_Fang_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "daedric katana",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "daedric long bow",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "T_Dae_Regular_Longspear_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},		

		{id = "T_Dae_Regular_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "daedric longsword",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "daedric mace",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "T_Dae_Regular_Naginata_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},		

		{id = "T_Dae_Regular_Saber_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Dae_Regular_Scimitar_02",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "daedric shortsword",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "daedric spear",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "daedric staff",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "daedric tanto",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Dae_Regular_Trident_01",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},		
		
		{id = "daedric wakizashi",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "daedric war axe",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "daedric warhammer",
		qtyReq = 1,
		yieldID = "mc_dae_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Com_DaedSteel_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 6,
		taskTime = 0.2
		},		

		{id = "T_Com_DaedSteel_Claymore_01",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 13,
		taskTime = 0.2
		},	

		{id = "T_Com_DaedSteel_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 2,
		taskTime = 0.2
		},	

		{id = "T_Com_DaedSteel_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 10,
		taskTime = 0.2
		},	

		{id = "T_Com_DaedSteel_Shortsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_daesteel",
		yieldCount = 5,
		taskTime = 0.2
		},	

		{id = "dwarven battle axe",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 10,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},			
		
		{id = "dwarven claymore",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 12,
		taskTime = 0.2
		},	

		{id = "dwarven crossbow",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2
		},			
		
		{id = "dwarven halberd",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Junkmace_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Longspear_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 6,
		taskTime = 0.2
		},	
		
		{id = "dwarven mace",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},	

		{id = "T_Dwe_Regular_Staff_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},			
		
		{id = "dwarven shortsword",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 2,
		taskTime = 0.2
		},	

		{id = "dwarven spear",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 2,
		taskTime = 0.2
		},			
		
		{id = "dwarven war axe",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 4,
		taskTime = 0.2
		},	

		{id = "dwarven warhammer",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},	

		{id = "T_De_Ebony_Halberd_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Battleaxe_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "ebony broadsword",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Claymore_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 14,
		taskTime = 0.2
		},		

		{id = "T_De_Ebony_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_DaiKatana_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 19,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Halberd_02",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Katana_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "ebony longsword",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "ebony mace",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "Ebony Scimitar",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "ebony shortsword",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Shortsword_02",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},		
		
		{id = "ebony spear",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "ebony staff",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Tanto_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "ebony throwing star",
		qtyReq = 10,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},			

		{id = "T_De_Ebony_Wakizashi_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "ebony war axe",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Warhammer_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},		

		{id = "T_De_Ebony_Scythe",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_BattleAxe_01",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "glass claymore",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "glass dagger",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_DaiKatana_01",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Katana_01",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass halberd",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass longsword",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_De_UNI_GlassShortsword",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Spear_01",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass staff",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Tanto_01",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass throwing knife",
		qtyReq = 5,
		yieldID = "ingred_raw_glass_01",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "glass throwing star",
		qtyReq = 10,
		yieldID = "ingred_raw_glass_01",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Wakizashi_01",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "glass war axe",
		qtyReq = 1,
		yieldID = "mc_glass_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Cleaver_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Knife_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Knife_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Var_Knife_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "imperial broadsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Broadsword_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Broadsword_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "imperial shortsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "T_Imp_Legion_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_RoyalLongsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Legion_Saber_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "iron battle axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "iron broadsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Broadsword_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Broadsword_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "iron claymore",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "iron club",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron dagger",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Dagger_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron fork",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "iron halberd",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Hoe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "Iron Long Spear",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron longsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "iron mace",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Morningstar_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Pitchfork_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron saber",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Saber_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Saber_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Saber_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Scimitar_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Scythe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "iron shortsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Shovel_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron spear",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron tanto",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Tanto_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron throwing knife",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_ThrowingKnife_02",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Farm_Trovel_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "iron wakizashi",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "iron war axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_WarAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "iron warhammer",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "miner's pick",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Rea_Regular_Halberd_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Rea_Regular_WarAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Rea_Regular_Warhammer_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_WarAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},

		{id = "nordic battle axe",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_BattleAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 21,
		taskTime = 0.2
		},

		{id = "nordic broadsword",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "nordic claymore",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 14,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Seax_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Shortsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Spear_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_Warhammer_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 16,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Orn_ThrowingAxe_01",
		qtyReq = 8,
		yieldID = "mc_scrap_orcish",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "Orcish warhammer",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 14,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Bow_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "Orcish battle axe",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Claymore_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Cleaver_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Halberd_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Mace_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 10,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Dagger_02",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Spear_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Spear_02",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_BattleAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orcish",
		yieldCount = 12,
		taskTime = 0.2
		},
		
		{id = "silver claymore",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "silver dagger",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Dagger_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "silver longsword",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Mace_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Mace_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Saber_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_Saber_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "silver shortsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "silver spear",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_2HMace",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "silver staff",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "silver throwing star",
		qtyReq = 5,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "silver war axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "steel battle axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},

		{id = "steel broadsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "steel claymore",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 11,
		taskTime = 0.2
		},

		{id = "steel club",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "steel crossbow",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel dagger",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel dai-katana",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel halberd",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel katana",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2
		},

		{id = "steel longbow",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel longsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel mace",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},

		{id = "steel saber",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Scimitar_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel shortsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "steel spear",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "steel staff",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel tanto",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel throwing knife",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Com_Steel_Knife_01",
		qtyReq = 8,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel throwing star",
		qtyReq = 12,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel wakizashi",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "steel war axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "steel warhammer",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_gear00",
		qtyReq = 1,
		yieldID = "ingred_scrap_metal_01",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "misc_com_silverware_knife",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareKnife_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_com_silverware_fork",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareFork_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_com_silverware_spoon",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareSpoon_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareBottle_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "Misc_Imp_Silverware_Bowl",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverBowl_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverBowl_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_cup",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "Misc_Imp_Silverware_Cup_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareCup_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareCup_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareCup_03",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareDish_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareDish_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverGoblet_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_pitcher",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "rrfm_silver_pitcher",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_plate_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_plate_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "misc_imp_silverware_plate_03",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
			
		{id = "T_Imp_SilverWarePlate_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_03",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_04",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_05",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePlate_06",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverPlate_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverPlate_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverPlate_03",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWarePot_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_SilverWareVase_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverVase_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_SilverVase_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "misc_com_metal_goblet_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_goblet_02",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_tankard_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Imp_TankardNavy_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "Misc_Com_Pitcher_Metal_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_03",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_04",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_05",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "misc_com_metal_plate_07",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "T_Imp_SilverWareTankard_01",
		qtyReq = 2,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_black",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_blue",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_green",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_orange",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_purple",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_red",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_white",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_1sil_yellow",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "TR_m3_i3_316_Com_Candle_14_off",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_03",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_03_64",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_08",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_08_64",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_14",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_14_77",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_15",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_black",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_blue",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_green",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_orange",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_purple",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_red",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_white",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "mc_candle_3sil_yellow",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10_off",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10_64",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "light_com_candle_10_128",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_16",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "Light_Com_Candle_16_77",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Dwe_Regular_ShieldTower_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "misc_dwrv_mug00",
		qtyReq = 7,
		yieldID = "mc_scrap_dwemer",
		byproduct = { id = "mc_scrap_iron", yield = 5 },
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_goblet00",
		qtyReq = 4,
		yieldID = "mc_scrap_dwemer",
		byproduct = { id = "mc_scrap_iron", yield = 6 },
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_goblet10",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		byproduct = { id = "mc_scrap_iron", yield = 1 },
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_pitcher00",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		byproduct = { id = "mc_scrap_iron", yield = 4 },
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_bowl00",
		qtyReq = 4,
		yieldID = "mc_scrap_dwemer",
		byproduct = { id = "mc_scrap_iron", yield = 5 },
		yieldCount = 1,
		taskTime = 0.2
		},

		{id = "steel dart",
		qtyReq = 10,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_MetalPiece_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Com_MetalPiece_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Com_MetalPiece_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 15,
		taskTime = 0.2},

		{id = "T_Com_MetalPiece_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Com_MetalBlank_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "mc_bucket01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "mc_torchholder01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "mc_torchholder02",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "DarkBrotherhood Helm",
		qtyReq = 1,
		yieldID = "T_Dwe_ExplodoEye_01",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "BM riekling sword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "BM_ice_minion_lance",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "BM riekling sword_rusted",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Ayl_Regular_Dagger_01",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		byproduct = {id = "mc_scrap_silver", yield = 1},
		yieldCount = 3,
		taskTime = 0.5},

		{id = "T_Ayl_Regular_Longblade_01",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		byproduct = {id = "ingred_pearl_01", yield = 3},
		yieldCount = 6,
		taskTime = 0.5},

		{id = "T_Ayl_Regular_Longbow_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Ayl_Regular_Shortblade_01",
		qtyReq = 1,
		yieldID = "ingred_pearl_01",
		byproduct = {id = "ingred_pearl_01", yield = 3},
		yieldCount = 4,
		taskTime = 0.5},

		{id = "T_Ayl_Regular_Spear_01",
		qtyReq = 1,
		yieldID = "ingread_pearl_01",
		yieldCount = 5,
		byproduct = {id = "mc_scrap_iron", yield = 2},
		taskTime = 0.2},

		{id = "T_Ayl_Regular_WarAxe_01",
		qtyReq = 1,
		yieldID = "ingread_pearl_01",
		yieldCount = 5,
		byproduct = {id = "mc_scrap_iron", yield = 2},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Claymore_01",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {id = "mc_scrap_iron", yield = 8},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Dagger_01",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {id = "mc_scrap_iron", yield = 1},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Longsword_01",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {id = "mc_scrap_iron", yield = 5},
		taskTime = 0.2},

		{id = "T_Bre_Artisan_Shortsword_01",
		qtyReq = 1,
		yieldID = "TR_m1_Q_Ingred_Topaz",
		yieldCount = 1,
		byproduct = {id = "mc_scrap_iron", yield = 3},
		taskTime = 0.2},

		{id = "T_Bre_Fine_Dagger_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Adamant_Arrow_01",
		qtyReq = 40,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Adamant_Bolt_01",
		qtyReq = 40,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Adamant_DoubleAxe_02",
		qtyReq = 1,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 12,
		taskTime = 0.2},

		{id = "T_Com_Farm_Sledgehammer_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Com_Gold_Dagger_01",
		qtyReq = 1,
		yieldID = "Gold_001",
		yieldCount = 60,
		taskTime = 0.4},

		{id = "T_Com_Iron_GreatMace_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Com_Iron_GSword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 7,
		taskTime = 0.2},

		{id = "T_Com_Iron_Staff_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Com_Iron_Warpick_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Com_Steel_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Com_Steel_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Com_Steel_Shortsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Com_Steel_Shortsword_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Dae_Regular_Broadsword_01",
		qtyReq = 1,
		yieldID = "mc_ingot_daedric",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Dae_Regular_GSword_01",
		qtyReq = 1,
		yieldID = "mc_ingot_daedric",
		yieldCount = 8,
		taskTime = 0.2},

		{id = "T_Dae_Regular_Halberd_01",
		qtyReq = 1,
		yieldID = "mc_ingot_daedric",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_De_Ebony_Bow_01",
		qtyReq = 1,
		yieldID = "mc_ingot_ebony",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_De_Glass_Mace_01",
		qtyReq = 1,
		yieldID = "mc_ingot_glass",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_De_Glass_Shortsword_01",
		qtyReq = 1,
		yieldID = "mc_ingot_glass",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_De_Glass_Warhammer_01",
		qtyReq = 1,
		yieldID = "mc_ingot_glass",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_De_Ind_BellHammer_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 16,
		taskTime = 0.2},

		{id = "T_De_RedHero_CeremonialBlade_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Dwe_Regular_Arrow_01",
		qtyReq = 40,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_BattleAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_He_Direnni_Halberd_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_He_Direnni_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_He_Direnni_Shortsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_Staff_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Legion_Katana_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Legion_Shortsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_Legion_WarAxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Silver_Halberd_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_Silver_Katana_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Silver_Longbow_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Silver_WarHammer_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Nor_FineSteel_Seax_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Huntsman_Shortsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Iron_Seax_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Iron_Spear_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Regular_Longsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Iron_Seax_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 12,
		taskTime = 0.2},

		{id = "BM huntsman axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "BM huntsman war axe",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 9,
		taskTime = 0.2},

		{id = "T_Nor_Silver_Bow_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Steel_Waraxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Nor_Steel_Warhammer_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 12,
		taskTime = 0.2},

		{id = "T_Orc_Regular_WarAxeThooted_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Rga_Steel_Saber_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_2hsword",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_Lsword_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_Spear_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Rga_Yoku_Waraxe_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Tsa_Regular_Katana_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Ayl_Saliache_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 2},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_BracerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 1},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_BracerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 1},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 3},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 2},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 1},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 1},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {id = "T_IngMine_Spinel_01", yield = 1},
		taskTime = 0.3},

		{id = "T_Ayl_Saliache_Shield_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.3},

		{id = "T_Com_Steel_Helm_Open_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.3},

		{id = "T_De_NativeEbony_Boots_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 4,
		byproduct = {id = "mc_scrap_iron", yield = 3},
		taskTime = 0.4},

		{id = "T_De_NativeEbony_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 2,
		byproduct = {id = "mc_scrap_iron", yield = 2},
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmClosed_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmClosed_02",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmOpen_01",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_NativeEbony_HelmOpen_02",
		qtyReq = 1,
		yieldID = "mc_Ebony_Ingot",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_Necrom_Cuirass_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.4},

		{id = "T_De_Necrom_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_De_Necrom_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.4},

		{id = "T_Dwe_Regular_ShieldTower_01",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		byproduct = {id = "mc_scrap_iron", yield = 3},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Boots",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		byproduct = {id = "mc_scrap_iron", yield = 3},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Bracer_L",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Bracer_R",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Cuirass",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 4,
		byproduct = {id = "mc_scrap_iron", yield = 3},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Greaves",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		byproduct = {id = "mc_scrap_iron", yield = 2},
		taskTime = 0.3},

		{id = "T_Dwe_Scrap_helmet",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Pauldron_L",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		byproduct = {id = "mc_scrap_iron", yield = 1},
		taskTime = 0.2},

		{id = "T_Dwe_Scrap_Pauldron_R",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		byproduct = {id = "mc_scrap_iron", yield = 1},
		taskTime = 0.2},

		{id = "T_He_Direnni_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_He_Direnni_BracerL_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_BracerR_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		byproduct = {id = "mc_scrap_silver", yield = 1},
		taskTime = 0.4},

		{id = "T_He_Direnni_BracerL_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_He_Direnni_Helm_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_He_Direnni_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_cuirass_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Chainmail_Helm_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},


		{id = "T_Imp_Chainmail_Helm_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},
		
		{id = "T_Imp_Chainmail_Helm_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_boots_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_boots_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_boots_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Cuirass_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Cuirass_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Cuirass_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_GauntletL_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_GauntletL_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_GauntletL_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_GauntletR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_GauntletR_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_GauntletR_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Greaves_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Greaves_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Greaves_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Helm_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Helm_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_Helm_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronL_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronL_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronL_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronR_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronR_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron1_PauldronR_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron2_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_ColIron2_BracerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron2_BracerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_ColIron2_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.2},

		{id = "T_Imp_ColIron2_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.2},

		{id = "T_Imp_ColIron2_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColIron2_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_Boots_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.4},

		{id = "T_Imp_ColSteel1_Boots_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.4},

		{id = "T_Imp_ColSteel1_Boots_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 6,
		taskTime = 0.4},

		{id = "T_Imp_ColSteel1_BracerL_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_BracerL_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_BracerL_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_BracerR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_BracerR_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_BracerR_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_Cuirass_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.4},

		{id = "T_Imp_ColSteel1_Cuirass_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.4},

		{id = "T_Imp_ColSteel1_Cuirass_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 8,
		taskTime = 0.4},

		{id = "T_Imp_ColSteel1_Greaves_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_Greaves_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_Greaves_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_Helm_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_Helm_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_Helm_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_PauldronL_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_PauldronL_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_PauldronL_04",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_PauldronR_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_ColSteel1_PauldronR_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_Ebony_Helmet_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 1,
		byproduct = {id = "mc_scrap_iron", yield = 4},
		taskTime = 0.2},

		{id = "T_Imp_Gold_Cuirass_01",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 300,
		byproduct = {id = "mc_scrap_iron", yield = 6},
		taskTime = 4},

		{id = "T_Imp_Gold_Helm_01",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 280,
		byproduct = {id = "mc_scrap_iron", yield = 1},
		taskTime = 2},

		{id = "T_Imp_Gold_PauldronL_01",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 250,
		byproduct = {id = "mc_scrap_iron", yield = 2},
		taskTime = 2},

		{id = "T_Imp_Gold_PauldronR_01",
		qtyReq = 1,
		yieldID = "gold_001",
		yieldCount = 250,
		byproduct = {id = "mc_scrap_iron", yield = 2},
		taskTime = 2},

		{id = "T_Imp_GuardTown1_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.6},

		{id = "T_Imp_GuardTown1_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_HelmAnv_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_HelmStr_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_HelmSut_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_PauldrL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_PauldrR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown1_ShieldAnv_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.6},

		{id = "T_Imp_GuardTown2_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_HelmArt_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_HelmBru_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_HelmCho_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_PauldrL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown2_PauldrR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.6},

		{id = "T_Imp_GuardTown3_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_HelmKva_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_HelmSar_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_HelmSkn_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_PauldrL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_GuardTown3_PauldrR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Mananaut_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		byproduct = {id = "mc_fish_bladder", yield = 3},
		taskTime = 0.4},

		{id = "T_Imp_Reman_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.4},

		{id = "T_Imp_Reman_BracerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_BracerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Reman_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Shield_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Imp_Templar_ShieldTower_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Nor_Companion_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.4},

		{id = "T_Nor_Companion_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.4},

		{id = "T_Nor_Companion_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Companion_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Companion_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Nor_Companion_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Nor_Companion_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Nor_Companion_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Orc_Regular_HelmOpen_01",
		qtyReq = 1,
		yieldID = "mc_scrap_orichalcum",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Boots_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.4},

		{id = "T_Rea_Wormmouth_BracerL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_BracerR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 3,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_Helm_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rea_Wormmouth_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Rga_Alikr_Buckler",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_De_Scales_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_De_Scales_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "T_Imp_SilverScales_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2},

		{id = "T_Imp_SilverScales_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 7,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 10,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_02",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_03",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_Imp_SilverWeight_04",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_De_Weight_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2},

		{id = "T_De_Weight_02",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 2,
		taskTime = 0.2},

		{id = "T_De_Weight_03",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_De_Weight_04",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Imp_Reman_Javelin_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 4,
		taskTime = 0.2},

		{id = "centurion_projectile_dart",
		qtyReq = 12,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "mc_arrow_dwe",
		qtyReq = 12,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Regular_Bolt_01",
		qtyReq = 24,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},

		{id = "T_Dwe_Regular_Dart_01",
		qtyReq = 45,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2},
	}

return scraplist