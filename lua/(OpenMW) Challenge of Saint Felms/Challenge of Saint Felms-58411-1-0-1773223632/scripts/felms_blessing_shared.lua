return {
    SPELL_ID       = "felms'_wrath",
    KILL_THRESHOLD = 150,
    INT_THRESHOLD  = 35,

    MSG            = "Saint Felms the Bold has seen your devotion. Not through prayer or scripture, but through the swing of an axe, the only tongue he ever knew. You cannot read his name, but you have lived his creed. The Bold One's fury is yours now. Strike the wicked without hesitation.",
    PROGRESS_MSG   = "Saint Felms bears witness to your cleansing: ",

    PLAYER_FACTION = "temple",

    PLAYER_EXCLUDED_FACTIONS = {
        ["imperial cult"] = true,
    },

    EXCLUDED_FACTIONS = {
        ["temple"]     = true,
        ["morag tong"] = true,
    },

    VALID_RACES = {
        ["nord"] = true,
    },

    VALID_CLASSES = {
        ["assassin"]    = true, ["barbarian"] = true, ["rogue"]      = true,
        ["sorcerer"]    = true, ["thief"]     = true, ["courtesan"]  = true,
        ["necromancer"] = true, ["smuggler"]  = true, ["warlock"]    = true,
        ["witch"]       = true, ["shaman"]    = true, ["dreamer"]    = true,
        ["mabrigash"]   = true, ["wise woman"]= true, ["champion"]   = true,
    },

    VALID_FACTIONS = {
        ["thieves guild"]    = true,
        ["camonna tong"]     = true,
        ["dark brotherhood"] = true,
        ["imperial cult"]    = true,
    },
}