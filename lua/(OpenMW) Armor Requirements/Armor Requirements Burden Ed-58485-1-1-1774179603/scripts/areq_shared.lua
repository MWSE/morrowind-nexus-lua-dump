return {
    ARMOR_ATTR = {
        heavyarmor  = "endurance",
        mediumarmor = "endurance",
        lightarmor  = "agility",
    },
    SKILL_NAMES = {
        heavyarmor  = "Heavy Armor",
        mediumarmor = "Medium Armor",
        lightarmor  = "Light Armor",
    },
    ATTR_NAMES = {
        endurance = "Endurance",
        agility   = "Agility",
    },
    -- Add armor record IDs here to exempt them from all checks
    EXCLUDED_IDS = {
        -- ["armor_id_here"] = true,
    },
    -- Don't change that
    DEFAULTS = {
        MOD_ENABLED         = true,
        HEAVY_ENABLED       = true,
        MEDIUM_ENABLED      = true,
        LIGHT_ENABLED       = true,
        BOUND_CHECK_ENABLED = true,
        HEAVY_T2_RATING  = 16, HEAVY_T3_RATING  = 59, HEAVY_T4_RATING  = 65,
        HEAVY_T2_SKILL   = 30, HEAVY_T3_SKILL   = 60, HEAVY_T4_SKILL   = 80,
        HEAVY_T2_ATTR    = 30, HEAVY_T3_ATTR    = 60, HEAVY_T4_ATTR    = 80,
        MEDIUM_T2_RATING = 15, MEDIUM_T3_RATING = 39, MEDIUM_T4_RATING = 44,
        MEDIUM_T2_SKILL  = 30, MEDIUM_T3_SKILL  = 60, MEDIUM_T4_SKILL  = 80,
        MEDIUM_T2_ATTR   = 30, MEDIUM_T3_ATTR   = 60, MEDIUM_T4_ATTR   = 80,
        LIGHT_T2_RATING  =  8, LIGHT_T3_RATING  = 19, LIGHT_T4_RATING  = 44,
        LIGHT_T2_SKILL   = 30, LIGHT_T3_SKILL   = 60, LIGHT_T4_SKILL   = 80,
        LIGHT_T2_ATTR    = 30, LIGHT_T3_ATTR    = 60, LIGHT_T4_ATTR    = 80,
    },
}