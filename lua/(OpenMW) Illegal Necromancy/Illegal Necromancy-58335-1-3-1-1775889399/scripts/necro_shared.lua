return {
    -- Record IDs of summoned undead creatures
    SUMMON_MAP = {
        ["ancestor_ghost_summon"]   = "SummonAncestralGhost",
        ["skeleton_summon"]         = "SummonSkeletalMinion",
        ["bonewalker_greater_summ"] = "SummonGreaterBonewalker",
        ["bonewalker_summon"]       = "SummonBonewalker",
        ["bonelord_summon"]         = "SummonBonelord",
    },

    -- Summon IDs allowed for members of these factions
    FACTION_EXEMPT_SUMMONS = {
        ["temple"] = {
            ["ancestor_ghost_summon"] = true,
        },
    },

    -- Factions exempt from reporting necromancy
    EXEMPT_FACTIONS = {
        ["telvanni"] = true,
    },

    -- NPCs exempt from reporting necromancy (record ID)
    EXEMPT_NPCS = {
        -- ["npc_id_here"] = true,
    },

    -- Cell IDs where necromancy is allowed
    EXEMPT_CELLS = {
        -- ["cell_id_here"] = true,
    },

    DEFAULTS = {
        MOD_ENABLED            = true,
        FACTION_EXEMPT_ENABLED = true,
        SNEAK_THRESHOLD        = 75,
        CHAMELEON_THRESHOLD    = 75,
        WITNESS_RADIUS         = 600,
        SIGN_COMPAT            = false,
    },

    WITNESS_MESSAGES = {
        "Someone has seen your dark work. The dead should stay dead.",
        "A witness recoils in horror. Necromancy is not tolerated here.",
        "Your summoning has not gone unnoticed. Expect consequences.",
        "The sight of your undead servant has disturbed those nearby.",
    },
}