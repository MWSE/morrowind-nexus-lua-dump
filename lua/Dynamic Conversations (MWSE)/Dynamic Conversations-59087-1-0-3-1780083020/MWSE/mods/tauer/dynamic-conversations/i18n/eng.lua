local TRANSLATION_KEY = require("tauer.dynamic-conversations.services.translations.enums.TRANSLATION_KEY")

return {
    --- MCM labels
    [TRANSLATION_KEY.mcmTitleLabel] = "Dynamic Conversations",
    [TRANSLATION_KEY.settingsLabel] = "Settings",
    [TRANSLATION_KEY.modEnabledLabel] = "Enabled",
    [TRANSLATION_KEY.conversationTimerLabel] = "Conversation Timer",
    [TRANSLATION_KEY.secondsLabel] = "seconds",
    [TRANSLATION_KEY.conversationChanceLabel] = "Conversation Chance",
    [TRANSLATION_KEY.playerDistanceThresholdLabel] = "Player Distance Threshold",
    [TRANSLATION_KEY.exteriorsOnlyLabel] = "Exteriors Only",
    [TRANSLATION_KEY.enableAnimationsLabel] = "Enable custom animations",
    [TRANSLATION_KEY.blacklistedNpcsTitleLabel] = "Blacklisted NPCs",
    [TRANSLATION_KEY.blacklistedNpcsLeftLabel] = "Blacklisted",
    [TRANSLATION_KEY.blacklistedNpcsRightLabel] = "NPCs",
    [TRANSLATION_KEY.blacklistedCellsTitleLabel] = "Blacklisted Cells",
    [TRANSLATION_KEY.blacklistedCellsLeftLabel] = "Blacklisted",
    [TRANSLATION_KEY.blacklistedCellsRightLabel] = "Cells",
    [TRANSLATION_KEY.forceStopConversationLabel] = "Force stop active conversation",
    [TRANSLATION_KEY.debuggingCategoryLabel] = "Debugging",
    [TRANSLATION_KEY.conversationHistoryTitleLabel] = "Conversation History",
    [TRANSLATION_KEY.clearConversationHistoryLabel] =
    "To clear the history, use the button below. This will allow you to witness these conversations in the game-world again. (WARNING: This action cannot be undone!)",
    [TRANSLATION_KEY.nameLabel] = "Name",
    [TRANSLATION_KEY.idLabel] = "ID",

    --- MCM descriptions
    [TRANSLATION_KEY.settingsDescription] = "Configure the settings for Dynamic Conversations mod.",
    [TRANSLATION_KEY.modEnabledDescription] = "Enable or disable the Dynamic Conversations mod.",
    [TRANSLATION_KEY.conversationTimerDescription] = "Time in seconds before a new conversation will be attempted.",
    [TRANSLATION_KEY.conversationChanceDescription] = "Chance of a conversation occurring when the timer expires.",
    [TRANSLATION_KEY.playerDistanceThresholdDescription] =
    "Distance to the conversation participants that the player must be within before a conversation will trigger.",
    [TRANSLATION_KEY.exteriorsOnlyDescription] = "Conversations will only occur in exterior cells.",
    [TRANSLATION_KEY.enableAnimationsDescription] = "Enables custom animations on NPCs during conversations.",
    [TRANSLATION_KEY.conversationHistoryDescription] =
    "This is a list of all the non-repeatable conversations you have witnessed.\nClicking on an entry will show more details about that conversation, and give you the option to play the dialog, as well as remove it from the history.",
    [TRANSLATION_KEY.clearConversationHistoryDescription] =
    "Clears the conversation history, allowing you to hear non-repeatable conversations you have heard before.",
    [TRANSLATION_KEY.blacklistedNpcsDescription] = "NPCs that can never be selected for a conversation.",
    [TRANSLATION_KEY.blacklistedCellsDescription] = "Cells where conversations will never occur.",
    [TRANSLATION_KEY.logLevelDescription] = "Sets the verbosity of the mod's logging output.",
    [TRANSLATION_KEY.forceStopConversationDescription] = "Immediately stops the active conversation.",
    [TRANSLATION_KEY.debuggingCategoryDescription] = "Settings used for debugging purposes.",

    --- MCM messages
    [TRANSLATION_KEY.clearConversationHistoryConfirmation] =
    "Are you sure you want to clear the conversation history? Cannot be undone!",
    [TRANSLATION_KEY.deleteConversationConfirmation] =
    "Are you sure you want to delete this conversation from the history?",
    [TRANSLATION_KEY.forceStopConversationConfirmation] =
    "Are you sure you want to force stop the active conversation?",

    --- MCM buttons
    [TRANSLATION_KEY.yesButton] = "Yes",
    [TRANSLATION_KEY.noButton] = "No",
    [TRANSLATION_KEY.clearConversationHistoryButton] = "Clear conversation history",
    [TRANSLATION_KEY.forceStopConversationButton] = "Force stop",
    [TRANSLATION_KEY.deleteButton] = "Delete",
}
