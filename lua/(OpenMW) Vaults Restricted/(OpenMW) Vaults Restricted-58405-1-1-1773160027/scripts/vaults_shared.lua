return {
    -- Don't change these
    DEFAULTS = {
        MOD_ENABLED    = true,
        COUNTDOWN      = 5,
        WITNESS_RADIUS = 600,
        BOUNTY_AMOUNT  = 300,
    },
    -- By default, you're not a member of a House
    HOUSE_FACTIONS = {
        Hlaalu   = 2,
        Redoran  = 2,
        Telvanni = 2,
    },
    -- By default, you're not a member of a faction. You'll need to add a new message to WARNING_MESSAGES if you're to add a faction
    NON_HOUSE_FACTIONS = {
        ["Imperial Legion"] = 4,
        ["Temple"]          = 5,
    },

    GUARD_PATTERNS         = { "guard", "ordinator" },
    GUARD_TR_PATTERNS      = { "tr" },
    -- Excludes non-guard NPCSs
    GUARD_EXCLUDE_PATTERNS = { "eseld", "leila", "nelvel", "valtio", "yridius", "selvand", "tashira", "ararvyne" },

    WARNING_MESSAGES = {
        [0] = "This is a restricted area. Guards will attack you in %d...",
        [1] = "Your Imperial Legion rank is insufficient. Guards will attack you in %d...",
        [2] = "You don't belong to this House. Guards will attack you in %d...",
        [3] = "Your House rank is insufficient. Guards will attack you in %d...",
        [4] = "You are not a soldier of the Imperial Legion. Guards will attack you in %d...",
        [5] = "You are not a member of the Temple. Guards will attack you in %d...",
        [6] = "Your Temple rank is insufficient. Guards will attack you in %d...",
    },
   
    -- [cell id] = {faction from  either HOUSE_FACTIONS or NON_HOUSE_FACTIONS, minimal rank of that faction to enter a vault, an insufficient rank message.}
    -- Optional: if there's a quest linked to the restricted cell, use questException with params being quest id and its stage.
    -- If you don't need to be in a cell on quest stage 50, write down 51
    -- "alwaysIntruder" = true returns NPCs always on guard.
    VAULT_CELLS = {
        -- REDORAN
        ["ald iuval, kogotel: vaults"]                       = { faction = "Redoran",         minRank = 5, messageType = 3 },
        ["vivec, redoran vaults"]                            = { faction = "Redoran",         minRank = 4, messageType = 3 },
        -- HLAALU
        ["oran plantation, oran manor: vault"]               = { faction = "Hlaalu",          minRank = 6, messageType = 3 },
        ["hlerynhul, hleryn estate: vault"]                  = { faction = "Hlaalu",          minRank = 6, messageType = 3 },
        ["narsis, mesa exchange: vaults"]                    = { faction = "Hlaalu",          minRank = 6, messageType = 3 },
        ["narsis, measurehall: mint vaults"]                 = { faction = "Hlaalu",          minRank = 6, messageType = 3 },
        ["narsis, measurehall: lower vaults"]                = { faction = "Hlaalu",          minRank = 6, messageType = 3 },
        ["narsis, second family manor: vault 1"]             = { faction = "Hlaalu",          minRank = 5, messageType = 3 },
        ["narsis, second family manor: vault 2"]             = { faction = "Hlaalu",          minRank = 5, messageType = 3 },
        ["narsis, second family manor: vault 3"]             = { faction = "Hlaalu",          minRank = 5, messageType = 3 },
        ["vivec, hlaalu vaults"] = { faction = "Hlaalu", minRank = 4, messageType = 3, questException = { id = "HH_BankCourier", stageComplete = 51 } },
        -- TELVANNI
        ["tel gilan, tower: vault"]                          = { faction = "Telvanni",        minRank = 5, messageType = 3 },
        ["port telvannis, telvanni council house: vaults"]   = { faction = "Telvanni",        minRank = 5, messageType = 3 },
        ["vivec, telvanni vault"]                            = { faction = "Telvanni",        minRank = 4, messageType = 3 },
        -- IMPERIAL LEGION
        ["ebon tower, palace: treasure chamber"]             = { faction = "Imperial Legion", minRank = 6, messageType = 1 },
        ["firewatch, ember keep: treasure chamber"]          = { faction = "Imperial Legion", minRank = 6, messageType = 1 },
        ["ebon tower, curia: imperial treasury vault"]       = { faction = "Imperial Legion", minRank = 7, messageType = 1 },
        -- INDORIL
        ["bosmora, indoril vault"]                           = { alwaysIntruder = true },
        -- TEMPLE
        ["vivec, hall of justice secret library"]            = { faction = "Temple",          minRank = 7, messageType = 6 },
        -- BANKS
        ["firewatch, briricca private bank"]                 = { alwaysIntruder = true },
        ["narsis, briricca private bank"]                    = { alwaysIntruder = true },
    },
}