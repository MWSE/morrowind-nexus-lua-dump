return {
    -- add weapon record IDs here to exempt them from all checks
    IGNORED_IDS = {
        -- ["weapon_id_here"] = true,
    },

    ATTR_NAMES = {
        strength  = "Strength",
        agility   = "Agility",
        speed     = "Speed",
        endurance = "Endurance",
    },

    SKILL_NAMES = {
        axe         = "Axe",
        bluntweapon = "Blunt Weapon",
        longblade   = "Long Blade",
        shortblade  = "Short Blade",
        spear       = "Spear",
        marksman    = "Marksman",
    },

    BURDEN_SPELLS = {
        [2] = "wreqd_burden_t2",
        [3] = "wreqd_burden_t3",
        [4] = "wreqd_burden_t4",
    },

    -- don't change that
    DEFAULTS = {
        MOD_ENABLED     = true,
        TOOLTIP_ENABLED = true,

        AXE1H_T2_DMG = 10,  AXE1H_T3_DMG = 17, AXE1H_T4_DMG = 19,

        AXE2H_T2_DMG = 17, AXE2H_T3_DMG = 22, AXE2H_T4_DMG = 38,

        MACE_T2_DMG = 5,  MACE_T3_DMG = 10, MACE_T4_DMG = 999,

        HAMMER_T2_DMG = 15, HAMMER_T3_DMG = 22, HAMMER_T4_DMG = 999,

        STAFF_T2_DMG = 6,  STAFF_T3_DMG = 8,  STAFF_T4_DMG = 999,

        BLADE1H_T2_DMG = 10, BLADE1H_T3_DMG = 16, BLADE1H_T4_DMG = 999,

        BLADE2H_T2_DMG = 13, BLADE2H_T3_DMG = 20, BLADE2H_T4_DMG = 30,

        SHORT_T2_DMG = 6,  SHORT_T3_DMG = 12, SHORT_T4_DMG = 999,

        SPEAR_T2_DMG = 13, SPEAR_T3_DMG = 18, SPEAR_T4_DMG = 999,

        BOW_T2_DMG = 10,  BOW_T3_DMG = 17,  BOW_T4_DMG = 24,

        XBOW_T2_DMG = 15, XBOW_T3_DMG = 28, XBOW_T4_DMG = 37,

        THROWN_T2_DMG = 3, THROWN_T3_DMG = 5, THROWN_T4_DMG = 999,

        T1_SKILL = 0,  T2_SKILL = 30,  T3_SKILL = 60,  T4_SKILL = 80,

        T1_ATTR  = 0,  T2_ATTR  = 30,  T3_ATTR  = 60,  T4_ATTR  = 80,
    },
}