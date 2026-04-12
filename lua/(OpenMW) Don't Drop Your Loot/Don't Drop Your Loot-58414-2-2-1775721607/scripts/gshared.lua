return {
    KHAJIIT_RACE = {
        ["khajiit"]           = true,
        ["t_els_cathay"]      = true,
        ["t_els_cathay-raht"] = true,
        ["t_els_ohmes"]       = true,
        ["t_els_ohmes-raht"]  = true,
        ["t_els_suthay"]      = true,
        ["t_els_dagi-raht"]   = true,
    },
    -- They won't report you
    EXEMPT_FACTIONS = {
        ["thieves guild"] = true,
        ["camonna tong"]  = true,
        ["telvanni"]      = true,
    },
    -- No one will report you or take you items here
    EXEMPT_CELLS = {
        -- ["cell_id_here"] = true,
    },
    -- The Khajiit love these
    NARCOTIC = {
        ["potion_skooma_01"]     = true,
        ["ingred_moon_sugar_01"] = true,
    },
    CONTRABAND = {
        ["ingred_raw_glass_01"]            = true,
        ["ingred_raw_ebony_01"]            = true,
        ["ingred_dae_cursed_raw_ebony_01"] = true,
        ["ingred_human_meat_01"]           = true,
        ["amulet of 6th house"]            = true,
        ["ingred_6th_corprusmeat_01"]      = true,
        ["ingred_6th_corprusmeat_02"]      = true,
        ["ingred_6th_corprusmeat_03"]      = true,
        ["ingred_6th_corprusmeat_04"]      = true,
        ["ingred_6th_corprusmeat_05"]      = true,
        ["ingred_6th_corprusmeat_06"]      = true,
        ["ingred_6th_corprusmeat_07"]      = true,
        ["misc_6th_ash_statue_01"]         = true,
        ["misc_dwrv_artifact50"]           = true,
        ["misc_coin00"]                    = true,
        ["misc_dwrv_pitcher00"]            = true,
        ["misc_dwrv_artifact60"]           = true,
        ["misc_dwrv_artifact00"]           = true,
        ["misc_dwrv_goblet10"]             = true,
        ["misc_dwrv_goblet00"]             = true,
        ["misc_dwrv_mug00"]               = true,
        ["misc_dwrv_bowl00"]              = true,
    },
    -- That's what EXEMPT_CLASSES pick up from CONTRABAND
    PAUPER_CONTRABAND = {
        ["ingred_raw_glass_01"]            = true,
        ["ingred_raw_ebony_01"]            = true,
        ["ingred_dae_cursed_raw_ebony_01"] = true,
        ["amulet of 6th house"]            = true,
    },
    -- Don't change that
    GOLD_IDS = {
        ["gold_001"] = true,
        ["gold_005"] = true,
        ["gold_010"] = true,
        ["gold_025"] = true,
        ["gold_100"] = true,
    },
    -- They won't report you
    EXEMPT_NPCS = {
        -- ["npc_id_here"] = true,
    },
    -- They won't report you and won't pick up your stuff
    EXEMPT_NPCS_FULL = {
        -- ["npc_id_here"] = true,
    },
    -- They won't report you but pick up your stuff
    EXEMPT_CLASSES = {
        ["pauper"] = true,
    },
    -- They won't be lured to pick up items (but still pick up in pickup radius)
    LURE_EXCLUDED = {
        ["vd_tarancur"] = true,
    },
    -- Default settings, don't change these
    DEFAULTS = {
        PICKUP_RADIUS       = 200,
        CONTRABAND_RADIUS   = 600,
        PICKUP_DELAY        = 2.0,
        CHAMELEON_THRESHOLD = 85,
        SNEAK_THRESHOLD     = 75,
        SIGN_COMPAT         = false,
        MIN_APPARATUS       = 100,
        MIN_BOOK            = 100,
        MIN_CLOTHING        = 25,
        MIN_ARMOR           = 300,
        MIN_WEAPON          = 300,
        MIN_INGREDIENT      = 99,
        MIN_POTION          = 60,
        MIN_LOCKPICK        = 99,
        MIN_PROBE           = 99,
        MIN_REPAIR          = 99,
        MIN_MISC            = 200,
        PICKUP_ENABLED      = true,
        CRIME_ENABLED       = true,
        RANK_EXEMPT_ENABLED = true,
        RANK_EXEMPT_DIFF    = 3,
        ESCORT_FOLLOW_BUSY  = true,
        EQUIP_ARMOR         = true,
        SHOW_PICKUP_MESSAGES = true,
        SHOW_HEAVY_MESSAGES  = true,
        -- Lure mechanic
        LURE_ENABLED        = true,
        LURE_RADIUS         = 500,
        LURE_PICKUP_DELAY   = 1.0,
        LURE_RETURN_DELAY   = 1.5,
        LURE_LINGER_DELAY   = 2.0,
    },
}