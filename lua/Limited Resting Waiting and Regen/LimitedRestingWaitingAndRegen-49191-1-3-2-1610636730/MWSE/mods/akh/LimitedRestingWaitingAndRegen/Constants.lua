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

constants.ui = {
    ID_BUTTON_WAIT = tes3ui.registerID("MenuRestWait_wait_button"),
    ID_BUTTON_REST = tes3ui.registerID("MenuRestWait_rest_button"),
    ID_BUTTON_REST_UNTIL_HEALED = tes3ui.registerID("MenuRestWait_untilhealed_button"),
    ID_MENU_SERVICE_TRAVEL = tes3ui.registerID("MenuDialog_service_travel"),
    ID_PROPERTY_MOUSECLICK = 4294934580
}

constants.event = {
    PLAYER_WAIT = "akh:lrwar:playerWait",
    PLAYER_WAITED = "akh:lrwar:playerWaited",
    PLAYER_REST = "akh:lrwar:playerRest",
    PLAYER_RESTED = "akh:lrwar:playerRested",
    PLAYER_TRAVEL = "akh:lrwar:playerTravel",
    PLAYER_TRAVELED = "akh:lrwar:playerTraveled"
}

constants.npcClass = {
    PUBLICAN = "Publican",
    CARAVANER = "Caravaner",
    SHIPMASTER = "Caravaner",
    GUILD_GUIDE = "Guild Guide"
}

return constants