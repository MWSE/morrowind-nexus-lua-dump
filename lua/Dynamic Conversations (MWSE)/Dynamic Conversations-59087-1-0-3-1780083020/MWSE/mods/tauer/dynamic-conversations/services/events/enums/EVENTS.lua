--- All custom events for the Dynamic Conversations mod
---@enum EVENTS
local EVENTS = {
	modStateChanged = "tauer.dynamic-conversations.modStateChanged",
	conversationScheduled = "tauer.dynamic-conversations.conversationScheduled",
	conversationStarted = "tauer.dynamic-conversations.conversationStarted",
	conversationEnded = "tauer.dynamic-conversations.conversationEnded",
	conversationInterrupted = "tauer.dynamic-conversations.conversationInterrupted",
	lastDialogueSpoken = "tauer.dynamic-conversations.lastDialogueSpoken",
	npcTravelTimeExceeded = "tauer.dynamic-conversations.npcTravelTimeExceeded",
	conversationForceStopped = "tauer.dynamic-conversations.conversationForceStopped",
	timerFinished = "tauer.dynamic-conversations.timerFinished",
	timerCancelled = "tauer.dynamic-conversations.timerCancelled",
	handleInvalidated = "tauer.dynamic-conversations.handleInvalidated",
	npcStateRestored = "tauer.dynamic-conversations.npcStateRestored",
	conversationHistoryDeleted = "tauer.dynamic-conversations.conversationHistoryDeleted",
	conversationHistoryPlayStop = "tauer.dynamic-conversations.conversationHistoryPlayStop",
	conversationHistoryPlay = "tauer.dynamic-conversations.conversationHistoryPlay",
	conversationInteropStarted = "tauer.dynamic-conversations.conversationInteropStarted",
}

return EVENTS
