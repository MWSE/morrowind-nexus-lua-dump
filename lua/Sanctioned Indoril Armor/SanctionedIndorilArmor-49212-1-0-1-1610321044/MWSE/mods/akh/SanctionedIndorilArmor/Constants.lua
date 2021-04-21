local constants = {}

constants.config = {
    restingPreset = {
        VANILLA = 0,
        BEDS_AND_SCRIPTED = 1

    },
    contextualRestButtonPreset = {
        VANILLA = 0,
        UNTIL_MORNING = 1,
        UNTIL_MORNING_EVENING = 2
    },
    waitingPreset = {
        VANILLA = 0,
        VANILLA_RESTING = 1,
        VANILLA_RESTING_AND_INNS = 2
    },
    healthRegenPreset = {
        VANILLA = 0,
        NO_REGEN_ON_TRAVEL = 1,
        NO_REGEN = 2
    },
    magickaRegenPreset = {
        VANILLA = 0,
        NO_REGEN_ON_TRAVEL = 1,
    }
}

constants.event = {
    PLAYER_EQUIPPED_INDORIL = "akh:sia:playerEquippedIndoril",
    PLAYER_UNEQUIPPED_INDORIL = "akh:sia:playerUnequippedIndoril",
    PLAYER_EQUIPPED_ROBE = "akh:sia:playerEquippedRobe",
    PLAYER_UNEQUIPPED_ROBE = "akh:sia:playerUnequippedRobe",
    CONFIG_CHANGED = "akh:sia:configChanged",
    TEMPLE_RANK_CHANGED = "akh:sia:templeRankChanged",
    REQUIRED_QUEST_JOURNAL_CHANGED = "akh:sia:requiredQuestJournalChanged"
}

constants.faction = {
    TEMPLE = "Temple"
}

constants.npcClass = {
    GUARD = "Guard"
}

constants.command = {
    PC_RAISE_RANK = "PCRaiseRank",
    PC_LOWER_RANK = "PCLowerRank"
}

return constants