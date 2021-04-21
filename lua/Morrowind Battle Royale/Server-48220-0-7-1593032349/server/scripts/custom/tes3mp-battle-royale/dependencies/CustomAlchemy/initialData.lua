local keyOrder = {
    "instances",
    "weight",
    "burdenId",
    "apparatuses",
    "effects",
    "ingerdients",
}
local default = {
    instances = {},
    weight = {},
    burdenId = {},
    ["apparatuses"] = {
        ["apparatus_a_mortar_01"] = {
            ["type"] = 1,
            ["tier"] = 1,
            ["quality"] = 0.5
        },
        ["apparatus_a_alembic_01"] = {
            ["type"] = 2,
            ["tier"] = 1,
            ["quality"] = 0.5
        },
        ["apparatus_a_calcinator_01"] = {
            ["type"] = 3,
            ["tier"] = 1,
            ["quality"] = 0.5
        },
        ["apparatus_a_retort_01"] = {
            ["type"] = 4,
            ["tier"] = 1,
            ["quality"] = 0.5
        },
        ["apparatus_j_mortar_01"] = {
            ["type"] = 1,
            ["tier"] = 2,
            ["quality"] = 1
        },
        ["apparatus_j_alembic_01"] = {
            ["type"] = 2,
            ["tier"] = 2,
            ["quality"] = 1
        },
        ["apparatus_j_calcinator_01"] = {
            ["type"] = 3,
            ["tier"] = 2,
            ["quality"] = 1
        },
        ["apparatus_j_retort_01"] = {
            ["type"] = 4,
            ["tier"] = 2,
            ["quality"] = 1
        },
        ["apparatus_m_mortar_01"] = {
            ["type"] = 1,
            ["tier"] = 3,
            ["quality"] = 1.2
        },
        ["apparatus_m_alembic_01"] = {
            ["type"] = 2,
            ["tier"] = 3,
            ["quality"] = 1.2
        },
        ["apparatus_m_calcinator_01"] = {
            ["type"] = 3,
            ["tier"] = 3,
            ["quality"] = 1.2
        },
        ["apparatus_m_retort_01"] = {
            ["type"] = 4,
            ["tier"] = 3,
            ["quality"] = 1.2
        },
        ["apparatus_g_mortar_01"] = {
            ["type"] = 1,
            ["tier"] = 4,
            ["quality"] = 1.5
        },
        ["apparatus_g_alembic_01"] = {
            ["type"] = 2,
            ["tier"] = 4,
            ["quality"] = 1.5
        },
        ["apparatus_g_calcinator_01"] = {
            ["type"] = 3,
            ["tier"] = 4,
            ["quality"] = 1.5
        },
        ["apparatus_g_retort_01"] = {
            ["type"] = 4,
            ["tier"] = 4,
            ["quality"] = 1.5
        },
        ["apparatus_sm_mortar_01"] = {
            ["type"] = 1,
            ["tier"] = 5,
            ["quality"] = 2
        },
        ["apparatus_sm_alembic_01"] = {
            ["type"] = 2,
            ["tier"] = 5,
            ["quality"] = 2
        },
        ["apparatus_sm_calcinator_01"] = {
            ["type"] = 3,
            ["tier"] = 5,
            ["quality"] = 2
        },
        ["apparatus_sm_retort_01"] = {
            ["type"] = 4,
            ["tier"] = 5,
            ["quality"] = 2
        },
        ["apparatus_a_spipe_01"] = {
            ["type"] = 2,
            ["tier"] = -1,
            ["quality"] = 0.15
        },
        ["apparatus_a_spipe_tsiya"] = {
            ["type"] = 2,
            ["tier"] = -1,
            ["quality"] = 0.15
        }
    },
    ["ingredients"] = {
        ["ingred_saltrice_01"] = {
            ["effects"] = {77,81,17,75},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_emerald_01"] = {
            ["effects"] = {81,75,17,17},
            ["attributes"] = {0, 0, 3, 5},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_ash_yam_01"] = {
            ["effects"] = {79,79,94,66},
            ["attributes"] = {1, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_moon_sugar_01"] = {
            ["effects"] = {79,57,17,17},
            ["attributes"] = {4, 0, 5, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bread_01"] = {
            ["effects"] = {77,-1,-1,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_human_meat_01"] = {
            ["effects"] = {80,17,17,-1},
            ["attributes"] = {-1, 1, 6, -1},
            ["skills"] = {-1, 0, 0, -1},
            ["weight"] = 1.0000
        },
        ["ingred_emerald_pinetear"] = {
            ["effects"] = {81,75,17,17},
            ["attributes"] = {-1, -1, 3, 5},
            ["skills"] = {-1, -1, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_raw_stalhrim_01"] = {
            ["effects"] = {91,16,45,75},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 5.0000
        },
        ["ingred_blood_innocent_unique"] = {
            ["effects"] = {17,41,69,19},
            ["attributes"] = {4, -1, -1, -1},
            ["skills"] = {0, -1, -1, -1},
            ["weight"] = 0.1000
        },
        ["ingred_snowwolf_pelt_unique"] = {
            ["effects"] = {20,79,94,43},
            ["attributes"] = {-1, 4, -1, -1},
            ["skills"] = {-1, 0, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_snowbear_pelt_unique"] = {
            ["effects"] = {20,79,94,43},
            ["attributes"] = {-1, 4, -1, -1},
            ["skills"] = {-1, 0, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_udyrfrykte_heart"] = {
            ["effects"] = {76,79,17,43},
            ["attributes"] = {-1, 5, 3, -1},
            ["skills"] = {-1, 0, 0, -1},
            ["weight"] = 5.0000
        },
        ["ingred_belladonna_01"] = {
            ["effects"] = {93,76,81,19},
            ["attributes"] = {1, -1, 5, -1},
            ["skills"] = {0, -1, 0, -1},
            ["weight"] = 0.1000
        },
        ["ingred_wolfsbane_01"] = {
            ["effects"] = {74,39,17,19},
            ["attributes"] = {1, -1, 5, -1},
            ["skills"] = {0, -1, 0, -1},
            ["weight"] = 0.1000
        },
        ["ingred_holly_01"] = {
            ["effects"] = {91,6,16,28},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 0.1000
        },
        ["ingred_belladonna_02"] = {
            ["effects"] = {93,76,81,19},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 0.1000
        },
        ["ingred_bear_pelt"] = {
            ["effects"] = {20,79,94,43},
            ["attributes"] = {-1, 0, -1, -1},
            ["skills"] = {-1, 0, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_wolf_pelt"] = {
            ["effects"] = {20,79,94,43},
            ["attributes"] = {-1, 4, -1, -1},
            ["skills"] = {-1, 0, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_innocent_heart"] = {
            ["effects"] = {76,79,17,43},
            ["attributes"] = {-1, 5, 3, -1},
            ["skills"] = {-1, 0, 0, -1},
            ["weight"] = 1.0000
        },
        ["ingred_wolf_heart"] = {
            ["effects"] = {76,79,17,43},
            ["attributes"] = {-1, 5, 3, -1},
            ["skills"] = {-1, 0, 0, -1},
            ["weight"] = 1.0000
        },
        ["ingred_heartwood_01"] = {
            ["effects"] = {76,79,17,28},
            ["attributes"] = {-1, 3, 0, -1},
            ["skills"] = {-1, 0, 0, -1},
            ["weight"] = 1.0000
        },
        ["ingred_boar_leather"] = {
            ["effects"] = {47,16,91,61},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_horker_tusk_01"] = {
            ["effects"] = {21,79,84,64},
            ["attributes"] = {0, 1, -1, -1},
            ["skills"] = {11, 0, -1, -1},
            ["weight"] = 0.1000
        },
        ["ingred_gravetar_01"] = {
            ["effects"] = {91,18,82,17},
            ["attributes"] = {-1, -1, -1, 7},
            ["skills"] = {-1, -1, -1, 0},
            ["weight"] = 0.1000
        },
        ["ingred_eyeball"] = {
            ["effects"] = {91,43,19,79},
            ["attributes"] = {-1, -1, -1, 0},
            ["skills"] = {-1, -1, -1, 0},
            ["weight"] = 1.0000
        },
        ["ingred_eyeball_unique"] = {
            ["effects"] = {91,43,19,79},
            ["attributes"] = {-1, -1, -1, 0},
            ["skills"] = {-1, -1, -1, 0},
            ["weight"] = 1.0000
        },
        ["ingred_russula_01"] = {
            ["effects"] = {0,20,27,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_horn_lily_bulb_01"] = {
            ["effects"] = {99,18,74,74},
            ["attributes"] = {-1, -1, 0, 5},
            ["skills"] = {-1, -1, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_nirthfly_stalks_01"] = {
            ["effects"] = {23,79,74,17},
            ["attributes"] = {-1, 4, 4, 4},
            ["skills"] = {-1, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_timsa-come-by_01"] = {
            ["effects"] = {57,99,19,74},
            ["attributes"] = {-1, -1, -1, 5},
            ["skills"] = {-1, -1, -1, 0},
            ["weight"] = 1.0000
        },
        ["ingred_meadow_rye_01"] = {
            ["effects"] = {79,23,74,17},
            ["attributes"] = {4, -1, 4, 4},
            ["skills"] = {0, -1, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_sweetpulp_01"] = {
            ["effects"] = {45,10,99,75},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_scrib_cabbage_01"] = {
            ["effects"] = {17,23,74,79},
            ["attributes"] = {1, -1, 3, 3},
            ["skills"] = {0, -1, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_lloramor_spines_01"] = {
            ["effects"] = {67,39,27,65},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_golden_sedge_01"] = {
            ["effects"] = {19,79,117,1},
            ["attributes"] = {-1, 0, -1, -1},
            ["skills"] = {-1, 0, -1, -1},
            ["weight"] = 1.0000
        },
        ["ingred_noble_sedge_01"] = {
            ["effects"] = {23,74,27,79},
            ["attributes"] = {-1, 3, -1, 3},
            ["skills"] = {-1, 0, -1, 0},
            ["weight"] = 1.0000
        },
        ["ingred_adamantium_ore_01"] = {
            ["effects"] = {7,76,27,68},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 50.0000
        },
        ["ingred_durzog_meat_01"] = {
            ["effects"] = {79,79,47,24},
            ["attributes"] = {3, 0, -1, -1},
            ["skills"] = {0, 0, -1, -1},
            ["weight"] = 2.0000
        },
        ["ingred_dreugh_wax_01"] = {
            ["effects"] = {79,74,17,17},
            ["attributes"] = {0, 0, 7, 2},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["food_kwama_egg_01"] = {
            ["effects"] = {77,-1,-1,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {-1, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["food_kwama_egg_02"] = {
            ["effects"] = {77,45,6,80},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {-1, 0, 0, 0},
            ["weight"] = 2.0000
        },
        ["ingred_kwama_cuttle_01"] = {
            ["effects"] = {97,20,2,0},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_marshmerrow_01"] = {
            ["effects"] = {75,65,17,20},
            ["attributes"] = {0, 0, 2, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_saltrice_01"] = {
            ["effects"] = {77,81,17,75},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_diamond_01"] = {
            ["effects"] = {17,39,68,66},
            ["attributes"] = {3, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_emerald_01"] = {
            ["effects"] = {81,75,17,17},
            ["attributes"] = {0, 0, 3, 5},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_pearl_01"] = {
            ["effects"] = {17,57,0,94},
            ["attributes"] = {3, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_raw_ebony_01"] = {
            ["effects"] = {17,72,6,74},
            ["attributes"] = {3, 0, 0, 4},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 10.0000
        },
        ["ingred_ruby_01"] = {
            ["effects"] = {18,8,74,17},
            ["attributes"] = {0, 0, 1, 3},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_ash_salts_01"] = {
            ["effects"] = {17,93,70,93},
            ["attributes"] = {3, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_corprus_weepings_01"] = {
            ["effects"] = {20,79,17,75},
            ["attributes"] = {0, 7, 2, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_crab_meat_01"] = {
            ["effects"] = {77,92,5,74},
            ["attributes"] = {0, 0, 0, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_daedras_heart_01"] = {
            ["effects"] = {76,79,17,43},
            ["attributes"] = {0, 5, 3, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_daedra_skin_01"] = {
            ["effects"] = {79,69,45,1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_resin_01"] = {
            ["effects"] = {75,74,7,94},
            ["attributes"] = {0, 4, 0, 4},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_alit_hide_01"] = {
            ["effects"] = {17,97,59,64},
            ["attributes"] = {1, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_ash_yam_01"] = {
            ["effects"] = {79,79,94,66},
            ["attributes"] = {1, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_bittergreen_petals_01"] = {
            ["effects"] = {74,39,17,19},
            ["attributes"] = {1, 0, 5, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_black_anther_01"] = {
            ["effects"] = {17,90,17,41},
            ["attributes"] = {3, 0, 5, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_black_lichen_01"] = {
            ["effects"] = {17,91,17,72},
            ["attributes"] = {0, 0, 4, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bloat_01"] = {
            ["effects"] = {19,79,79,64},
            ["attributes"] = {0, 1, 2, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bonemeal_01"] = {
            ["effects"] = {74,59,20,17},
            ["attributes"] = {3, 0, 0, 6},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_comberry_01"] = {
            ["effects"] = {20,76,4,68},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_chokeweed_01"] = {
            ["effects"] = {17,77,69,17},
            ["attributes"] = {7, 0, 0, 2},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_corkbulb_root_01"] = {
            ["effects"] = {73,75,5,79},
            ["attributes"] = {0, 0, 0, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_ectoplasm_01"] = {
            ["effects"] = {79,64,17,18},
            ["attributes"] = {3, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_fire_salts_01"] = {
            ["effects"] = {18,79,91,4},
            ["attributes"] = {0, 3, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_frost_salts_01"] = {
            ["effects"] = {17,76,6,90},
            ["attributes"] = {4, 0, 7, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_ghoul_heart_01"] = {
            ["effects"] = {45,72,117,-1},
            ["attributes"] = {6, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_gold_kanet_01"] = {
            ["effects"] = {18,7,17,74},
            ["attributes"] = {0, 0, 7, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_gravedust_01"] = {
            ["effects"] = {17,69,19,74},
            ["attributes"] = {1, 0, 0, 5},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_green_lichen_01"] = {
            ["effects"] = {79,69,17,18},
            ["attributes"] = {6, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_guar_hide_01"] = {
            ["effects"] = {20,79,74,79},
            ["attributes"] = {0, 5, 6, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_hackle-lo_leaf_01"] = {
            ["effects"] = {77,45,0,74},
            ["attributes"] = {0, 0, 0, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_heather_01"] = {
            ["effects"] = {74,8,17,17},
            ["attributes"] = {6, 0, 4, 6},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_hound_meat_01"] = {
            ["effects"] = {77,82,68,65},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_kagouti_hide_01"] = {
            ["effects"] = {20,79,94,43},
            ["attributes"] = {0, 4, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_kresh_fiber_01"] = {
            ["effects"] = {74,79,19,17},
            ["attributes"] = {7, 6, 0, 4},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_moon_sugar_01"] = {
            ["effects"] = {79,57,17,17},
            ["attributes"] = {4, 0, 5, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_muck_01"] = {
            ["effects"] = {17,66,17,69},
            ["attributes"] = {1, 0, 6, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_netch_leather_01"] = {
            ["effects"] = {79,79,17,73},
            ["attributes"] = {5, 1, 6, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_racer_plumes_01"] = {
            ["effects"] = {17,10,-1,-1},
            ["attributes"] = {2, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_rat_meat_01"] = {
            ["effects"] = {19,45,72,97},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_raw_glass_01"] = {
            ["effects"] = {17,17,17,4},
            ["attributes"] = {1, 0, 4, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 2.0000
        },
        ["ingred_red_lichen_01"] = {
            ["effects"] = {17,41,69,19},
            ["attributes"] = {4, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_roobrush_01"] = {
            ["effects"] = {17,79,18,72},
            ["attributes"] = {2, 3, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_scales_01"] = {
            ["effects"] = {17,2,74,1},
            ["attributes"] = {6, 0, 5, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_scamp_skin_01"] = {
            ["effects"] = {19,73,74,74},
            ["attributes"] = {0, 0, 6, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_scathecraw_01"] = {
            ["effects"] = {17,72,18,74},
            ["attributes"] = {0, 0, 0, 2},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_scrap_metal_01"] = {
            ["effects"] = {18,5,92,74},
            ["attributes"] = {0, 0, 0, 1},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 10.0000
        },
        ["ingred_scrib_jelly_01"] = {
            ["effects"] = {79,72,70,74},
            ["attributes"] = {2, 0, 0, 2},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_scuttle_01"] = {
            ["effects"] = {77,82,8,59},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_shalk_resin_01"] = {
            ["effects"] = {20,80,17,79},
            ["attributes"] = {0, 0, 6, 4},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_sload_soap_01"] = {
            ["effects"] = {17,79,4,74},
            ["attributes"] = {6, 3, 0, 3},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_stoneflower_petals_01"] = {
            ["effects"] = {74,81,17,79},
            ["attributes"] = {0, 0, 7, 6},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_trama_root_01"] = {
            ["effects"] = {74,10,19,17},
            ["attributes"] = {2, 0, 0, 4},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_vampire_dust_01"] = {
            ["effects"] = {80,79,67,133},
            ["attributes"] = {0, 0, 0, 6},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_void_salts_01"] = {
            ["effects"] = {76,67,45,17},
            ["attributes"] = {0, 0, 0, 5},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_wickwheat_01"] = {
            ["effects"] = {75,79,45,22},
            ["attributes"] = {3, 2, 0, 1},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_willow_anther_01"] = {
            ["effects"] = {17,6,69,73},
            ["attributes"] = {6, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_scrib_jerky_01"] = {
            ["effects"] = {77,82,7,1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_fire_petal_01"] = {
            ["effects"] = {90,18,67,45},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bread_01"] = {
            ["effects"] = {77,-1,-1,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_coprinus_01"] = {
            ["effects"] = {2,20,27,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_russula_01"] = {
            ["effects"] = {0,20,27,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_bc_ampoule_pod"] = {
            ["effects"] = {2,45,64,17},
            ["attributes"] = {0, 0, 0, 2},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bc_bungler's_bane"] = {
            ["effects"] = {17,17,57,17},
            ["attributes"] = {4, 5, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_bc_hypha_facia"] = {
            ["effects"] = {17,17,20,65},
            ["attributes"] = {7, 3, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bc_spore_pod"] = {
            ["effects"] = {17,20,66,45},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bc_coda_flower"] = {
            ["effects"] = {17,10,17,18},
            ["attributes"] = {6, 0, 1, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_guar_hide_girith"] = {
            ["effects"] = {20,79,74,79},
            ["attributes"] = {0, 5, 6, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_guar_hide_marsus"] = {
            ["effects"] = {20,79,74,79},
            ["attributes"] = {0, 5, 6, 7},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_raw_glass_tinos"] = {
            ["effects"] = {17,17,17,4},
            ["attributes"] = {1, 0, 4, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 2.0000
        },
        ["ingred_treated_bittergreen_uniq"] = {
            ["effects"] = {74,19,17,39},
            ["attributes"] = {1, 0, 5, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_gold_kanet_unique"] = {
            ["effects"] = {18,7,17,74},
            ["attributes"] = {-1, -1, 7, 0},
            ["skills"] = {-1, -1, 0, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bread_01_uni2"] = {
            ["effects"] = {77,-1,-1,-1},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 0.2000
        },
        ["poison_goop00"] = {
            ["effects"] = {35,23,25,27},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 0.1000
        },
        ["ingred_dae_cursed_emerald_01"] = {
            ["effects"] = {81,75,17,17},
            ["attributes"] = {-1, -1, 3, 5},
            ["skills"] = {-1, -1, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_dae_cursed_pearl_01"] = {
            ["effects"] = {17,57,0,94},
            ["attributes"] = {3, -1, -1, -1},
            ["skills"] = {0, -1, -1, -1},
            ["weight"] = 0.2000
        },
        ["ingred_cursed_daedras_heart_01"] = {
            ["effects"] = {76,79,17,43},
            ["attributes"] = {-1, 5, 3, -1},
            ["skills"] = {-1, 0, 0, -1},
            ["weight"] = 1.0000
        },
        ["ingred_dae_cursed_diamond_01"] = {
            ["effects"] = {17,39,68,66},
            ["attributes"] = {3, -1, -1, -1},
            ["skills"] = {0, -1, -1, -1},
            ["weight"] = 0.2000
        },
        ["ingred_dae_cursed_ruby_01"] = {
            ["effects"] = {18,8,74,17},
            ["attributes"] = {-1, -1, 1, 3},
            ["skills"] = {-1, -1, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_dae_cursed_raw_ebony_01"] = {
            ["effects"] = {17,72,6,74},
            ["attributes"] = {3, -1, -1, 4},
            ["skills"] = {0, -1, -1, 0},
            ["weight"] = 10.0000
        },
        ["ingred_human_meat_01"] = {
            ["effects"] = {80,17,17,-1},
            ["attributes"] = {-1, 1, 6, -1},
            ["skills"] = {-1, 0, 0, -1},
            ["weight"] = 1.0000
        },
        ["ingred_6th_corprusmeat_01"] = {
            ["effects"] = {20,18,19,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_6th_corprusmeat_02"] = {
            ["effects"] = {20,18,19,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_6th_corprusmeat_03"] = {
            ["effects"] = {20,18,19,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_6th_corprusmeat_04"] = {
            ["effects"] = {20,18,19,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.0000
        },
        ["ingred_6th_corprusmeat_05"] = {
            ["effects"] = {20,18,19,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 1.0000
        },
        ["ingred_6th_corprusmeat_06"] = {
            ["effects"] = {20,18,19,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.5000
        },
        ["ingred_6th_corprusmeat_07"] = {
            ["effects"] = {20,18,19,-1},
            ["attributes"] = {0, 0, 0, 0},
            ["skills"] = {0, 0, 0, 0},
            ["weight"] = 0.2000
        },
        ["ingred_scrib_jelly_02"] = {
            ["effects"] = {79,72,70,74},
            ["attributes"] = {2, -1, -1, 2},
            ["skills"] = {0, -1, -1, 0},
            ["weight"] = 0.1000
        },
        ["ingred_bread_01_uni3"] = {
            ["effects"] = {77,-1,-1,-1},
            ["attributes"] = {-1, -1, -1, -1},
            ["skills"] = {-1, -1, -1, -1},
            ["weight"] = 0.2000
        },
    },
    ["effects"] = {
        ["0"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["1"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["2"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["3"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["4"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["5"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["6"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["7"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["8"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["9"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["10"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["11"] = {
            ["cost"] = 3.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["12"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = false
        },
        ["13"] = {
            ["cost"] = 6.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = false
        },
        ["14"] = {
            ["cost"] = 5.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["15"] = {
            ["cost"] = 7.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["16"] = {
            ["cost"] = 5.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["17"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["18"] = {
            ["cost"] = 4.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["19"] = {
            ["cost"] = 4.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["20"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["21"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["22"] = {
            ["cost"] = 8.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["23"] = {
            ["cost"] = 8.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["24"] = {
            ["cost"] = 8.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["25"] = {
            ["cost"] = 4.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["26"] = {
            ["cost"] = 8.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["27"] = {
            ["cost"] = 9.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["28"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["29"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["30"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["31"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["32"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["33"] = {
            ["cost"] = 4.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["34"] = {
            ["cost"] = 4.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["35"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["36"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["37"] = {
            ["cost"] = 6.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["38"] = {
            ["cost"] = 6.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["39"] = {
            ["cost"] = 20.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["40"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["41"] = {
            ["cost"] = 0.20,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["42"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["43"] = {
            ["cost"] = 0.20,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["44"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["45"] = {
            ["cost"] = 40.00,
            ["negative"] = true,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["46"] = {
            ["cost"] = 40.00,
            ["negative"] = true,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["47"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["48"] = {
            ["cost"] = 3.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["49"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["50"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["51"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["52"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["53"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["54"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["55"] = {
            ["cost"] = 0.20,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["56"] = {
            ["cost"] = 0.20,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["57"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = false
        },
        ["58"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["59"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["60"] = {
            ["cost"] = 350.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["61"] = {
            ["cost"] = 350.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["62"] = {
            ["cost"] = 150.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["63"] = {
            ["cost"] = 150.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["64"] = {
            ["cost"] = 0.75,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["65"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["66"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["67"] = {
            ["cost"] = 10.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["68"] = {
            ["cost"] = 10.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["69"] = {
            ["cost"] = 300.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["70"] = {
            ["cost"] = 2000.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["71"] = {
            ["cost"] = 2500.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["72"] = {
            ["cost"] = 100.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["73"] = {
            ["cost"] = 100.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["74"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["75"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["76"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["77"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["78"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["79"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["80"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["81"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["82"] = {
            ["cost"] = 0.50,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["83"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["84"] = {
            ["cost"] = 4.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["85"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["86"] = {
            ["cost"] = 8.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["87"] = {
            ["cost"] = 8.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["88"] = {
            ["cost"] = 4.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["89"] = {
            ["cost"] = 2.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["90"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["91"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["92"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["93"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["94"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["95"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["96"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["97"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["98"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["99"] = {
            ["cost"] = 0.20,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["100"] = {
            ["cost"] = 15.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["101"] = {
            ["cost"] = 0.20,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["102"] = {
            ["cost"] = 12.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["103"] = {
            ["cost"] = 22.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["104"] = {
            ["cost"] = 32.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["105"] = {
            ["cost"] = 28.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["106"] = {
            ["cost"] = 7.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["107"] = {
            ["cost"] = 13.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["108"] = {
            ["cost"] = 13.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["109"] = {
            ["cost"] = 15.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["110"] = {
            ["cost"] = 25.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["111"] = {
            ["cost"] = 52.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["112"] = {
            ["cost"] = 29.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["113"] = {
            ["cost"] = 55.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["114"] = {
            ["cost"] = 23.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["115"] = {
            ["cost"] = 27.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["116"] = {
            ["cost"] = 38.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["117"] = {
            ["cost"] = 1.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["118"] = {
            ["cost"] = 15.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["119"] = {
            ["cost"] = 15.00,
            ["negative"] = false,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["120"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["121"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["122"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["123"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["124"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["125"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["126"] = {
            ["cost"] = 0.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["127"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["128"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["129"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["130"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["131"] = {
            ["cost"] = 2.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["132"] = {
            ["cost"] = 2500.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["133"] = {
            ["cost"] = 5.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = false
        },
        ["134"] = {
            ["cost"] = 25.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["135"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = true,
            ["hasDuration"] = true
        },
        ["136"] = {
            ["cost"] = 1.00,
            ["negative"] = true,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["137"] = {
            ["cost"] = 10.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["138"] = {
            ["cost"] = 30.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["139"] = {
            ["cost"] = 30.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        },
        ["140"] = {
            ["cost"] = 30.00,
            ["negative"] = false,
            ["hasMagnitude"] = false,
            ["hasDuration"] = true
        }
    }
}

return { default = default, keyOrder = keyOrder}