local defaultConfig = {
	modEnabled = true,
	knowsPrice = 25,
	knowsSpecialization = 25,
	knowsExport = 50,
	canInvest = 75,
	canTradeWithEveryone = 100,
	canBarterEquipped = 100,
	sdModifier = 25,
	restockTime = 1,
	removeBought = true,
	forbidden = {},
	smuggler = {},
    ["Grazelands Region"] = {
		export = {
			ingred_raw_glass_01 = true,
			ingred_hackle_lo_01 = true,
			ingred_stoneflower_01 = true,
			ingred_wickwheat_01 = true,
			ingred_shalk_resin_01 = true,
			ingred_scuttle_01 = true,
			AB_IngFood_ScuttlePie = true,
			AB_IngFlor_TelvanniResin = true,
			AB_IngCrea_GuarMeat_01 = true,
			ingred_guar_hide_01 = true,
		},
		import = {
			["sc_paper plain"] = true,
			ashfall_firewood = true,
			AB_sc_Blank = true,
			AB_sc_BlankBargain = true,
			AB_sc_BlankCheap = true,
			AB_sc_BlankExclusive = true,
			AB_sc_BlankQuality = true,
		}
    }, 
    ["West Gash Region"] = {
		export = {	
			ingred_raw_ebony_01 = true,
			ingred_bittergreen_01 = true,
			AB_IngFlor_BgSlime_01 = true,
			ingred_chokeweed_01 = true,
			ingred_green_lichen_01 = true,
			ingred_kresh_fiber_01 = true,
			ingred_roobrush_01 = true,
			ingred_muck_01 = true,
			ingred_stoneflower_01 = true,
			potion_local_liquor_01  = true
		},
		import = {
			AB_w_EggminerHook = true,
			AB_a_EggminerHelm = true,
		}
    },
    ["Ashlands Region"] = {
		export = {
			ingred_raw_glass_01 = true,
			ingred_raw_ebony_01 = true,
			ingred_diamond_01 = true,
			ingred_fire_fern_01 = true,
			ingred_red_lichen_01 = true,
			ingred_scathecraw_01 = true,
			ingred_trama_root_01 = true,
			ingred_shalk_resin_01 = true,
			ingred_scuttle_01 = true,
			AB_IngFood_ScuttlePie = true,
			ingred_ash_salts_01 = true,
			AB_IngCrea_GuarMeat_01 = true,
			ingred_guar_hide_01 = true,
		},
		import = {
			ashfall_firewood = true,
			ingred_bread_01 = true,
			p_cure_blight_s = true,
			AB_w_EggminerHook = true,
			AB_a_EggminerHelm = true,
		}
    },
	
	["Red Mountain Region"] = {
		export = {
			ingred_raw_glass_01 = true,
			ingred_raw_ebony_01 = true,
			ingred_diamond_01 = true,
			ingred_fire_fern_01 = true,
			ingred_red_lichen_01 = true,
			ingred_scathecraw_01 = true,
			ingred_trama_root_01 = true,
			ingred_shalk_resin_01 = true,
			ingred_scuttle_01 = true,
			AB_IngFood_ScuttlePie = true,
			ingred_ash_salts_01 = true,
			AB_IngCrea_GuarMeat_01 = true,
			ingred_guar_hide_01 = true,
		},
		import = {
			ashfall_firewood = true,
			ingred_bread_01 = true,
			p_cure_blight_s = true,
		}
    },
	
    ["Bitter Coast Region"] = {
		export = {
			ashfall_backpack_n = true,
			ingred_netch_leather_01 = true,
			ingred_bungler_bane_01 = true,
			ingred_draggle_tail_01 = true,
			ingred_hypha_facia = true,
			ingred_luminous_russula_01 = true,
			ingred_slough_fern_01 = true,
			ingred_violet_coprinus_01 = true,
			ingred_pearl_01 = true,
		},
		import = {
			AB_w_ToolFishingNet = true,
			T_Rga_FishingSpear_01 = true,
			p_cure_common_s = true,
		}
    },
    ["Ascadian Isles Region"] = {
		export = {
			ingred_netch_leather_01 = true,
			ashfall_backpack_n = true,
			ingred_ash_yam_01 = true,
			ingred_black_anther_01 = true,
			ingred_comberry_01 = true,
			potion_comberry_brandy_01 = true,
			potion_comberry_wine_01 = true,
			ingred_corkbulb_01 = true,
			ingred_gold_canet_01 = true,
			ingred_heather_01 = true,
			ingred_marshmerrow_01 = true,
			ingred_saltrice_01 = true,
			AB_IngFood_SaltriceBread = true,
			Potion_Local_Brew_01 = true,
			ingred_willow_flower_01 = true,
			AB_IngCrea_GuarMeat_01 = true,
			ingred_guar_hide_01 = true,
		},
		import = {
			AB_w_ToolHandscythe00 = true,
			AB_w_ToolHandscythe01 = true,
			AB_w_ToolScythe = true,
		}
    },
    ["Molag Amur Region"] = {
		export = {
			ingred_fire_fern_01 = true,
			food_kwama_egg_01 = true,
			food_kwama_egg_02 = true,
			ingred_scathecraw_01 = true,
			ingred_trama_root_01 = true,
			ingred_shalk_resin_01 = true,
			ingred_scuttle_01 = true,
			AB_IngFood_ScuttlePie = true
		},
		import = {
			ashfall_firewood = true,
			ingred_bread_01 = true,
			AB_w_EggminerHook = true,
			AB_a_EggminerHelm = true,
		}
    },
    ["Azura's Coast Region"] = {
		export = {
			ingred_black_anther_01 = true,
			ingred_pearl_01 = true,
			ingred_kresh_fiber_01 = true,
			ingred_marshmerrow_01 = true,
			ingred_muck_01 = true,
			ingred_saltrice_01 = true,
			AB_IngFood_SaltriceBread = true,
			Potion_Local_Brew_01 = true,
			AB_IngFlor_TelvanniResin = true,
		},
		import = {
			["sc_paper plain"] = true,
			ashfall_firewood = true,
			AB_sc_Blank = true,
			AB_sc_BlankBargain = true,
			AB_sc_BlankCheap = true,
			AB_sc_BlankExclusive = true,
			AB_sc_BlankQuality = true,
		}
    },
    ["Sheogorad Region"] = {
		export = {
			ingred_black_anther_01 = true,
			ingred_gold_canet_01 = true,
			ingred_green_lichen_01 = true,
			ingred_pearl_01 = true,
			ingred_kresh_fiber_01 = true,
		},
		import = {
			ashfall_firewood = true,
		}
    },
	Solstheim = {
		export = {
			ingred_raw_ebony_01 = true,
			ingred_bear_pelt = true,
			ingred_boar_leather = true,
			ingred_belladonna_01 = true,
			ingred_belladonna_02 = true,
			ingred_holly_01 = true,
			ingred_horker_tusk_01 = true,
			ashfall_backpack_b = true,
			ashfall_backpack_w = true,
			ashfall_firewood = true,
			potion_nord_mead = true,
			T_IngFood_MeatHorker_01
		},
		import = {
			potion_cyro_brandy_01 = true,
			Potion_Cyro_Whiskey_01 = true,
		}
	},
	["Ald-ruhn"] = {
		export = {
			AB_a_BonemLightBoots = true,
			AB_a_BonemLightBracerL = true,
			AB_a_BonemLightBracerR = true,
			AB_a_BonemLightCuirass = true,
			AB_a_BonemLightGreaves = true,
			AB_a_BonemLightHelm = true,
			AB_a_BonemLightPaulL = true,
			AB_a_BonemLightPaulR = true,
			AB_a_IronDeBoots = true,
			AB_a_IronDeCuirass = true,
			AB_a_IronDeHelm = true,
			AB_a_IronDePldLeft = true,
			AB_a_IronDePldRight = true,
			["bonemold_gah-julan_cuirass"] = true,
			["bonemold_gah-julan_helm"] = true,
			["bonemold_gah-julan_pauldron_l"] = true,
			["bonemold_gah-julan_pauldron_r"] = true,
			["bonemold_tshield_redoranguard"] = true,
		},
		import = {
			-- Non-native armor and weapons
			["BM bear boots"] = true,
			["BM bear cuirass"] = true,
			["BM bear greaves"] = true,
			["BM Bear Helmet"] = true,
			["bm bear left gauntlet"] = true,
			["BM bear right gauntlet"] = true,
			["BM Bear left Pauldron"] = true,
			["BM bear right pauldron"] = true,
			["BM bear shield"] = true,
			["BM wolf boots"] = true,
			["BM wolf cuirass"] = true,
			["BM wolf greaves"] = true,
			["bm wolf left gauntlet"] = true,
			["BM wolf right gauntlet"] = true,
			["BM Wolf Left Pauldron"] = true,
			["BM wolf right pauldron"] = true,
			["BM wolf shield"] = true,
			BM_bear_boots_snow = true,
			BM_bear_cuirass_snow = true,
			BM_bear_greaves_snow = true,
			BM_bear_helmet_snow = true,
			BM_bear_left_gauntlet_snow = true,
			BM_Bear_left_Pauldron_snow = true,
			BM_bear_right_gauntlet_snow = true,
			BM_bear_right_pauldron_snow = true,
			BM_Ice_Boots = true,
			BM_Ice_cuirass = true,
			BM_Ice_gauntletL = true,
			BM_Ice_gauntletR = true,
			BM_Ice_greaves = true,
			BM_Ice_Helmet = true,
			BM_Ice_PauldronL = true,
			BM_Ice_PauldronR = true,
			BM_Ice_Shield = true,
			BM_NordicMail_Boots = true,
			BM_NordicMail_cuirass = true,
			BM_NordicMail_gauntletL = true,
			BM_NordicMail_gauntletR = true,
			BM_NordicMail_greaves = true,
			BM_NordicMail_Helmet = true,
			BM_NordicMail_PauldronL = true,
			BM_NordicMail_PauldronR = true,
			BM_NordicMail_Shield = true,
			BM_wolf_boots_snow = true,
			BM_wolf_cuirass_snow = true,
			BM_wolf_greaves_snow = true,
			BM_wolf_helmet_snow = true,
			BM_wolf_left_gauntlet_snow = true,
			BM_wolf_left_pauldron_snow = true,
			BM_wolf_right_gauntlet_snow = true,
			BM_wolf_right_pauldron_snow = true,
			ingred_raw_Stalhrim_01 = true,
			T_Com_MetalPieceIron_01 = true,
			T_Com_MetalPieceSteel_01 = true,
		}
	},
	Balmora = {
		export = {
			["bonemold_armun-an_cuirass"] = true,
			["bonemold_armun-an_helm"] = true,
			["bonemold_armun-an_pauldron_l"] = true,
			["bonemold_armun-an_pauldron_r"] = true,
			["bonemold_tshield_hlaaluguard"] = true,
			potion_skooma_01 = true,
		},
		import = {
			T_He_DirenniScales_01 = true,
			T_Imp_SilverScales_01 = true,
			T_Imp_SilverScales_02 = true,
		}
	},
	Suran = {
		export = {
			["bonemold_armun-an_cuirass"] = true,
			["bonemold_armun-an_helm"] = true,
			["bonemold_armun-an_pauldron_l"] = true,
			["bonemold_armun-an_pauldron_r"] = true,
			["bonemold_tshield_hlaaluguard"] = true,
			potion_skooma_01 = true,
		},
		import = {
			T_He_DirenniScales_01 = true,
			T_Imp_SilverScales_01 = true,
			T_Imp_SilverScales_02 = true,
		}
	},
	Caldera = {
		export = {
		},
		import = {
		}
	},
	["Khuul"] = {
		export = {
		},
		import = {
			AB_w_ToolFishingNet = true,
			T_Rga_FishingSpear_01 = true,
			p_cure_common_s = true,
		}
	},
	["Ald Velothi"] = {
		export = {
		},
		import = {
			AB_w_ToolFishingNet = true,
			T_Rga_FishingSpear_01 = true,
			p_cure_common_s = true,
		}
	},
	["Gnisis"] = {
		export = {
		},
		import = {
		}
	},
	["Hla Oad"] = {
		export = {
		},
		import = {
		}
	},
	["Gnaar Mok"] = {
		export = {
		},
		import = {
		}
	},
	["Seyda Neen"] = {
		export = {
		},
		import = {
		}
	},
	["Tel Branora"] = {
		export = {
			bonemold_tshield_telvanniguard = true,
			cephalopod_helm = true,
			AB_a_CephHelmOpen = true,
			AB_a_CephPauldronLeft = true,
			AB_a_CephPauldronRight = true,
			dust_adept_helm = true,
			mole_crab_helm = true,
			potion_t_bug_musk_01 = true,
		},
		import = {
			food_kwama_egg_01 = true,
			food_kwama_egg_02 = true,
			misc_uniq_egg_of_gold = true,
		}
	},
	["Tel Aruhn"] = {
		export = {
			bonemold_tshield_telvanniguard = true,
			AB_a_CephHelmOpen = true,
			AB_a_CephPauldronLeft = true,
			AB_a_CephPauldronRight = true,
			cephalopod_helm = true,
			mole_crab_helm = true,
			dust_adept_helm = true,
			potion_t_bug_musk_01 = true,
		},
		import = {
			["6th bell hammer"] = true,
			misc_goblet_dagoth = true,
			AB_Misc_6thBell = true,
			AB_Misc_6thFlute = true,
			misc_6th_ash_statue_01 = true,
			AB_Misc_6thAshStatue13 = true,
			AB_Misc_6thAshStatue07 = true,
			AB_Misc_6thAshStatue04 = true,
			AB_Misc_6thAshStatue02 = true,
			AB_Misc_6thMug = true,
			AB_Misc_6thBowl = true,
			misc_de_goblet_04_dagoth = true,
			AB_Misc_6thPlate02 = true,
			AB_Misc_6thPlate01 = true,
			potion_ancient_brandy = true,
			ingred_corprus_weepings_01 = true,
			ingred_ghoul_heart_01 = true,
		}
	},
	["Sadrith Mora"] = {
		export = {
			bonemold_tshield_telvanniguard = true,
			AB_a_CephHelmOpen = true,
			AB_a_CephPauldronLeft = true,
			AB_a_CephPauldronRight = true,
			cephalopod_helm = true,
			mole_crab_helm = true,
			dust_adept_helm = true,
			potion_t_bug_musk_01 = true,
		},
		import = {
			-- rare items, artifacts and gimmicks
			artifact_bittercup_01 = true,
			misc_vivec_ashmask_01 = true,
			Misc_SoulGem_Azura = true,
			Nuccius_ring = true,
			index_valen = true,
			index_telas = true,
			index_roth = true,
			index_maran = true,
			index_indo = true,
			index_hlor = true,
			index_falen = true,
			index_falas = true,
			index_beran = true,
			index_andra = true,
			T_De_Index_Hlomaseth = true,
			T_De_Index_Hlorandar = true,
			T_De_Index_Idaverrano = true,
			T_De_Index_Khalaan = true,
			T_De_Index_Othrano = true,
			T_De_Index_Romayon = true,
			T_De_Index_Vandirelyon = true,
			T_De_Index_Volenfaryon = true,
			T_De_UNI_PilgrimStone = true,
			T_De_UNI_RenaldLute = true,
			T_De_UNI_UlvoClawMisc = true,
			T_He_DirenniWelkyndInv_01 = true,
			T_Com_UNI_KingOrgnumCoffer_01 = true,
			T_Ayl_WelkyndInv_01 = true,
			T_Ayl_VarlaInv_01 = true,
			T_Ayl_Statuette_01 = true,
			T_Ayl_DWelkyndInv_01 = true,
			T_He_DirenniScales_01 = true,
			T_Rga_MemoryStone_01 = true,
			T_He_DngDirenni_Welkynd01_50 = true,
			T_He_DirenniAlembic_01 = true,
			T_He_DirenniMortar_01 = true,
			T_De_PunavitComCup_01 = true,
			T_De_PunavitSamovar_01 = true,
		}
	},
	chitin = {
		["chitin arrow"] = true,
		["chitin club"] = true,
		["chitin dagger"] = true,
		["chitin short bow"] = true,
		["chitin shortsword"] = true,
		["chitin spear"] = true,
		["chitin throwing star"] = true,
		["chitin war axe"] = true,
		["chitin boots"] = true,
		["chitin cuirass"] = true,
		["chitin greaves"] = true,
		["chitin guantlet - left"] = true,
		["chitin guantlet - right"] = true,
		["chitin helm"] = true,
		["chitin pauldron - left"] = true,
		["chitin pauldron - right"] = true,
		["chitin_shield"] = true,
		["chitin_towershield"] = true,
		["chitin arrow"] = true,
		["chitin club"] = true,
		["chitin dagger"] = true,
		["chitin short bow"] = true,
		["chitin shortsword"] = true,
		["chitin spear"] = true,
		["chitin throwing star"] = true,
		["chitin war axe"] = true,
		T_De_Chitin_HelmOpen_01 = true,
		T_De_Chitin_PauldrL_01 = true,
		T_De_Chitin_PauldrR_01 = true,
	},
	
	netch = {
		netch_leather_boiled_cuirass = true,
		netch_leather_boiled_helm = true,
		netch_leather_boots = true,
		netch_leather_cuirass = true,
		netch_leather_gauntlet_left = true,
		netch_leather_gauntlet_right = true,
		netch_leather_greaves = true,
		netch_leather_helm = true,
		netch_leather_pauldron_left = true,
		netch_leather_pauldron_right = true,
		netch_leather_shield = true,
		netch_leather_towershield = true,
		AB_a_NetchBoilPldLeft = true,
		AB_a_NetchBoilPldRight = true,
		T_De_Netch_Cuirass_01 = true,
		T_De_Netch_Cuirass_02 = true,
		T_De_Netch_Cuirass_03 = true,
		T_De_Netch_Helm_01 = true,
		T_De_Netch_Helm_02 = true,
		T_De_NetchRogue_Cuirass_01 = true,
		T_De_NetchRogue_Helm_01 = true,
		T_De_NetchRogue_Helm_02 = true,
	},
	
	ashlander = {
		AB_Misc_AshlFlute = true,
		AB_w_AshlBoneArrow = true,
		AB_w_BoneArrow = true,
		AB_a_BugBlueBoots = true,
		AB_a_BugBlueCuirass = true,
		AB_a_BugBlueGntLeft = true,
		AB_a_BugBlueGntRight = true,
		AB_a_BugBlueGreaves = true,
		AB_a_BugBlueHelm = true,
		AB_a_BugBluePldLeft = true,
		AB_a_BugBluePldRight = true,
		AB_a_BugBlueShield = true,
		AB_a_BugGreenBoots = true,
		AB_a_BugGreenCuirass = true,
		AB_a_BugGreenGntLeft = true,
		AB_a_BugGreenGntRight = true,
		AB_a_BugGreenGreaves = true,
		AB_a_BugGreenHelm = true,
		AB_a_BugGreenPldLeft = true,
		AB_a_BugGreenPldRight = true,
		AB_a_BugGreenShield = true,
	},
	
	dwemer = {
		AB_Misc_DwGyro00 = true,
	},
	daedra = {
		ingred_daedra_skin_01 = true,
		ingred_daedras_heart_01 = true,
		ingred_fire_salts_01 = true,
		ingred_frost_salts_01 = true,
		ingred_void_salts_01 = true,
		ingred_scamp_skin_01 = true,
		AB_IngCrea_ClannClaw_01 = true,
		AB_IngCrea_TwilightMembrane = true,
		AB_IngCrea_DaeTeeth_01 = true,
		
	},
	
	sea = {
		ingred_pearl_01 = true,
		ingred_dreugh_wax_01 = true,
		ingred_crab_meat_01 = true,
		ingred_scales_01 = true,
		AB_IngCrea_DreughShell_01 = true,
		AB_IngCrea_SfMeat_01 = true,
		T_IngCrea_ShellMolecrab_02 = true,
		T_IngCrea_ShellMolecrab_01 = true,
		T_IngCrea_CephalopodShell_01 = true,

	},
	
	kwama = {
		food_kwama_egg_01 = true,
        food_kwama_egg_02 = true,
		ingred_scrib_jelly_01 = true,
		ingred_scrib_jerky_01 = true,
		AB_IngCrea_KwamaPoison = true,
		AB_IngCrea_ScribShell_01 = true,
		AB_IngFood_KwamaLoaf = true,
		T_IngFood_MeatKwama_01 = true,
		T_IngFood_ScribPie_01 = true,
	},
	
	coins = {
		T_Ayl_CoinGold_01 = true,
		T_Ayl_CoinSquare_01 = true,
		T_Ayl_CoinBig_01 = true,
		T_He_DirenniCoin_01 = true,
		T_Imp_CoinReman_01 = true,
		T_Imp_CoinAlessian_01 = true,
		AB_Misc_CoinTriune = true,
		misc_dwrv_coin00 = true,
		misc_dwrv_cursed_coin00 = true,
		T_Nor_CoinBarrowCopper_01 = true,
		T_Nor_CoinBarrowIron_01 = true,
		T_Nor_CoinBarrowSilver_01 = true,
	},
	
	luxury = {
		T_Imp_GoldBowl_01 = true,
		T_Imp_GoldGoblet_01 = true,
		T_Imp_GoldPitcher_01 = true,
		exquisite_skirt_01 = true,
		exquisite_shoes_01 = true,
		exquisite_shirt_01 = true,
		exquisite_ring_02 = true,
		exquisite_ring_01 = true,
		exquisite_ring_processus = true,
		exquisite_pants_01 = true,
		exquisite_belt_01 = true,
		exquisite_amulet_01 = true,
		T_Com_MetalPieceGold_01 = true,
		T_Com_MetalPieceGold_02 = true,
		T_Com_MetalPieceGold_03 = true,
		T_Com_MetalPieceSilver_01 = true,
		T_Com_MetalPieceSilver_02 = true,
		T_Com_MetalPieceSilver_03 = true,
	},
	
	gems = {
		ingred_diamond_01 = true,
		ingred_Dae_cursed_diamond_01 = true,
		ingred_Dae_cursed_emerald_01 = true,
		ingred_Dae_cursed_pearl_01 = true,
		ingred_Dae_cursed_ruby_01 = true,
		ingred_ruby_01 = true,
		ingred_emerald_01 = true,
		ingred_pearl_01 = true,
		AB_IngMine_Amethyst_01 = true,
		AB_IngMine_BlackPearl_01 = true,
		AB_IngMine_BlackTourmaline_01 = true,
		AB_IngMine_Diopside_01 = true,
		AB_IngMine_Firejade_01 = true,
		AB_IngMine_Garnet_01 = true,
		AB_IngMine_GoldPearl_01 = true,
		AB_IngMine_Peridot_01 = true,
		AB_IngMine_Sapphire_01 = true,
		AB_IngMine_Topaz_01 = true,
		AB_IngMine_Tourmaline_01 = true,
		T_IngMine_EmeraldDeTomb_01 = true,
		T_IngMine_DiamondDeTomb_01 = true,
		T_IngMine_Alexandrite_01 = true,
		T_IngMine_AlexandriteDae_01 = true,
		T_IngMine_Amethyst_01 = true,
		T_IngMine_AmethystDae_01 = true,
		T_IngMine_Aquamarine_01 = true,
		T_IngMine_AquamarineDae_01 = true,
		T_IngMine_Garnet_01 = true,
		T_IngMine_GarnetDae_01 = true,
		T_IngMine_KhajiitEye_01 = true,
		T_IngMine_KhajiitEyeDae_01 = true,
		T_IngMine_Moonstone_01 = true,
		T_IngMine_MoonstoneDae_01 = true,
		T_IngMine_PearlBlack_01 = true,
		T_IngMine_PearlBlackDae_01 = true,
		T_IngMine_PearlDeTomb_01 = true,
		T_IngMine_PearlKardesh_01 = true,
		T_IngMine_RubyDeTomb_01 = true,
		T_IngMine_Sapphire_01 = true,
		T_IngMine_SapphireDae_01 = true,
		T_IngMine_Topaz_01 = true,
		T_IngMine_TopazDae_01 = true,
		T_IngMine_Turquoise_01 = true,
		T_IngMine_TurquoiseDae_01 = true,	
	},
	
	skillBooks = {
	
	},
	pottery = {
	
	},
	glass = {
		Misc_DE_glass_green_01 = true,
		misc_de_glass_yellow_01 = true,
		misc_de_tankard_01 = true,
	},
	food = {
		food_kwama_egg_01 = true,
        food_kwama_egg_02 = true,
		ingred_scrib_jelly_01 = true,
		ingred_scrib_jerky_01 = true,
		ingred_ash_yam_01 = true,
		ingred_bread_01 = true,
		ingred_bread_01_UNI2 = true,
		ingred_bread_01_UNI3 = true,
		ingred_crab_meat_01 = true,
		ingred_durzog_meat_01 = true,
		ingred_saltrice_01 = true,
		ingred_scuttle_01 = true,
		AB_IngCrea_GuarMeat_01 = true,
		AB_IngCrea_HorseMeat01 = true,
		AB_IngCrea_SfMeat_01 = true,
		T_IngCrea_MeatDark_01 = true,
		T_IngCrea_VelkNectarSack_01 = true,
		T_IngFlor_Cabbage_01 = true,
		potion_ancient_brandy = true,
		potion_comberry_brandy_01 = true,
		potion_comberry_wine_01 = true,
		potion_cyro_brandy_01 = true,
		Potion_Cyro_Whiskey_01 = true,
		Potion_Local_Brew_01 = true,
		potion_local_liquor_01 = true,
		potion_nord_mead = true,
		
	},
	
	enchanted = {},
	
	soulgem = {
		Misc_SoulGem_Petty = true,
		Misc_SoulGem_Lesser = true,
		Misc_SoulGem_Common = true,
		Misc_SoulGem_Greater = true,
		Misc_SoulGem_Grand = true,
		Misc_SoulGem_Azura = true,
		Misc_SoulGem_Black = true,
	}
}

local function isSmuggler(actor)
	return actor.class.id == "Smuggler" or (actor.faction and (actor.faction.id == "Thieves Guild" or actor.faction.id == "Camonna Tong"))
end

local function isDwemer(item)
	return string.find(item.id, "dwrv") or string.find(item.id, "dwemer") or string.find(item.id, "dwarven") or string.find(item.id, "AB_*_dw") 
end

local function isForbidden(item)
	local mineral =  string.find(item.id, "raw_glass") or string.find(item.id, "raw_ebony")
	local skooma = string.find(item.id, "potion_skooma") or string.find(item.id, "moon_sugar")
	return mineral or skooma
end

local function addCategoryToRegionExport(category, regions)
	for _, region in ipairs(regions) do
		if not defaultConfig[region] then
			defaultConfig[region] = {
				export = {},
				import = {}
			}
		end
		for item, status in pairs(defaultConfig[category]) do
			if defaultConfig[region].import[item] ~= true then
				defaultConfig[region].export[item] = true
			else
				defaultConfig[region].import[item] = nil
			end
		end
	end
end

local function addCategoryToRegionImport(category, regions)
	for _, region in ipairs(regions) do
		if not defaultConfig[region] then
			defaultConfig[region] = {
				export = {},
				import = {}
			}
		end
		for item, status in pairs(defaultConfig[category]) do
			if defaultConfig[region].export[item] ~= true then
				defaultConfig[region].import[item] = true
			else
				defaultConfig[region].export[item] = nil
			end
		end
	end
end

local function addRegionGoods(region, towns)
	for _, town in ipairs(towns) do
		if not defaultConfig[town] then
			defaultConfig[town] = {
				export = {
				},
				import = {
				}
			}
		end
		
		for item, status in pairs(defaultConfig[region].export) do
			if status then
				if defaultConfig[town].export[item] ~= false then
					defaultConfig[town].export[item] = status
				end
			end
		end
		
		for item, status in pairs(defaultConfig[region].import) do
			if status then
				if defaultConfig[town].import[item] ~= false then
					defaultConfig[town].import[item] = status
				end
			end
		end
	end
end

for obj in tes3.iterateObjects(tes3.objectType.npc) do
	if isSmuggler(obj) then
		defaultConfig.smuggler[obj.id] = true
	end
end

local itemTypes = { [tes3.objectType.alchemy] = true, [tes3.objectType.ammunition] = true, [tes3.objectType.apparatus] = true, [tes3.objectType.armor] = true, [tes3.objectType.book] = true, [tes3.objectType.clothing] = true, [tes3.objectType.ingredient] = true, [tes3.objectType.light] = true, [tes3.objectType.lockpick] = true, [tes3.objectType.miscItem] = true, [tes3.objectType.probe] = true, [tes3.objectType.repairItem] = true, [tes3.objectType.weapon] = true }	

for obj in tes3.iterateObjects() do
	if (itemTypes[obj.objectType]) then
		if isDwemer(obj) then
			defaultConfig.dwemer[obj.id] = true
			defaultConfig.forbidden[obj.id] = true
		elseif isForbidden(obj) then
			defaultConfig.forbidden[obj.id] = true
		end
	end
end

for book in tes3.iterateObjects(tes3.objectType.book) do
	if book.skill >= 0 then
		defaultConfig.skillBooks[book.id] = true
	end
end

for ingred in tes3.iterateObjects(tes3.objectType.ingredient) do
	if string.startswith(ingred.id, "AB_IngFood_") or string.startswith(ingred.id, "T_IngFood_") then
		defaultConfig.food[ingred.id] = true
	end
end

for potion in tes3.iterateObjects(tes3.objectType.alchemy) do
	if string.startswith(potion.id, "AB_dri_") or string.find(potion.id, "^T_%w+_Drink") then
		defaultConfig.food[potion.id] = true
	end
end

for misc in tes3.iterateObjects(tes3.objectType.miscItem) do
	if string.startswith(misc.id, "AB_Misc_DeBlue") or string.startswith(misc.id, "AB_Misc_DeEbony") or string.startswith(misc.id, "AB_Misc_DeGreen") or string.startswith(misc.id, "AB_Misc_DePeach") or string.startswith(misc.id, "AB_Misc_DeYel") or string.startswith(misc.id, "misc_com_bottle") or string.startswith(misc.id, "misc_de_goblet") then
		defaultConfig.glass[misc.id] = true
	elseif string.startswith(misc.id, "misc_com_redware") or string.startswith(misc.id, "misc_com_plate") or string.startswith(misc.id, "misc_de_bowl_redware") or string.startswith(misc.id, "misc_de_pot_redware") or string.startswith(misc.id, "AB_Misc_DeYel") then
		defaultConfig.pottery[misc.id] = true
	end
end

enchantedLvlLists = {"l_m_enchantitem_telvanni_rank01", "l_m_enchantitem_telvanni_rank6", "l_m_enchantitem_telvanni_rank8"}


for i, leveledItem in ipairs(enchantedLvlLists) do
	leveledItem = tes3.getObject(leveledItem)
	for _, listNode in ipairs(leveledItem.list) do
		item = listNode.object
		defaultConfig.enchanted[item.id] = true
	end
end

addCategoryToRegionExport("kwama", {"Molag Amur Region", "West Gash Region", "Ashlands Region"})
addCategoryToRegionExport("daedra", {"Grazelands Region", "Azura's Coast Region", "Molag Amur Region"})
addCategoryToRegionExport("dwemer", {"Molag Amur Region"})
addCategoryToRegionExport("sea", {"Bitter Coast Region", "Azura's Coast Region", "Sheogorad Region"})

addRegionGoods("West Gash Region", {"Balmora", "Caldera", "Gnisis", "Khuul", "Ald Velothi"})
addRegionGoods("Bitter Coast Region", {"Seyda Neen", "Gnaar Mok", "Hla Oad"})
addRegionGoods("Ascadian Isles Region", {"Suran", "Pelagiad", "Ebonheart"})
addRegionGoods("Molag Amur Region", {"Molag Mar", "Erabenimsun Camp"})
addRegionGoods("Azura's Coast Region", {"Tel Branora", "Tel Aruhn", "Sadrith Mora", "Tel Mora"})
addRegionGoods("Grazelands Region", {"Vos", "Tel Vos", "Ahemmusa Camp"})
addRegionGoods("Sheogorad Region", {"Dagon Fel"})
addRegionGoods("Ashlands Region", {"Ald-ruhn", "Maar Gan", "Urshilaku Camp"})
addRegionGoods("Red Mountain Region", {"Ghostgate"})
addRegionGoods("Solstheim", {"Felsaad Coast", "Hirstaang Forest", "Isinfier Plains", "Moesring Mountains", "Skaal Village", "Thirsk", "Raven Rock", "Fort Frostmoth"})

addCategoryToRegionExport("netch", {"Balmora", "Suran"})
addCategoryToRegionExport("chitin", {"Ald-ruhn", "Urshilaku Camp", "Erabenimsun Camp", "Ahemmusa Camp", "Zainab Camp"})
addCategoryToRegionExport("ashlander", {"Urshilaku Camp", "Erabenimsun Camp", "Ahemmusa Camp", "Zainab Camp"})
addCategoryToRegionExport("enchanted", {"Tel Branora", "Tel Aruhn", "Sadrith Mora", "Tel Mora", "Vos", "Tel Vos"})

addCategoryToRegionImport("gems", {"Balmora", "Suran"})
addCategoryToRegionImport("luxury", {"Balmora", "Suran"})
addCategoryToRegionImport("coins", {"Balmora", "Suran"})
addCategoryToRegionImport("soulgem", {"Tel Branora", "Tel Aruhn", "Sadrith Mora", "Tel Mora", "Vos", "Tel Vos"})
addCategoryToRegionImport("food", {"Ald-ruhn", "Maar Gan", "Ghostgate"})



local mwseConfig = mwse.loadConfig("buyingGame", defaultConfig)

return mwseConfig;
