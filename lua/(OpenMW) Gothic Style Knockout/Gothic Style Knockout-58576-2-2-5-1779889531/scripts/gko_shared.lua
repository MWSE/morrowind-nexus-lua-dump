return {

    -- these NPCs won't be knocked out
    EXCLUDED_NPCS = {
       -- ["eydis fire-eye"] = true,
    },

    -- NPCs whose record comes from one of these content files (lowercase!!!) won't be knocked out
    EXCLUDED_CONTENT_FILES = {
    },

    -- NPCs whose recordId starts with one of these prefixes (lowercase) won't be
    -- knocked out. Used for actors that have no contentFile
    EXCLUDED_ID_PREFIXES = {
       "gvea_",
       "arena fighter",
       "arena_fighter",
       "arena_grand_",
       "arena extra",
       "arena team champ",
    },

    -- these NPCs won't knock out player
    KILL_PLAYER_NPCS = {
       ["tul"] = true,
    },

    -- quest-based exemptions
    QUEST_EXCEPTIONS = {
        ["eydis fire-eye"] = {
            { quest = "fg_killcronies", before = 10, after = 100 },
            { quest = "tg_bitterbribe", before = 10, after = 100 },
        },
        ["lorbumol gro-aglakh"] = {
            { quest = "fg_killcronies", before = 15, after = 100 },
        },
        ["sjoring hard-heart"] = {
            { quest = "fg_killhardheart", before = 10, after = 100 },
            { quest = "tg_killhardheart", before = 10, after = 100 },
        },
        ["trebonius artorius"] = {
            { quest = "mg_guildmaster", before = 10, after = 100 },
        },
        ["ethys savil"] = {
            { quest = "a1_7huleeyainformant", before = 1, after = 20 },
        },
        ["urven davor"] = {
            { quest = "a1_7huleeyainformant", before = 1, after = 20 },
        },
        ["favel gobor"] = {
            { quest = "a1_7huleeyainformant", before = 1, after = 20 },
        },
        ["varus vatinius"] = {
            { quest = "il_grandmaster", before = 10, after = 100 },
        },
        ["bolvyn venim"] = {
            { quest = "hr_archmaster", before = 10, after = 100 },
        },
        ["gothren"] = {
            { quest = "ht_archmagister", before = 10, after = 100 },
        },
        ["feruren oran"] = {
            { quest = "mt_writoran", before = 10, after = 100 },
        },
        ["toris saren"] = {
            { quest = "mt_writsaren", before = 10, after = 100 },
        },
        ["ethal seloth"] = {
            { quest = "mt_writvendu", before = 10, after = 100 },
        },
        ["idroso vendu"] = {
            { quest = "mt_writvendu", before = 10, after = 100 },
        },
        ["guril retheran"] = {
            { quest = "mt_writguril", before = 10, after = 100 },
        },
        ["galasa uvayn"] = {
            { quest = "mt_writgalasa", before = 10, after = 100 },
        },
        ["mavon drenim"] = {
            { quest = "mt_writmavon", before = 10, after = 100 },
        },
        ["larrius varro"] = {
            { quest = "mt_writvarro", before = 10, after = 100 },
        },
        ["madrale thirith"] = {
            { quest = "town_balmora", before = 29, after = 30 },
        },
        ["marasa aren"] = {
            { quest = "town_balmora", before = 29, after = 30 },
        },
        ["sovor trandel"] = {
            { quest = "town_balmora", before = 29, after = 30 },
        },
        ["thanelen velas"] = {
            { quest = "town_balmora", before = 29, after = 30 },
        },
        ["vadusa sathryon"] = {
            { quest = "town_balmora", before = 29, after = 30 },
        },
        ["tr_m4_llirala_arys"] = {
            { quest = "tr_m4_mt_llirala", before = 10, after = 100 },
        },
    },

GUARD_CLASS = {
        ["guard"] = true,
    },

    GUARD_PATTERNS = {
        "guard",
        "ordinator",
        "archer",
        "firemoth_",
        "imperial templar",
        "sharpshooter",
        "watchman",
        "red_watch",
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

    RECOVERY_MESSAGES = {
        "This isn't over. Not by a long shot.",
        "I'll remember your face.",
        "Ugh... my head. You'll pay for this.",
    },

    KHAJIIT_RECOVERY_MESSAGES = {
        "This one will lick wounds now. But this one has a long memory.",
        "Ugh... this one's skull rings like a bell. You will answer for this.",
    },

    LOOT_GOLD_MESSAGES = {
        "Let this be a lesson. Your gold will cover the trouble.",
        "Maybe next time you'll think twice. I'll take this gold for my troubles.",
        "You shouldn't have done that. Your coin purse says thank you.",
    },

    LOOT_GOLD_KHAJIIT_MESSAGES = {
        "This one takes your gold as payment for the insult. Learn from this.",
        "Khajiit thanks you for the generous donation. Do not make this mistake again.",
    },

    LOOT_NO_GOLD_MESSAGES = {
        "Hah, not even a coin on you. Pathetic.",
        "Empty pockets? You truly are a sorry sight.",
        "No gold? You're even more worthless than I thought.",
    },

    LOOT_NO_GOLD_KHAJIIT_MESSAGES = {
        "Not a single coin? This one pities you.",
        "Empty pockets... this one expected better prey.",
    },

    LOOT_WEAPON_MESSAGES = {
        "And I'll be keeping this weapon. Consider it a trophy.",
        "Nice weapon. It's mine now.",
    },

    LOOT_WEAPON_KHAJIIT_MESSAGES = {
        "This one will take your weapon too. A fine prize.",
        "Khajiit has new toy now. Your loss.",
    },

    -- don't change that
    DEFAULTS = {
        MOD_ENABLED         = true,
        KNOCKDOWN_DURATION  = 5,
        DROP_WEAPON         = true,
        PICKUP_DELAY        = 1.5,
        SET_FIGHT           = 10,
        SET_DISPOSITION     = 0,
        HP_AFTER_KNOCKDOWN  = 0.05,
        LOOT_MIN_PERCENT    = 100,
        BLUNT_ONLY          = false,
        PLAYER_KNOCKDOWN    = true,
        NPC_LOOT_PLAYER     = true,
        FIGHT_THRESHOLD_ENABLED        = true,
        FIGHT_THRESHOLD                = 85,
        PLAYER_FIGHT_THRESHOLD_ENABLED = true,
        PLAYER_FIGHT_THRESHOLD         = 85,
        BOUNTY_THRESHOLD_ENABLED       = true,
        BOUNTY_THRESHOLD               = 5000,
        BH_COMPAT                      = false,
    },
}