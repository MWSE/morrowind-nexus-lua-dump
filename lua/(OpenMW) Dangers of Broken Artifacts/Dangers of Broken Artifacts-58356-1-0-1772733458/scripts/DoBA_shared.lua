return {
    -- Don't touch that
    DEFAULTS = {
        SCAN_INTERVAL = 60,
        MOD_ENABLED = true,
    },

    CREATURE_NAMES = {
        scamp_summon           = "Scamp",
        dremora_summon         = "Dremora",
        clannfear_summon       = "Clannfear",
        atronach_flame_summon  = "Flame Atronach",
        atronach_frost_summon  = "Frost Atronach",
        atronach_storm_summon  = "Storm Atronach",
        hunger_summon          = "Hunger",
        daedroth_summon        = "Daedroth",
        winged_twilight_summon = "Winged Twilight",
    },

    -- maxCharge is the max charge of an enchanted item. You can add more ids of creatures and modify/add maxCharge requirements.
    -- Don't forget to update the names of creatures
    DAEDRA_TIERS = {
        { maxCharge = 100, ids = { "scamp_summon" } },
        { maxCharge = 200, ids = { "dremora_summon", "clannfear_summon", "atronach_flame_summon" } },
        { maxCharge = 300, ids = { "atronach_frost_summon", "hunger_summon", "daedroth_summon" } },
        { maxCharge = math.huge, ids = { "winged_twilight_summon", "atronach_storm_summon" } },
    },

    -- You can add more messages
    MESSAGES = {
        "A broken enchanted item hath torn the veil — a %s walks free from Oblivion.",
        "The shattered ward upon your gear hath opened a rift. A %s emerges, bound to your ruin.",
        "Your broken enchantment bleeds into Oblivion. A %s answers the call.",
        "The seal is broken. From the realm of everchanging madness steps a %s, hungry for your soul.",
        "A crack in the enchantment, a crack in the world. A %s slips through.",
    },
}