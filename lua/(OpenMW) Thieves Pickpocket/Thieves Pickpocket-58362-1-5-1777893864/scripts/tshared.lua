return {
    -- These factions can steal your gold
    THIEF_FACTIONS = {
        ["thieves guild"] = true,
    },

    -- These classes can steal your gold
    THIEF_CLASSES = {
        ["thief"] = true,
    },

    STEAL_MESSAGES = {
        "You feel a slight brush against your side.",
        "A gentle tug on your belt, as faint as a breeze.",
        "The weight of your satchel shifts almost imperceptibly.",
        "Your coin purse feels oddly light.",
        "You sense a presence, quick and practiced.",
    },

    -- FACTION_IMMUNITY[NPC_Faction][Player_Faction] = true
    FACTION_IMMUNITY = {
        ["thieves guild"] = {
            ["thieves guild"] = true, -- no professional thief would steal from another thief
        },
    },
    -- Don't touch it unless you want your stuff to disappear
    GOLD_IDS = {
        ["gold_001"] = true,
    },
    -- Stealable misc items, you can edit it
    STEALABLE_MISC = {
        ["misc_dwrv_coin00"] = true,
    },
    -- Stealable ingredients, you can edit it
    STEALABLE_INGREDIENTS = {
        ["ingred_diamond_01"]        = true,
        ["ingred_emerald_01"]        = true,
        ["ingred_pearl_01"]          = true,
        ["ingred_ruby_01"]           = true,
        ["t_ingcrea_ambergris"]      = true,
        ["t_ingcrea_canahfeather"]   = true,
        ["t_ingmine_topaz_01"]       = true,
        ["t_ingmine_spellstone_01"]  = true,
        ["t_ingmine_sapphire_01"]    = true,
        ["t_ingmine_rosequartz_01"]  = true,
        ["t_ingmine_diamondred_01"]  = true,
        ["t_ingmine_pearlpink_01"]   = true,
        ["t_ingmine_moonstone_01"]   = true,
        ["t_ingmine_lapislazuli_01"] = true,
        ["t_ingmine_pearlkardesh_01"]= true,
        ["t_ingmine_garnet_01"]      = true,
        ["t_ingmine_topazblue_01"]   = true,
        ["t_ingmine_diamondblue_01"] = true,
        ["t_ingmine_pearlblue_01"]   = true,
        ["t_ingmine_pearlblack_01"]  = true,
    },
    -- Stealable jewelry (only unequipped), you can edit it
    STEALABLE_CLOTHING = {
        ["extravagant_amulet_01"]   = true,
        ["extravagant_amulet_02"]   = true,
        ["exquisite_amulet_01"]     = true,
        ["extravagant_ring_01"]     = true,
        ["extravagant_ring_02"]     = true,
        ["exquisite_ring_01"]       = true,
        ["exquisite_ring_02"]       = true,
        ["t_ayl_amulet_01"]         = true,
        ["t_he_ex_amulet_01"]       = true,
        ["t_imp_ex_amulet_01"]      = true,
        ["t_qyc_ex_amulet_01"]      = true,
        ["t_imp_ex_amuletnib_01"]   = true,
        ["t_he_et_amulet_01"]       = true,
        ["t_imp_et_amulet_02"]      = true,
        ["t_nor_et_amulet_01"]      = true,
        ["t_nor_et_amulet_02"]      = true,
        ["t_qyc_et_amulet_01"]      = true,
        ["t_imp_et_amuletnib_01"]   = true,
        ["t_imp_et_amuletnib_02"]   = true,
        ["t_ayl_ring_01"]           = true,
        ["t_ayl_ring_02"]           = true,
        ["t_bre_ex_ring_01"]        = true,
        ["t_he_ex_ring_01"]         = true,
        ["t_rga_eq_ring_01"]        = true,
        ["t_imp_ex_ringnib_01"]     = true,
        ["t_imp_ringsignet_01"]     = true,
    },


    RETALIATION_LINES = {
        "You'll never take me alive!",
        "I'd rather die than rot in a cell!",
        "Back off or I'll gut you!",
        "You want your gold back? Come and get it!",
        "Big mistake, friend. Big mistake.",
    },
    RETALIATION_LINES_KHAJIIT = {
        "This one will not be caged!",
        "Khajiit fights! You will bleed!",
        "You bare claws at Khajiit? Khajiit bares claws back!",
        "Sweet moons, give this one strength to gut the fool!",
        "This one would rather die than surrender the coin!",
    },
    APOLOGY_LINES = {
        "Easy now, I meant no harm! Here, take it back!",
        "Whoa, whoa! It was just a joke, friend!",
        "No need for steel! I was only holding it for you!",
        "Please, I have a family! It won't happen again!",
        "You win! I'll not cross you again, I swear!",
    },
    APOLOGY_LINES_KHAJIIT = {
        "This one meant no offense! Please, sheathe your blade!",
        "Khajiit is sorry! It was a moment of weakness!",
        "Warm sands, warm sands! This one returns everything!",
        "The moons frown on this one's greed. Forgive Khajiit!",
        "This one begs mercy! Khajiit will steal no more!",
    },
    TAUNT_LINES = {
        "That's what I thought.",
        "Run along now, friend.",
        "Smart choice. Live to spend another day.",
        "Knew you didn't have the stomach.",
        "Try harder next time, eh?",
    },
    TAUNT_LINES_KHAJIIT = {
        "Hah! Khajiit knew you would not bite.",
        "The coin stays with this one. Good choice",
        "Wise. Khajiit's claws are sharper than yours.",
        "Run, little mouse. Khajiit keeps the prize.",
        "Sweet moons smile on Khajiit today, not on you.",
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

    -- Defaults for settings, don't change that
    DEFAULTS = {
        MOD_ENABLED     = true,
        STEAL_RADIUS  = 100,
        STEAL_CHANCE  = 0.25,
        MIN_GOLD      = 50,
        MAX_GOLD      = 250,
        AGILITY_MIN   = 65,
        SNEAK_MIN     = 70,
        SCAN_INTERVAL = 1,
        USE_DISPOSITION   = true,
        MAX_DISPOSITION   = 60,
        PLAY_SOUND      = true,
        SHOW_MESSAGE    = true,
        STEAL_ITEMS     = true,
        RETALIATION_ENABLED = true,
        RETALIATION_WINDOW  = 5,
        RETALIATION_RADIUS  = 200,
        RETALIATION_STANDOFF = 3,
        RETALIATION_LEVEL_DIFF = 5,
    },
}