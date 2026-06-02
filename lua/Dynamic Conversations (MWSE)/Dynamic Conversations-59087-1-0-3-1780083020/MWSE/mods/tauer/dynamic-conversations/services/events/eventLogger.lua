local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

local logger = mwse.Logger.new()

--- Logs important conversation events
---@class eventLogger : initializedService
local this = {}

---@public
---@return boolean
function this.initialize()
    event.register(EVENTS.modStateChanged, this.onModStateChanged, { priority = 10000 })
    event.register(EVENTS.conversationScheduled, this.onConversationScheduled, { priority = 10000 })
    event.register(EVENTS.conversationStarted, this.onConversationStarted, { priority = 10000 })
    event.register(EVENTS.conversationEnded, this.onConversationEnded, { priority = 10000 })
    event.register(EVENTS.conversationInterrupted, this.onConversationInterrupted, { priority = 10000 })
    event.register(EVENTS.timerFinished, this.onTimerFinished, { priority = 10000 })
    event.register(EVENTS.timerCancelled, this.onTimerCancelled, { priority = 10000 })
    event.register(EVENTS.handleInvalidated, this.onHandleInvalidated, { priority = 10000 })
    return true
end

---@private
---@param eventData modStateChangedEventData
function this.onModStateChanged(eventData)
    local state = eventData.enabled and "enabled" or "disabled"
    logger:info("Dynamic Conversations mod '%s'", state)
end

---@private
---@param eventData conversationScheduledEventData
function this.onConversationScheduled(eventData)
    logger:info(
        "Conversation '%s' scheduled between '%s' and '%s'",
        eventData.conversation.configuration.name,
        eventData.conversation.firstParticipant.baseObject.name,
        eventData.conversation.secondParticipant.baseObject.name
    )
end

---@private
---@param eventData conversationStartedEventData
function this.onConversationStarted(eventData)
    logger:info("Conversation '%s' started", eventData.conversation.configuration.name)
end

---@private
---@param eventData conversationEndedEventData
function this.onConversationEnded(eventData)
    logger:info("Conversation '%s' ended", eventData.conversation.configuration.name)
end

---@private
---@param eventData conversationInterruptedEventData
function this.onConversationInterrupted(eventData)
    logger:info(
        "Conversation '%s' interrupted because %s",
        eventData.conversation.configuration.name,
        eventData.reason
    )
end

---@private
---@param eventData timerFinishedEventData
function this.onTimerFinished(eventData)
    logger:debug("Timer '%s' finished", eventData.timer.id)
end

---@private
---@param eventData timerCancelledEventData
function this.onTimerCancelled(eventData)
    logger:debug("Timer '%s' cancelled", eventData.timer.id)
end

---@private
---@param eventData handleInvalidatedEventData
function this.onHandleInvalidated(eventData)
    logger:warn("Handle '%s' invalidated", eventData.hint)
end

return this
