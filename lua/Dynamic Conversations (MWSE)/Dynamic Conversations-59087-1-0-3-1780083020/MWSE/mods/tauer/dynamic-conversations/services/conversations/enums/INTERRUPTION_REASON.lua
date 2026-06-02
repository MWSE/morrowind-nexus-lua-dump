--- Reasons a conversation might be interrupted
---@enum INTERRUPTION_REASON
local enum = {
    combatStarted = "one or more participant entered combat",
    cellChanged = "the player changed cell",
    loadedGame = "the player loaded a saved game",
    npcTravelTimeExceeded = "the first participant took too long to reach the second participant",
    forceStopped = "the conversation was forcefully stopped via MCM",
    referenceDeactivated = "one or more participant was deactivated",
    handleInvalidated = "a participant's handle was invalidated",
    modDisabled = "the Dynamic Conversations mod was disabled in the MCM",
    participantDied = "one or more participant died",
    conversationInteropStarted = "a new conversation was started via interop",
}

return enum
