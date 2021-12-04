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
		qtyReq = 2,
		yieldID = "mc_scrap_adamantium",
		yieldCount = 3,
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
		yieldID = "mc_iron_ingot",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_Helm_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Guard_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Boots_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 11,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 7,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_Helm_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Steel_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_Boots_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "nordic_iron_cuirass",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 13,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "nordic_iron_helm",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_GauntletL_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_GauntletR_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Iron_PauldronR_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Boots_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Cuirass_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},

		{id = "nordic_ringmail_cuirass",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 8,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Greaves_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
		yieldCount = 4,
		taskTime = 0.2
		},
		
		{id = "T_Nor_Ringmail_Helmet_01",
		qtyReq = 1,
		yieldID = "mc_iron_ingot",
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
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass_bracer_left",
		qtyReq = 4,
		yieldID = "mc_glass_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "glass_bracer_right",
		qtyReq = 4,
		yieldID = "mc_glass_ingot",
		yieldCount = 3,
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
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass_pauldron_left",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass_pauldron_right",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
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

		{id = "T_Imp_Legion_BroadwordBroke_01",
		qtyReq = 1,
		yieldID = "mc_scrap_iron",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_Boots",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_Cuirass",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 6,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_BracerL",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_PauldronL",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "Tm_Ip_Ebony_BracerR",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Ebony_PauldronR",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
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
		qtyReq = 2,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_PauldronL_01",
		qtyReq = 1,
		yieldID = "mc_scrap_silver",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "T_Imp_Silver_BracerR_01",
		qtyReq = 2,
		yieldID = "mc_scrap_silver",
		yieldCount = 3,
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
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_01",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_02",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Com_Iron_Helm_Open",
		qtyReq = 2,
		yieldID = "mc_scrap_iron",
		yieldCount = 5,
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
		qtyReq = 2,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "orcish_bracer_right",
		qtyReq = 2,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
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
		qtyReq = 2,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_HelmOpen_01",
		qtyReq = 2,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
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

		{id = "dwemer_towershield",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
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

		{id = "T_Imp_Legion_ShortswordBroken_01",
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
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
		taskTime = 0.2
		},	

		{id = "dwarven spear",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 5,
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

		{id = "T_De_Ebony_Battleaxe",
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
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_DaiKatana_01",
		qtyReq = 1,
		yieldID = "mc_ebony_ingot",
		yieldCount = 19,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Halberd_02",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
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
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Shortsword_02",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},		
		
		{id = "ebony spear",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "ebony staff",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "T_De_Ebony_Tanto_01",
		qtyReq = 2,
		yieldID = "mc_ebony_ingot",
		yieldCount = 5,
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
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Spear_01",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
		taskTime = 0.2
		},

		{id = "glass staff",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_De_Glass_Tanto_01",
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 3,
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
		qtyReq = 2,
		yieldID = "mc_glass_ingot",
		yieldCount = 5,
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
		yieldCount = 5,
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
		qtyReq = 2,
		yieldID = "mc_scrap_orcish",
		yieldCount = 3,
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
		qtyReq = 2,
		yieldID = "mc_scrap_orcish",
		yieldCount = 3,
		taskTime = 0.2
		},
		
		{id = "T_Orc_Regular_Dagger_02",
		qtyReq = 2,
		yieldID = "mc_scrap_orcish",
		yieldCount = 5,
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

		{id = "T_Dwe_ExplodeoBody_01",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 4,
		taskTime = 0.2
		},

		{id = "T_Dwe_ExplodeoFlaps_01",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 3,
		taskTime = 0.2
		},

		{id = "T_Dwe_ExplodeoRotors_01",
		qtyReq=1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 2,
		taskTime = 0.2
		},

		{id = "misc_dwrv_mug00",
		qtyReq = 2,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_goblet00",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_goblet10",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 1,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_pitcher00",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
		yieldCount = 2,
		taskTime = 0.2
		},
		
		{id = "misc_dwrv_bowl00",
		qtyReq = 1,
		yieldID = "mc_scrap_dwemer",
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
		taskTime = 0.2}

	}

return scraplist