local CraftingFramework = require("CraftingFramework")
if not CraftingFramework then return end

-- Smithing
local materials = {
    {
        id = "hap_netch_leather",
        name = "Netch Leather",
        ids = {
            "ingred_netch_leather_01"
        }
    },

    {
        id = "hap_netch_leather_boiled",
        name = "Boiled Netch Leather",
        ids = {
            "hap_boiled_leather_n"
        }
    },

    {
        id = "hap_bear_pelt",
        name = "Bear Pelt",
        ids = {
            "ingred_bear_pelt",
            "ingred_snowbear_pelt_unique",
            "T_IngCrea_BearpeltBlack_01"
        }
    },

    {
        id = "hap_chitin",
        name = "Chitin",
        ids = {
            "T_IngCrea_KwamaChitin_01",
            "AB_Misc_KwamaChitin",
            "T_IngCrea_BeetleShell_01",
            "T_IngCrea_BeetleShell_02",
            "T_IngCrea_BeetleShell_03",
            "T_IngCrea_BeetleShell_04",
            "_ce_shalkshell1",
            "_ce_shalkshell2"
        }
    },

    {
        id = "hap_resin",
        name = "Resin",
        ids = {
            "ingred_resin_01",
            "ingred_shalk_resin_01",
            "T_IngCrea_BeetleResin_01",
            "AB_IngFlor_TelvanniResin"
        }
    },

    {
        id = "hap_newtscales",
        name = "Newtscales",
        ids = {
            "T_IngCrea_Newtscales_01"
        }
    },

    {
        id = "hap_glass",
        name = "Tempered Glass",
        ids = {
            "hap_tempered_glass"
        }
    },

    {
        id = "hap_cloth",
        name = "Cloth",
        ids = {
            "misc_clothbolt_01",
            "misc_clothbolt_02",
            "misc_clothbolt_03",
            "misc_de_cloth10",
            "misc_de_cloth11",
            "misc_de_foldedcloth00"
        }
    },

    {
        id = "hap_leather",
        name = "Leather",
        ids = {
            "ingred_boar_leather",
            "ashfall_leather",
            "hap_leather",
            "ingred_bguarhide",
            "ingred_kagouti_hide_01",
            "ingred_guar_hide_01",
            "ingred_alit_hide_01"
        }
    },

    {
        id = "hap_wolf_pelt",
        name = "Wolf Pelt",
        ids = {
            "ingred_wolf_pelt",
            "ingred_snowwolf_pelt_unique"
        }
    },

    {
        id = "hap_cephalopod",
        name = "Cephalopod Shell",
        ids = {
            "T_IngCrea_CephalopodShell_01"
        }
    },

        {
        id = "hap_bonemeal",
        name = "Bonemeal",
        ids = {
            "ingred_bonemeal_01"
        }
    },

    {
        id = "hap_steel",
        name = "Steel Ingot",
        ids = {
            "T_Com_MetalPieceSteel_01"
        }
    },

    {
        id = "hap_iron",
        name = "Iron Ingot",
        ids = {
            "T_Com_MetalPieceIron_01"
        }
    },

    {
        id = "hap_bronze",
        name = "Bronze Ingot",
        ids = {
            "T_Com_MetalPieceBronze_01"
        }
    },

    {
        id = "hap_orc",
        name = "Orichalcum Ingot",
        ids = {
            "hap_orch_ingot"
        }
    },

    {
        id = "hap_dreugh",
        name = "Dreugh Shell",
        ids = {
            "AB_IngCrea_DreughShell_01"
        }
    },

    {
        id = "hap_trollfat",
        name = "Troll Fat",
        ids = {
            "T_IngCrea_Trollfat_01"
        }
    },

    {
        id = "hap_dwemer",
        name = "Dwemer Ingot",
        ids = {
            "hap_dwemer_ingot"
        }
    },

    {
        id = "hap_gold",
        name = "Gold Ingot",
        ids = {
            "T_Com_MetalPieceGold_01",
            "T_Com_MetalPieceGold_02",
            "T_Com_MetalPieceGold_03"
        }
    },

    {
        id = "hap_ebony",
        name = "Ebony Ingot",
        ids = {
            "hap_ebony_ingot"
        }
    },

    {
        id = "hap_purple_dye",
        name = "Imperial Purple Dye",
        ids = {
            "T_IngDye_ImperialPurple_01"
        }
    },

    {
        id = "hap_red_dye",
        name = "Vermilion Dye",
        ids = {
            "T_IngDye_Vermilion_01"
        }
    },

    {
        id = "hap_yellow_dye",
        name = "Yellow Ochre Dye",
        ids = {
            "T_IngDye_YellowOchre_01"
        }
    },

    {
        id = "hap_white_dye",
        name = "White Lead Dye",
        ids = {
            "T_IngDye_WhiteLead_01"
        }
    },

    {
        id = "hap_plumes",
        name = "Feathers",
        ids = {
            "T_IngCrea_StridentBirdFeath_01",
            "T_IngCrea_HagravenFeathers_01",
            "T_IngCrea_RocFeather",
            "T_IngCrea_CanahFeather",
            "ingred_racer_plumes_01",
            "ab01ingred_bird_plumes",
            "1feather",
            "ab01ingred_bird_plumes",
            "ab01ingred_bird_plumesSmall",
            "FKA_feathers"
        }
    },

    {
        id = "hap_silver",
        name = "Silver Ingot",
        ids = {
            "T_Com_MetalPieceSilver_01",
            "T_Com_MetalPieceSilver_02",
            "T_Com_MetalPieceSilver_03"
        }
    },

    {
        id = "hap_wood",
        name = "Wood",
        ids = {
            "ashfall_firewood",
            "T_Com_Scrapwood01",
            "T_Com_Scrapwood02",
            "T_Com_Scrapwood03",
            "T_Com_Scrapwood04",
            "ashfall_branch_ac_01",
            "ashfall_branch_ac_02",
            "ashfall_branch_ai_01",
            "ashfall_branch_ai_02",
            "ashfall_branch_ai_03",
            "ashfall_branch_ash_01",
            "ashfall_branch_ash_02",
            "ashfall_branch_ash_03",
            "ashfall_branch_bc_01",
            "ashfall_branch_bc_02",
            "ashfall_branch_bc_03",
            "ashfall_branch_gl_01",
            "ashfall_branch_gl_02",
            "ashfall_branch_gl_03",
            "ashfall_branch_wg_01",
            "ashfall_branch_wg_02",
            "ashfall_branch_wg_03"
        }
    },

    {
        id = "hap_fur",
        name = "Fur",
        ids = {
            "ingred_bear_pelt",
            "ingred_snowbear_pelt_unique",
            "T_IngCrea_BearpeltBlack_01",
            "ingred_wolf_pelt",
            "ingred_snowwolf_pelt_unique",
            "T_IngCrea_FrostTrollPelt_01",
            "T_IngCrea_GoatPelt_01",
            "T_IngCrea_HorkerPupPelt_01",
            "T_IngCrea_HorkerPupPelt_02",
            "T_IngCrea_HorkerPupPelt_03",
            "ashfall_rat_pelt",
            "T_IngCrea_DonkeyHide_01"
        }
    },

    {
        id = "hap_crab",
        name = "Mole Crab Shell",
        ids = {
            "T_IngCrea_ShellMolecrab_01",
            "T_IngCrea_ShellMolecrab_02"
        }
    },

    {
        id = "hap_corkbulb",
        name = "Corkbulb",
        ids = {
            "ingred_corkbulb_root_01"
        }
    },

    {
        id = "hap_adamantium",
        name = "Adamantium Ingot",
        ids = {
            "hap_adamantium_ingot"
        }
    },

    {
        id = "hap_agate",
        name = "Fire Agate",
        ids = {
            "T_IngMine_Agate_02"
        }
    },

    {
        id = "hap_amber",
        name = "Amber",
        ids = {
            "T_IngMine_AmberDae_01",
            "T_IngMine_Amber_01",
            "AB_IngMine_Amber_01"
        }
    },

    {
        id = "hap_ruby",
        name = "Ruby",
        ids = {
            "ingred_ruby_01",
            "T_IngMine_RubyDeTomb_01",
            "ingred_Dae_cursed_ruby_01"
        }
    },

    {
        id = "hap_firejade",
        name = "Firejade",
        ids = {
            "AB_IngMine_Firejade_01"
        }
    },

    {
        id = "hap_topaz",
        name = "Topaz",
        ids = {
            "T_IngMine_Topaz_01",
            "T_IngMine_TopazDae_01"
        }
    },
    
    {
        id = "hap_malachite",
        name = "Malachite",
        ids = {
            "T_IngMine_Malouchite_01"
        }
    },

    {
        id = "hap_sapphire",
        name = "Sapphire",
        ids = {
            "AB_IngMine_Sapphire_01",
            "T_IngMine_Sapphire_01",
            "T_IngMine_SapphireDae_01"
        }
    },

    {
        id = "hap_lapis",
        name = "Lapis Lazuli",
        ids = {
            "T_IngMine_LapisLazuli_01"
        }
    },

    {
        id = "hap_emerald",
        name = "Emerald",
        ids = {
            "ingred_emerald_01",
            "ingred_Dae_cursed_emerald_01",
            "T_IngMine_EmeraldDeTomb_01"
        }
    },

    {
        id = "hap_diamond",
        name = "Diamond",
        ids = {
            "ingred_diamond_01",
            "ingred_diamond_01"
        }
    },

    {
        id = "hap_copper",
        name = "Copper Ingot",
        ids = {
            "hap_copper_ingot",
        }
    },

    {
        id = "hap_tourmaline",
        name = "Black Tourmaline",
        ids = {
            "AB_IngMine_BlackTourmaline_01"
        }
    },

    {
        id = "hap_amethyst",
        name = "Amethyst",
        ids = {
            "T_IngMine_AmethystDae_01",
            "T_IngMine_Amethyst_01",
            "AB_IngMine_Amethyst_01"
        }
    },

    {
        id = "hap_khajiiteye",
        name = "Khajiit-Eye",
        ids = {
            "T_IngMine_KhajiitEyeDae_01",
            "T_IngMine_KhajiitEye_01"
        }
    },

    {
        id = "hap_stardiopside",
        name = "Star Diopside",
        ids = {
            "AB_IngMine_Diopside_01"
        }
    },

    {
        id = "hap_alit",
        name = "Alit Hide",
        ids = {
            "ingred_alit_hide_01"
        }
    },

    {
        id = "hap_kagouti",
        name = "Kagouti Hide",
        ids = {
            "ingred_kagouti_hide_01"
        }
    },

    {
        id = "hap_guar",
        name = "Guar Hide",
        ids = {
            "ingred_guar_hide_01"
        }
    },

    {
        id = "hap_thread",
        name = "Thread",
        ids = {
            "misc_spool_01",
            "T_Com_GoldThread_01"
        }
    },

    {
        id = "hap_wood_buckler",
        name = "Wooden Buckler",
        ids = {
            "T_Nor_Wood_ShieldBuckler_06"
        }
    },

    {
        id = "hap_wood_shield",
        name = "Wooden Shield",
        ids = {
            "T_Bre_WoodenHeater_Shield_01"
        }
    },

    {
        id = "hap_paint",
        name = "Paint",
        ids = {
            "T_Com_PaintpotB_01",
            "T_Com_PaintpotB_02",
            "T_Com_PaintpotR_01",
            "T_Com_PaintpotR_02",
            "T_Com_PaintpotG_01",
            "T_Com_PaintpotG_02",
            "T_Com_PaintpotY_01",
            "T_Com_PaintpotY_02"
        }
    },

    {
        id = "hap_paintbrush",
        name = "Paint",
        ids = {
            "AB_Misc_ComPaintBrush01",
            "AB_Misc_ComPaintBrush02",
            "T_Com_Paintbrush_01",
            "T_Com_Paintbrush_02",
            "T_Com_Paintbrush_03",
            "T_Com_Paintbrush_04",
            "T_Com_Paintbrush_04B",
            "T_Com_Paintbrush_04R",
            "T_Com_Paintbrush_04G",
            "T_Com_Paintbrush_04Y",
            "_GG_Misc_BrushBig",
            "_GG_Misc_BrushSmall"
        }
    },

    {
        id = "hap_saberpelt",
        name = "Saber Cat Pelt",
        ids = {
            "hap_saber_pelt"
        }
    },

    {
        id = "hap_snowsaberpelt",
        name = "Snow Saber Cat Pelt",
        ids = {
            "hap_snow_pelt"
        }
    },

    {
        id = "hap_sabertooth",
        name = "Saber Cat Tooth",
        ids = {
            "T_IngCrea_SaberCatTooth_01"
        }
    },

    {
        id = "hap_brwolf_pelt",
        name = "Wolf Pelt",
        ids = {
            "ingred_wolf_pelt"
        }
    },

    {
        id = "hap_swolf_pelt",
        name = "Snow Wolf Pelt",
        ids = {
            "ingred_snowwolf_pelt_unique"
        }
    },

    {
        id = "hap_mithril",
        name = "Mithril Ingot",
        ids = {
            "hap_mithril_ingot"
        }
    },

    {
        id = "hap_goat",
        name = "Goat Hide",
        ids = {
            "T_IngCrea_GoatPelt_01"
        }
    },

    {
        id = "hap_chalk",
        name = "Chalk",
        ids = {
            "T_IngMine_Chalk_01",
            "AB_IngMine_ChalkWhite"
        }
    },

    {
        id = "hap_essence",
        name = "Daedra Essence",
        ids = {
            "ingred_daedras_heart_01",
            "AB_IngCrea_DaeTeeth_01",
            "ingred_cursed_daedras_heart_01",
            "ingred_daedra_skin_01",
            "ingred_scamp_skin_01",
            "AB_IngCrea_ClannClaw_01",
            "ingred_fire_salts_01",
            "ingred_frost_salts_01",
            "ingred_void_salts_01",
            "T_IngCrea_DridreaSilk_01",
            "_ce_daedremn1",
            "_ce_daedremn2",
            "_ce_daedremn3",
            "_ce_daedremn4",
            "_ce_scampe1",
            "_ce_scampe2",
            "_ce_scampe3",
            "_ce_scampe4"
        }
    },

    {
        id = "hap_pearl",
        name = "Pearl",
        ids = {
            "ingred_Dae_cursed_pearl_01",
            "ingred_pearl_01"
        }
    },

    {
        id = "hap_bone",
        name = "Bone",
        ids = {
            "T_Com_Bone",
            "T_Com_Rib",
            "T_Com_SkullAlt",
            "AB_Misc_Bone",
            "AB_Misc_BoneRacerSkull",
            "AB_Misc_BoneRatSkull",
            "AB_Misc_BoneSkelArgFoot",
            "AB_Misc_BoneSkelArgPelvis",
            "AB_Misc_BoneSkelArgSkull",
            "AB_Misc_BoneSkelArgSkullJaw",
            "AB_Misc_BoneSkelArgSkullUpper",
            "AB_Misc_BoneSkelArgTail",
            "AB_Misc_BoneSkelArmL",
            "AB_Misc_BoneSkelArmR",
            "AB_Misc_BoneSkelArmUpperL",
            "AB_Misc_BoneSkelArmUpperR",
            "AB_Misc_BoneSkelArmWristL",
            "AB_Misc_BoneSkelArmWristR",
            "AB_Misc_BoneSkelFootL",
            "AB_Misc_BoneSkelFootR",
            "AB_Misc_BoneSkelHandL",
            "AB_Misc_BoneSkelHandR",
            "AB_Misc_BoneSkelKhaFoot",
            "AB_Misc_BoneSkelKhaTail",
            "AB_Misc_BoneSkelLegL",
            "AB_Misc_BoneSkelLegR",
            "AB_Misc_BoneSkelLegShinL",
            "AB_Misc_BoneSkelLegShinR",
            "AB_Misc_BoneSkelLegUpperL",
            "AB_Misc_BoneSkelLegUpperR",
            "AB_Misc_BoneSkelPelvis",
            "AB_Misc_BoneSkelRibs",
            "AB_Misc_BoneSkelSkullGhoul",
            "AB_Misc_BoneSkelSkullJaw",
            "AB_Misc_BoneSkelSkullNoJaw",
            "AB_Misc_BoneSkelSkullUpper",
            "AB_Misc_BoneSkelTorso",
            "AB_Misc_BoneSkelTorsoBroken",
            "_ce_skelbone1",
            "_ce_skelbone2",
            "_ce_skelbone3",
            "_ce_undskull1",
            "_ce_undskull2",
            "_ce_undskull3",
            "_ce_undskull4",
            "RPNR_racer_skull"
        }
    },

    {
        id = "hap_jade",
        name = "Jade",
        ids = {
            "T_IngMine_Jade_01"
        }
    },

    {
        id = "hap_wicker",
        name = "Wicker",
        ids = {
            "ingred_wickwheat_01",
            "ashfall_straw",
            "AB_Misc_WickwheatBundle",
            "ashfall_plant_fibre"
        }
    },

    {
        id = "hap_opal",
        name = "Opal",
        ids = {
            "T_IngMine_Opal_01",
            "T_IngMine_OpalDae_01"
        }
    },

    {
        id = "hap_onyx",
        name = "Onyx",
        ids = {
            "T_IngMine_Onyx_01"
        }
    },

    {
        id = "hap_bpearl",
        name = "Black Pearl",
        ids = {
            "T_IngMine_PearlBlack_01",
            "T_IngMine_PearlBlackDae_01"
        }
    },

    {
        id = "hap_stone",
        name = "Stone",
        ids = {
            "T_Com_PumiceStone_01",
            "ashfall_stone"
        }
    },

    {
        id = "hap_turqouise",
        name = "Turqouise",
        ids = {
            "T_IngMine_Turquoise_01",
            "T_IngMine_TurquoiseDae_01"
        }
    },

    {
        id = "hap_ametrine",
        name = "Turqouise",
        ids = {
            "T_IngMine_Ametrine_01"
        }
    },

    {
        id = "hap_rosequartz",
        name = "Rose Quartz",
        ids = {
            "T_IngMine_RoseQuartz_01"
        }
    },

    {
        id = "hap_brass",
        name = "Brass Ore",
        ids = {
            "T_IngMine_OreBrass_01"
        }
    },

    {
        id = "hap_smokyquartz",
        name = "Smoky Quartz",
        ids = {
            "T_IngMine_SmokyQuartz_01"
        }
    },

    {
        id = "hap_moonstone",
        name = "Moonstone",
        ids = {
            "T_IngMine_Moonstone_01",
            "T_IngMine_MoonstoneDae_01"
        }
    },

    {
        id = "hap_fireopal",
        name = "Fire Opal",
        ids = {
            "T_IngMine_FireOpal_01"
        }
    },

    {
        id = "hap_obsidian",
        name = "Obsidian",
        ids = {
            "AB_IngMine_Obsidian_01"
        }
    },

    {
        id = "hap_ragate",
        name = "Rainbow Agate",
        ids = {
            "T_IngMine_Agate_01"
        }
    },

    {
        id = "hap_ratskull",
        name = "Rat Skull",
        ids = {
            "AB_Misc_BoneRatSkull"
        }
    },

    {
        id = "hap_daedric",
        name = "Daedric Ingot",
        ids = {
            "hap_daedric_ingot"
        }
    },

    {
        id = "hap_clay",
        name = "Clay",
        ids = {
            "AB_IngMine_Clay01",
            "AB_IngMine_Clay02",
            "1clay"
        }
    },

    -- Smelter
    {
        id = "hap_iron_ore",
        name = "Iron Ore",
        ids = {
            "T_IngMine_OreIron_01"
        }
    },

    {
        id = "hap_boiled_leather",
        name = "Netch Leather",
        ids = {
            "ingred_netch_leather_01"
        }
    },

    {
        id = "hap_dwemer_ore",
        name = "Dwemer Metal",
        ids = {
            "misc_dwrv_gear00",
            "_ce_csteam1",
            "_ce_csteam2",
            "_ce_csteam3",
            "_ce_csteam4",
            "ingred_scrap_metal_01",
            "AB_Misc_DwrvDisk00",
            "AB_Misc_DwrvCoil00",
            "T_Dwe_Coil_01",
            "T_Dwe_Disk_01"
        }
    },

    {
        id = "hap_orc_ore",
        name = "Orichalcum Ore",
        ids = {
            "T_IngMine_OreOrichalcum_01"
        }
    },

    {
        id = "hap_tin",
        name = "Raw Tin",
        ids = {
            "T_IngMine_OreTin_01"
        }
    },

    {
        id = "hap_copper_ore",
        name = "Copper Ore",
        ids = {
            "T_IngMine_OreCopper_01"
        }
    },

    {
        id = "hap_gold_ore",
        name = "Gold Ore",
        ids = {
            "T_IngMine_OreGold_01"
        }
    },

    {
        id = "hap_ebony_ore",
        name = "Ebony Ore",
        ids = {
            "ingred_raw_ebony_01"
        }
    },

    {
        id = "hap_silver_ore",
        name = "Silver Ore",
        ids = {
            "T_IngMine_OreSilver_01"
        }
    },

    {
        id = "hap_glass_raw",
        name = "Raw Glass",
        ids = {
            "ingred_raw_glass_01"
        }
    },

    {
        id = "hap_adamantium_ore",
        name = "Adamantium Ore",
        ids = {
            "ingred_adamantium_ore_01"
        }
    }
}

CraftingFramework.Material:registerMaterials(materials)