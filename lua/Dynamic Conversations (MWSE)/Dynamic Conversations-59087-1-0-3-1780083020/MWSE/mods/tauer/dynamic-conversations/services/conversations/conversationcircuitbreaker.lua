local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")
local INTERRUPTION_REASON = require("tauer.dynamic-conversations.services.conversations.enums.INTERRUPTION_REASON")
local handleResolver = require("tauer.dynamic-conversations.services.handles.handleResolver")

--- A circuit breaker for active conversations that interrupts them under certain conditions
---@class conversationCircuitBreaker : initializedService
local this = {}

---@private
---@type safeConversation|nil
this.activeConversation = nil

---@public
---@return boolean
function this.initialize()
    event.register(EVENTS.conversationScheduled, this.onConversationScheduled)
    event.register(EVENTS.conversationEnded, this.onConversationEnded)
    event.register(EVENTS.npcTravelTimeExceeded, this.onNpcTravelTimeExceeded)
    event.register(EVENTS.conversationForceStopped, this.onConversationForceStopped)
    event.register(EVENTS.handleInvalidated, this.onHandleInvalidated)
    event.register(EVENTS.modStateChanged, this.onModStateChanged)
    event.register(EVENTS.conversationInteropStarted, this.onConversationInteropStarted)
    event.register(tes3.event.combatStarted, this.onCombatStarted)
    event.register(tes3.event.cellChanged, this.onCellChanged)
    event.register(tes3.event.load, this.onLoad)
    event.register(tes3.event.referenceDeactivated, this.onReferenceDeactivated)
    event.register(tes3.event.death, this.onDeath)
    return true
end

---@private
---@param eventData conversationScheduledEventData
function this.onConversationScheduled(eventData)
    this.activeConversation = {
        configuration = eventData.conversation.configuration,
        firstParticipant = tes3.makeSafeObjectHandle(eventData.conversation.firstParticipant --[[@as tes3reference]]),
        secondParticipant = tes3.makeSafeObjectHandle(eventData.conversation.secondParticipant --[[@as tes3reference]]),
    }
end

---@private
---@param _ conversationEndedEventData
function this.onConversationEnded(_)
    this.activeConversation = nil
end

---@private
---@param _ npcTravelTimeExceededEventData
function this.onNpcTravelTimeExceeded(_)
    this.triggerInterruptionEvent(INTERRUPTION_REASON.npcTravelTimeExceeded)
end

---@private
function this.onConversationForceStopped()
    this.triggerInterruptionEvent(INTERRUPTION_REASON.forceStopped)
end

---@private
---@param _ handleInvalidatedEventData
function this.onHandleInvalidated(_)
    this.triggerInterruptionEvent(INTERRUPTION_REASON.handleInvalidated)
end

---@private
---@param eventData modStateChangedEventData
function this.onModStateChanged(eventData)
    if not eventData.enabled then
        this.triggerInterruptionEvent(INTERRUPTION_REASON.modDisabled)
    end
end

---@private
function this.onConversationInteropStarted()
    this.triggerInterruptionEvent(INTERRUPTION_REASON.conversationInteropStarted)
end

---@private
---@param eventData combatStartedEventData
function this.onCombatStarted(eventData)
    if not this.activeConversation then
        return
    end

    local firstParticipant, secondParticipant = this.resolveParticipants()
    if not firstParticipant or not secondParticipant then
        return
    end

    if this.isInCombat(firstParticipant, eventData) or this.isInCombat(secondParticipant, eventData) then
        this.triggerInterruptionEvent(INTERRUPTION_REASON.combatStarted)
    end
end

---@private
---@param _ cellChangedEventData
function this.onCellChanged(_)
    this.triggerInterruptionEvent(INTERRUPTION_REASON.cellChanged)
end

---@private
---@param _ loadEventData
function this.onLoad(_)
    this.triggerInterruptionEvent(INTERRUPTION_REASON.loadedGame)
end

---@private
---@param eventData referenceDeactivatedEventData
function this.onReferenceDeactivated(eventData)
    if not this.activeConversation then
        return
    end

    local firstParticipant, secondParticipant = this.resolveParticipants()
    if not firstParticipant or not secondParticipant then
        return
    end

    if eventData.reference ~= firstParticipant and eventData.reference ~= secondParticipant then
        return
    end

    this.triggerInterruptionEvent(INTERRUPTION_REASON.referenceDeactivated)
end

---@private
---@param eventData deathEventData
function this.onDeath(eventData)
    if not this.activeConversation then
        return
    end

    local firstParticipant, secondParticipant = this.resolveParticipants()
    if not firstParticipant or not secondParticipant then
        return
    end

    if eventData.reference == firstParticipant or eventData.reference == secondParticipant then
        this.triggerInterruptionEvent(INTERRUPTION_REASON.participantDied)
    end
end

---@private
---@param reason INTERRUPTION_REASON
function this.triggerInterruptionEvent(reason)
    local conversation = this.activeConversation
    if not conversation then
        return
    end
    this.activeConversation = nil

    ---@type conversationInterruptedEventData
    local payload = {
        conversation = {
            configuration = conversation.configuration,
            firstParticipant = conversation.firstParticipant,
            secondParticipant = conversation.secondParticipant,
        },
        reason = reason,
    }
    event.trigger(EVENTS.conversationInterrupted, payload)
end

---@private
---@return tes3npcInstance|nil, tes3npcInstance|nil
function this.resolveParticipants()
    local conversation = this.activeConversation
    if not conversation then
        return nil, nil
    end

    local firstParticipant = handleResolver.tryResolve({
        handle = conversation.firstParticipant,
        hint = "conversationCircuitBreaker.resolveParticipants.firstParticipant",
    })

    local secondParticipant = handleResolver.tryResolve({
        handle = conversation.secondParticipant,
        hint = "conversationCircuitBreaker.resolveParticipants.secondParticipant",
    })

    return firstParticipant --[[@as tes3npcInstance]], secondParticipant --[[@as tes3npcInstance]]
end

---@private
---@param npc tes3npcInstance
---@param eventData combatStartedEventData
---@return boolean
function this.isInCombat(npc, eventData)
    return eventData.actor.reference == npc or eventData.target.reference == npc
end

return this
