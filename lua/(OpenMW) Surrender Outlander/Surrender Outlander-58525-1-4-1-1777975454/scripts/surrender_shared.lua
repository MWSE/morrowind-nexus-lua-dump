return {
    -- NPC classes that will accept a gold bribe and stop fighting
    BRIBEABLE_CLASSES = {
        ["thief"]  = true,
        ["rogue"]  = true,
        ["barbarian"]  = true,
        ["mabrigash"]  = true,
        ["necromancer"]  = true,
        ["smuggler"]  = true,
        ["warlock"]  = true,
        ["witch"]  = true,
        ["cat-catcher"]  = true,
    },

    -- NPCs that will NEVER accept a bribe, even if their class matches
    EXEMPT_NPCS = {
        -- ["npc_id_here"] = true,
    },

    KHAJIIT_RACE = {
        ["khajiit"]           = true,
        ["t_els_cathay"]      = true,
        ["t_els_cathay-raht"] = true,
        ["t_els_ohmes"]       = true,
        ["t_els_ohmes-raht"]  = true,
        ["t_els_suthay"]      = true,
        ["t_els_dagi-raht"]   = true,
    },

    GOLD_IDS = {
        ["gold_001"] = true,
        ["gold_005"] = true,
        ["gold_010"] = true,
        ["gold_025"] = true,
        ["gold_100"] = true,
    },

    -- NPCs whose recordId contains any of these substrings are treated as guards
    GUARD_PATTERNS = { "guard", "ordinator", "watchman" },

    -- NPC classes treated as guards
    GUARD_CLASSES = {
        ["guard"] = true,
    },

    BRIBE_MESSAGES = {
        "Thanks for the gold, outlander. You'd better run.",
        "Wise choice. Now get out of here before I change my mind.",
        "Heh. Your gold spends as well as anyone's.",
        "Smart move. I'll let you go... this time.",
        "Consider this a valuable life lesson.",
        "Gold talks. Now walk.",
        "Pleasure doing business with you.",
    },

    KHAJIIT_MESSAGES = {
        "Khajiit thanks you for your generous contribution. Now run, yes?",
        "Shiny coins make Khajiit forget many things. Your face, for example.",
        "This one appreciates your wisdom. Go now, before the warm sands cool.",
        "Khajiit has no quarrel with one who pays so well.",
        "Ah, the sweet jingle of gold. Khajiit's claws grow dull already.",
        "You buy your life cheaply, walker. Khajiit is in a good mood today.",
        "This one's pockets grow heavy, and heart grows light. Go.",
    },

    -- don't change that
    DEFAULTS = {
        MOD_ENABLED      = true,
        MIN_GOLD         = 250,
        CEASEFIRE        = 10,
        BRIBE_RADIUS     = 300,
        CLASS_CEASEFIRE  = true,
        THROW_GOLD_AMOUNT = 250,
        USE_PHYSICS      = false,
        SURRENDER_TO_GUARDS = true,
        GUARD_RADIUS        = 200,
        LOG              = false,
    },
}