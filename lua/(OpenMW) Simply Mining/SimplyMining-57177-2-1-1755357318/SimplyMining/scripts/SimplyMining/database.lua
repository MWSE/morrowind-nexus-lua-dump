db_weights = {
    {item = "T_IngMine_OreIron_01", weight = 15},
    --{item = "T_IngMine_OreCopper_01", weight = 35},
    {item = "T_IngMine_Coal_01", weight = 10},
    {item = "T_IngMine_OreSilver_01", weight = 9},
    {item = "T_IngMine_OreGold_01", weight = 9},
    {item = "T_IngMine_OreOrichalcum_01", weight = 8},
    {item = "ingred_diamond_01", weight = 6},
    {item = "ingred_adamantium_ore_01", weight = 5},
    {item = "ingred_raw_glass_01", weight = 5},
    {item = "ingred_raw_ebony_01", weight = 5},
}

db_difficulties = {
    ["T_IngMine_OreIron_01"] = 15,     
    ["T_IngMine_Coal_01"] = 22,        
    ["T_IngMine_OreSilver_01"] = 31,
    ["T_IngMine_OreCopper_01"] = 35, 
    ["T_IngMine_OreGold_01"] = 38,
    ["T_IngMine_OreOrichalcum_01"] = 55,
    ["ingred_diamond_01"] = 40,
    ["ingred_adamantium_ore_01"] = 65,
    ["ingred_raw_ebony_01"] = 77,       
    ["ingred_raw_glass_01"] = 85,       
}

db_nodes = {
    -- T_IngMine_OreQuicksilver_01 (Quicksilver)
    --["T_IngMine_OreQuicksilver_01"] = {
    --    -- Keine Nodes
    --},
	
    -- T_IngMine_Coal_01 (Coal)
    ["T_IngMine_Coal_01"] = {
		"sm_coal_vein" -- i\Contain_rock_Apy_09.NIF
	},
    -- T_IngMine_OreGold_01 (Gold)
    ["T_IngMine_OreGold_01"] = {
        "t_cyr_mine_oregcgold02", -- pc\o\PC_cont_ore_GC_gld_02.nif
        "t_cyr_mine_oregcgold03", -- pc\o\PC_cont_ore_GC_gld_03.nif
        "t_cyr_mine_oregcgold04", -- pc\o\PC_cont_ore_GC_gld_04.nif
        "t_cyr_mine_oregcgold05", -- pc\o\PC_cont_ore_GC_gld_05.nif
        "t_cyr_mine_oregcgold06", -- pc\o\PC_cont_ore_GC_gld_06.nif
        "t_cyr_mine_oregcgold07", -- pc\o\PC_cont_ore_GC_gld_07.nif
        "t_mw_mine_oregold05", -- TR\o\TR_cont_rock_gold_05.nif
        "t_mw_mine_oregold07", -- TR\o\TR_cont_rock_gold_07.nif
        "t_mw_mine_oregold02", -- TR\o\TR_cont_rock_gold_02.nif
        "t_mw_mine_oregold04", -- TR\o\TR_cont_rock_gold_04.nif
        "t_mw_mine_oregold03", -- TR\o\TR_cont_rock_gold_03.nif
        "t_mw_mine_oregold06", -- TR\o\TR_cont_rock_gold_06.nif
    },
    
    -- T_IngMine_OreOrichalcum_01 (Orichalcum)
    ["T_IngMine_OreOrichalcum_01"] = {
        "t_sky_mine_orereorich03", -- sky\o\sky_cont_rock_ori_03.nif
        "t_sky_mine_orereorich07", -- sky\o\sky_cont_rock_ori_07.nif
        "t_sky_mine_orereorich06", -- sky\o\sky_cont_rock_ori_06.nif
        "t_sky_mine_orereorich05", -- sky\o\sky_cont_rock_ori_05.nif
        "t_sky_mine_orereorich02", -- sky\o\sky_cont_rock_ori_02.nif
        "t_sky_mine_orereorich04", -- sky\o\sky_cont_rock_ori_04.nif
    },
    
    -- ingred_raw_glass_01 (Raw Glass)
    ["ingred_raw_glass_01"] = {
        -- Vanilla IDs für Raw Glass
        "rock_glass_02", -- o\Contain_rock_glass_02.nif
        "rock_glass_03", -- o\Contain_rock_glass_03.nif
        "rock_glass_04", -- o\Contain_rock_glass_04.nif
        "rock_glass_05", -- o\Contain_rock_glass_05.nif
        "rock_glass_06", -- o\Contain_rock_glass_06.nif
        "rock_glass_07", -- o\Contain_rock_glass_07.nif
    },
    
    -- ingred_adamantium_ore_01 (Adamantium)
    ["ingred_adamantium_ore_01"] = {
        -- Vanilla IDs für Adamantium
        "rock_adam_mold15", -- i\Contain_rock_Am_15.NIF
        "rock_adam_mold17", -- i\Contain_rock_Am_17.NIF
        "rock_adam_mold18", -- i\Contain_rock_Am_18.NIF
        "rock_adam_mold19", -- i\Contain_rock_Am_19.NIF
        "rock_adam_mold20", -- i\Contain_rock_Am_20.NIF
        "rock_adam_py08", -- i\Contain_rock_Apy_08.NIF
        "rock_adam_py09", -- i\Contain_rock_Apy_09.NIF
        "rock_adam_py11", -- i\Contain_rock_Apy_11.NIF
        "rock_adam_py12", -- i\Contain_rock_Apy_12.NIF
        "rock_adam_py14", -- i\Contain_rock_Apy_14.NIF
        -- TR Adamantium Nodes
        "t_cyr_mine_oregcadam03", -- pc\o\PC_cont_ore_GC_Am_17.NIF
        "t_cyr_mine_oregcadam04", -- pc\o\PC_cont_ore_GC_Am_18.NIF
        "t_cyr_mine_orechadam05", -- PC\o\pc_cont_chrock_adam_05.nif
        "t_cyr_mine_orechadam01", -- PC\o\pc_cont_chrock_adam_01.nif
        "t_cyr_mine_oregcadam05", -- pc\o\PC_cont_ore_GC_Am_19.NIF
        "t_cyr_mine_orechadam07", -- PC\o\pc_cont_chrock_adam_07.nif
        "t_cyr_mine_orechadam02", -- PC\o\pc_cont_chrock_adam_02.nif
        "t_cyr_mine_orechadam04", -- PC\o\pc_cont_chrock_adam_04.nif
        "t_cyr_mine_oregcadam01", -- pc\o\PC_cont_ore_GC_Am_15.NIF
        "t_cyr_mine_oregcadam06", -- pc\o\PC_cont_ore_GC_Am_20.NIF
    },
    
    -- T_IngMine_OreIron_01 (Iron)
    ["T_IngMine_OreIron_01"] = {
        "t_mw_mine_oreiron02", -- TR\o\tr_cont_rock_iron_02.nif
        "t_mw_mine_oreiron03", -- TR\o\tr_cont_rock_iron_03.nif
        "t_mw_mine_oreiron05", -- TR\o\tr_cont_rock_iron_05.nif
        "t_mw_mine_oreiron06", -- TR\o\tr_cont_rock_iron_06.nif
        "t_cyr_mine_oregciron04", -- pc\o\PC_cont_ore_GC_irn_04.nif
        "t_sky_mine_orereiron03", -- Sky\o\Sky_Cont_Rock_IRN_03.nif
        "t_cyr_mine_orechiron06", -- pc\o\pc_cont_chrock_iron_06.nif
        "t_cyr_mine_oregciron03", -- pc\o\PC_cont_ore_GC_irn_03.nif
        "t_cyr_mine_oregciron06", -- pc\o\PC_cont_ore_GC_irn_06.nif
        "t_cyr_mine_orewwiron06", -- pc\o\pc_cont_wwrock_iron_06.nif
        "t_cyr_mine_orechiron04", -- pc\o\pc_cont_chrock_iron_04.nif
        "t_sky_mine_orereiron04", -- Sky\o\Sky_Cont_Rock_IRN_04.nif
        "t_cyr_mine_orechiron02", -- pc\o\pc_cont_chrock_iron_02.nif
        "t_cyr_mine_orewwiron02", -- pc\o\pc_cont_wwrock_iron_02.nif
        "t_cyr_mine_oregciron07", -- pc\o\PC_cont_ore_GC_irn_07.nif
        "t_cyr_mine_orechiron05", -- pc\o\pc_cont_chrock_iron_05.nif
        "t_sky_mine_orereiron07", -- Sky\o\Sky_Cont_Rock_IRN_07.nif
        "t_sky_mine_orereiron06", -- Sky\o\Sky_Cont_Rock_IRN_06.nif
        "t_sky_mine_orereiron05", -- Sky\o\Sky_Cont_Rock_IRN_05.nif
        "t_sky_mine_orereiron02", -- Sky\o\Sky_Cont_Rock_IRN_02.nif
        "t_cyr_mine_orewwiron05", -- pc\o\pc_cont_wwrock_iron_05.nif
        "t_cyr_mine_oregciron05", -- pc\o\PC_cont_ore_GC_irn_05.nif
        "t_cyr_mine_oregciron02", -- pc\o\PC_cont_ore_GC_irn_02.nif
        "t_cyr_mine_orechiron03", -- pc\o\pc_cont_chrock_iron_03.nif
        "t_cyr_mine_orewwiron03", -- pc\o\pc_cont_wwrock_iron_03.nif
		
    },
    
    -- ingred_raw_ebony_01 (Ebony)
    ["ingred_raw_ebony_01"] = {
        -- Vanilla IDs für Ebony
        "rock_ebony_03", -- o\Contain_rock_ebony_03.nif
        "rock_ebony_04", -- o\Contain_rock_ebony_04.nif
        "rock_ebony_05", -- o\Contain_rock_ebony_05.nif
        "rock_ebony_05_colony", -- o\Contain_rock_ebony_05.nif
        "rock_ebony_06", -- o\Contain_rock_ebony_06.nif
        "rock_ebony_06_colony", -- o\Contain_rock_ebony_06.nif
        "rock_ebony_07", -- o\Contain_rock_ebony_07.nif
        "rock_ebony_07_colony", -- o\Contain_rock_ebony_07.nif
    },
    

    
    -- Copper (zusätzlich gefunden)
    ["T_IngMine_OreCopper_01"] = {
        "t_cyr_mine_orechcopp02", -- pc\o\pc_cont_chrock_copp_02.nif
        "t_cyr_mine_orechcopp03", -- pc\o\pc_cont_chrock_copp_03.nif
        "t_cyr_mine_orechcopp04", -- pc\o\pc_cont_chrock_copp_04.nif
        "t_cyr_mine_orechcopp05", -- pc\o\pc_cont_chrock_copp_05.nif
        "t_cyr_mine_orechcopp06", -- pc\o\pc_cont_chrock_copp_06.nif
        "t_cyr_mine_orechcopp07", -- pc\o\pc_cont_chrock_copp_07.nif
    },
    
    -- Silver (zusätzlich gefunden)
    ["T_IngMine_OreSilver_01"] = {
        "t_sky_mine_oreresilv02", -- Sky\o\Sky_Cont_Rock_SLV_02.nif
        "t_sky_mine_oreresilv03", -- Sky\o\Sky_Cont_Rock_SLV_03.nif
        "t_sky_mine_oreresilv04", -- Sky\o\Sky_Cont_Rock_SLV_04.nif
        "t_sky_mine_oreresilv05", -- Sky\o\Sky_Cont_Rock_SLV_05.nif
        "t_sky_mine_oreresilv06", -- Sky\o\Sky_Cont_Rock_SLV_06.nif
        "t_sky_mine_oreresilv07", -- Sky\o\Sky_Cont_Rock_SLV_07.nif
        "t_cyr_mine_oregcsilv02", -- pc\o\PC_cont_ore_GC_slv_02.nif
        "t_cyr_mine_oregcsilv03", -- pc\o\PC_cont_ore_GC_slv_03.nif
        "t_cyr_mine_oregcsilv04", -- pc\o\PC_cont_ore_GC_slv_04.nif
        "t_cyr_mine_oregcsilv05", -- pc\o\PC_cont_ore_GC_slv_05.nif
        "t_cyr_mine_oregcsilv06", -- pc\o\PC_cont_ore_GC_slv_06.nif
        "t_cyr_mine_oregcsilv07", -- pc\o\PC_cont_ore_GC_slv_07.nif
        "t_mw_mine_oreslvr02", -- tr\o\tr_cont_rock_slvr_02.nif
        "t_mw_mine_oreslvr03", -- tr\o\tr_cont_rock_slvr_03.nif
        "t_mw_mine_oreslvr04", -- tr\o\tr_cont_rock_slvr_04.nif
        "t_mw_mine_oreslvr05", -- tr\o\tr_cont_rock_slvr_05.nif
        "t_mw_mine_oreslvr06", -- tr\o\tr_cont_rock_slvr_06.nif
        "t_mw_mine_oreslvr07", -- tr\o\tr_cont_rock_slvr_07.nif
    },
    
    -- Diamond (zusätzlich in vanillaIds gefunden)
    ["ingred_diamond_01"] = {
        "rock_diamond_02", -- o\Contain_rock_diamond_02.nif
        "rock_diamond_03", -- o\Contain_rock_diamond_03.nif
        "rock_diamond_04", -- o\Contain_rock_diamond_04.nif
        "rock_diamond_05", -- o\Contain_rock_diamond_05.nif
        "rock_diamond_06", -- o\Contain_rock_diamond_06.nif
        "rock_diamond_07", -- o\Contain_rock_diamond_07.nif
    }
}

db_nodes_all = {
    ["T_IngMine_OreIron_01"] = {
        -- Tamriel Rebuilt (T_Mw)
        "t_mw_mine_oreiron02",
        "t_mw_mine_oreiron06",
        "t_mw_mine_oreiron05",
        "t_mw_mine_oreiron04", -- auskommentiert
        "t_mw_mine_oreiron07", -- auskommentiert
        "t_mw_mine_oreiron03",
        "t_mw_mine_oreiron01", -- auskommentiert
        
        -- Cyrodiil (T_Cyr)
        "t_cyr_mine_oregciron04",
        "t_cyr_mine_oregciron03",
        "t_cyr_mine_oregciron06",
        "t_cyr_mine_oregciron07",
        "t_cyr_mine_oregciron05",
        "t_cyr_mine_oregciron02",
        "t_cyr_mine_oregciron01", -- auskommentiert
        "t_cyr_mine_orechiron06",
        "t_cyr_mine_orechiron07",
        "t_cyr_mine_orechiron04",
        "t_cyr_mine_orechiron02",
        "t_cyr_mine_orechiron05",
        "t_cyr_mine_orechiron01", -- auskommentiert
        "t_cyr_mine_orechiron03",
        "t_cyr_mine_orewwiron06",
        "t_cyr_mine_orewwiron02",
        "t_cyr_mine_orewwiron03",
        "t_cyr_mine_orewwiron01", -- auskommentiert
        "t_cyr_mine_orewwiron04", -- auskommentiert
        "t_cyr_mine_orewwiron05",
        
        -- Skyrim (T_Sky)
        "t_sky_mine_orereiron03",
        "t_sky_mine_orereiron04",
        "t_sky_mine_orereiron07",
        "t_sky_mine_orereiron06",
        "t_sky_mine_orereiron05",
        "t_sky_mine_orereiron02",
        "t_sky_mine_orereiron01", -- auskommentiert
        
        -- Province Cyrodiil (T_Pi)
        "t_pi_mine_oreyniron06", -- auskommentiert
        "t_pi_mine_oreyniron04", -- auskommentiert
        "t_pi_mine_oreyniron05", -- auskommentiert
        "t_pi_mine_oreyniron02", -- auskommentiert
        "t_pi_mine_oreyniron03", -- auskommentiert
        "t_pi_mine_oreyniron01", -- auskommentiert
        "t_pi_mine_oreyniron07", -- auskommentiert
        "t_pi_mine_orepyiron04", -- auskommentiert
        "t_pi_mine_orepyiron07", -- auskommentiert
        "t_pi_mine_orepyiron02", -- auskommentiert
        "t_pi_mine_orepyiron05", -- auskommentiert
        "t_pi_mine_orepyiron03", -- auskommentiert
        "t_pi_mine_orepyiron01", -- auskommentiert
        "t_pi_mine_orepyiron06", -- auskommentiert
        "t_pi_mine_orecqiron07", -- auskommentiert
        "t_pi_mine_orecqiron02", -- auskommentiert
        "t_pi_mine_orecqiron04", -- auskommentiert
        "t_pi_mine_orecqiron06", -- auskommentiert
        "t_pi_mine_orecqiron03", -- auskommentiert
        "t_pi_mine_orecqiron05", -- auskommentiert
        "t_pi_mine_orecqiron01", -- auskommentiert
		
		-- TR Mainland ushu kur mine
		"tr_m4_ushukur_oreco_01a",
		"tr_m4_ushukur_oreco_01b",
		"tr_m4_ushukur_oreco_02a",
		"tr_m4_ushukur_oreco_02b",
		"tr_m4_ushukur_oreco_03a",
		"tr_m4_ushukur_oreco_03b",
    },
    
    ["T_IngMine_Coal_01"] = {
        --"t_glb_mine_orecoal_01", -- auskommentiert "coal pile"
        "sm_coal_vein", -- auskommentiert
    },
    
    ["T_IngMine_OreCopper_01"] = {
        -- Cyrodiil (T_Cyr)
        "t_cyr_mine_orechcopp02",
        "t_cyr_mine_orechcopp04",
        "t_cyr_mine_orechcopp06",
        "t_cyr_mine_orechcopp03",
        "t_cyr_mine_orechcopp05",
        "t_cyr_mine_orechcopp07",
        "t_cyr_mine_orechcopp01", -- auskommentiert
    },
    
    ["T_IngMine_OreSilver_01"] = {
        -- Tamriel Rebuilt (T_Mw)
        "t_mw_mine_oreslvr05",
        "t_mw_mine_oreslvr02",
        "t_mw_mine_oreslvr03",
        "t_mw_mine_oreslvr04",
        "t_mw_mine_oreslvr07",
        "t_mw_mine_oreslvr06",
        "t_mw_mine_oreslvr01", -- auskommentiert
        
        -- Cyrodiil (T_Cyr)
        "t_cyr_mine_oregcsilv04",
        "t_cyr_mine_oregcsilv03",
        "t_cyr_mine_oregcsilv06",
        "t_cyr_mine_oregcsilv02",
        "t_cyr_mine_oregcsilv07",
        "t_cyr_mine_oregcsilv05",
        "t_cyr_mine_oregcsilv01", -- auskommentiert
        
        -- Skyrim (T_Sky)
        "t_sky_mine_oreresilv04",
        "t_sky_mine_oreresilv06",
        "t_sky_mine_oreresilv05",
        "t_sky_mine_oreresilv02",
        "t_sky_mine_oreresilv07",
        "t_sky_mine_oreresilv03",
        "t_sky_mine_oreresilv01", -- auskommentiert
    },
    
    ["T_IngMine_OreQuicksilver_01"] = {
        "t_sky_mine_orerequiks01", -- auskommentiert (Quicksilver)
    },
	
	
    ["T_IngMine_OreGold_01"] = {
        -- Tamriel Rebuilt (T_Mw)
        "t_mw_mine_oregold07",
        "t_mw_mine_oregold05",
        "t_mw_mine_oregold02",
        "t_mw_mine_oregold04",
        "t_mw_mine_oregold03",
        "t_mw_mine_oregold06",
        "t_mw_mine_oregold01", -- auskommentiert
        
        -- Cyrodiil (T_Cyr)
        "t_cyr_mine_oregcgold03",
        "t_cyr_mine_oregcgold05",
        "t_cyr_mine_oregcgold07",
        "t_cyr_mine_oregcgold04",
        "t_cyr_mine_oregcgold06",
        "t_cyr_mine_oregcgold02",
        "t_cyr_mine_oregcgold01", -- auskommentiert
        
        -- Province Cyrodiil (T_Pi)
        "t_pi_mine_oreyngold03", -- auskommentiert
        "t_pi_mine_oreyngold01", -- auskommentiert
        "t_pi_mine_oreyngold06", -- auskommentiert
        "t_pi_mine_oreyngold07", -- auskommentiert
        "t_pi_mine_oreyngold04", -- auskommentiert
        "t_pi_mine_oreyngold02", -- auskommentiert
        "t_pi_mine_oreyngold05", -- auskommentiert
        "t_pi_mine_orepogold02", -- auskommentiert
        "t_pi_mine_orepogold07", -- auskommentiert
        "t_pi_mine_orepogold06", -- auskommentiert
        "t_pi_mine_orepogold03", -- auskommentiert
        "t_pi_mine_orepogold05", -- auskommentiert
        "t_pi_mine_orepogold01", -- auskommentiert
        "t_pi_mine_orepogold04", -- auskommentiert
    },
    
    ["T_IngMine_OreOrichalcum_01"] = {
        -- Skyrim (T_Sky)
        "t_sky_mine_orereorich03",
        "t_sky_mine_orereorich07",
        "t_sky_mine_orereorich06",
        "t_sky_mine_orereorich05",
        "t_sky_mine_orereorich02",
        "t_sky_mine_orereorich04",
        "t_sky_mine_orereorich01", -- auskommentiert
    },
    
    ["ingred_diamond_01"] = {
        -- Vanilla IDs
        "rock_diamond_02",
        "rock_diamond_03",
        "rock_diamond_04",
        "rock_diamond_05",
        "rock_diamond_06",
        "rock_diamond_07",
        "rock_diamond_01", -- auskommentiert
		
		-- correctUV Ore Replacer
		"rock_diamond_bone_01",
		"rock_diamond_bone_02",
		"rock_diamond_bone_03",
		"rock_diamond_bone_04",
		"rock_diamond_bone_05",
		"rock_diamond_bone_06",
		"rock_diamond_bone_07",
		"rock_diamond_lava_01",
		"rock_diamond_lava_02",
		"rock_diamond_lava_03",
		"rock_diamond_lava_04",
		"rock_diamond_lava_05",
		"rock_diamond_lava_06",
		"rock_diamond_lava_07",
		"rock_diamond_mold_01",
		"rock_diamond_mold_02",
		"rock_diamond_mold_03",
		"rock_diamond_mold_04",
		"rock_diamond_mold_05",
		"rock_diamond_mold_06",
		"rock_diamond_mold_07",
		"rock_diamond_mud_01",
		"rock_diamond_mud_02",
		"rock_diamond_mud_03",
		"rock_diamond_mud_04",
		"rock_diamond_mud_05",
		"rock_diamond_mud_06",
		"rock_diamond_mud_07",
		"rock_diamond_py_01",
		"rock_diamond_py_02",
		"rock_diamond_py_03",
		"rock_diamond_py_04",
		"rock_diamond_py_05",
		"rock_diamond_py_06",
		"rock_diamond_py_07",
    },
    
    ["ingred_raw_glass_01"] = {
        -- Vanilla IDs
        "rock_glass_02",
        "rock_glass_03",
        "rock_glass_04",
        "rock_glass_05",
        "rock_glass_06",
        "rock_glass_07",
        "rock_glass_01", -- auskommentiert
        
        -- Province Cyrodiil (T_Pi) - Sand/Glass nodes
        "t_pi_mine_sandpoglass01", -- auskommentiert
        "t_pi_mine_sandpoglass02", -- auskommentiert
        "t_pi_mine_sandcqglass01", -- auskommentiert
        "t_pi_mine_sandcqglass02", -- auskommentiert
        "t_pi_mine_sandcqglsblk2", -- auskommentiert
        "t_pi_mine_sandcqglsblk1", -- auskommentiert
        "t_pi_mine_sandynglass01", -- auskommentiert
        "t_pi_mine_sandynglass02", -- auskommentiert
		
		-- correctUV Ore Replacer
		"rock_glass_bone_01",
		"rock_glass_bone_02",
		"rock_glass_bone_03",
		"rock_glass_bone_04",
		"rock_glass_bone_05",
		"rock_glass_bone_06",
		"rock_glass_bone_07",
		"rock_glass_lava_01",
		"rock_glass_lava_02",
		"rock_glass_lava_03",
		"rock_glass_lava_04",
		"rock_glass_lava_05",
		"rock_glass_lava_06",
		"rock_glass_lava_07",
		"rock_glass_mold_01",
		"rock_glass_mold_02",
		"rock_glass_mold_03",
		"rock_glass_mold_04",
		"rock_glass_mold_05",
		"rock_glass_mold_06",
		"rock_glass_mold_07",
		"rock_glass_mud_01",
		"rock_glass_mud_02",
		"rock_glass_mud_03",
		"rock_glass_mud_04",
		"rock_glass_mud_05",
		"rock_glass_mud_06",
		"rock_glass_mud_07",
		"rock_glass_py_01",
		"rock_glass_py_02",
		"rock_glass_py_03",
		"rock_glass_py_04",
		"rock_glass_py_05",
		"rock_glass_py_06",
		"rock_glass_py_07",
    },
    
    ["ingred_raw_ebony_01"] = {
        -- Vanilla IDs
        "rock_ebony_03",
        "rock_ebony_04",
        "rock_ebony_05",
        "rock_ebony_05_colony",
        "rock_ebony_06",
        "rock_ebony_06_colony",
        "rock_ebony_07",
        "rock_ebony_07_colony",
        "rock_ebony_01", -- auskommentiert
        "rock_ebony_01_colony", -- auskommentiert
        "rock_ebony_02", -- auskommentiert
        "rock_ebony_02_colony", -- auskommentiert
		
		-- correctUV Ore Replacer
		"rock_ebony_bone_01",
		"rock_ebony_bone_02",
		"rock_ebony_bone_03",
		"rock_ebony_bone_04",
		"rock_ebony_bone_05",
		"rock_ebony_bone_06",
		"rock_ebony_bone_07",
		"rock_ebony_lava_01",
		"rock_ebony_lava_02",
		"rock_ebony_lava_03",
		"rock_ebony_lava_04",
		"rock_ebony_lava_05",
		"rock_ebony_lava_06",
		"rock_ebony_lava_07",
		"rock_ebony_mold_01",
		"rock_ebony_mold_02",
		"rock_ebony_mold_03",
		"rock_ebony_mold_04",
		"rock_ebony_mold_05",
		"rock_ebony_mold_06",
		"rock_ebony_mold_07",
		"rock_ebony_mud_01",
		"rock_ebony_mud_02",
		"rock_ebony_mud_03",
		"rock_ebony_mud_04",
		"rock_ebony_mud_05",
		"rock_ebony_mud_06",
		"rock_ebony_mud_07",
		"rock_ebony_py_01",
		"rock_ebony_py_02",
		"rock_ebony_py_03",
		"rock_ebony_py_04",
		"rock_ebony_py_05",
		"rock_ebony_py_06",
		"rock_ebony_py_07",
    },
    
    ["ingred_adamantium_ore_01"] = {
        -- Vanilla IDs
        "rock_adam_mold15",
        "rock_adam_mold17",
        "rock_adam_mold18",
        "rock_adam_mold19",
        "rock_adam_mold20",
        "rock_adam_mold16", -- auskommentiert
        "rock_adam_mold21", -- auskommentiert
        "rock_adam_py08",
        "rock_adam_py09",
        "rock_adam_py11",
        "rock_adam_py12",
        "rock_adam_py14",
        "rock_adam_py10", -- auskommentiert
        "rock_adam_py13", -- auskommentiert
        
        -- Cyrodiil (T_Cyr)
        "t_cyr_mine_oregcadam03",
        "t_cyr_mine_oregcadam04",
        "t_cyr_mine_oregcadam05",
        "t_cyr_mine_oregcadam01",
        "t_cyr_mine_oregcadam06",
        "t_cyr_mine_oregcadam02", -- auskommentiert
        "t_cyr_mine_oregcadam07", -- auskommentiert
        "t_cyr_mine_orechadam05",
        "t_cyr_mine_orechadam04",
        "t_cyr_mine_orechadam01",
        "t_cyr_mine_orechadam07",
        "t_cyr_mine_orechadam02",
        "t_cyr_mine_orechadam03", -- auskommentiert
        "t_cyr_mine_orechadam06", -- auskommentiert
        
        -- Tamriel Rebuilt (T_Mw) - auskommentiert
        "t_mw_mine_oreomadam03", -- auskommentiert
        "t_mw_mine_oreomadam06", -- auskommentiert
        "t_mw_mine_oreomadam05", -- auskommentiert
        "t_mw_mine_oreomadam04", -- auskommentiert
        "t_mw_mine_oreomadam07", -- auskommentiert
        "t_mw_mine_oreomadam02", -- auskommentiert
        "t_mw_mine_oreomadam01", -- auskommentiert
    }
}




unavailableOres = {
	["T_IngMine_OreQuicksilver_01"] = true,
	["T_IngMine_OreCopper_01"] = true,
}