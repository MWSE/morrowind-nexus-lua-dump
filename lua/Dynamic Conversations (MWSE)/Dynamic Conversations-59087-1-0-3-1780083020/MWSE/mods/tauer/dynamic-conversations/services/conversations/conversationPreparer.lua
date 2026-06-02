local npcAnimator = require("tauer.dynamic-conversations.services.npcs.npcAnimator")
local npcMover = require("tauer.dynamic-conversations.services.npcs.npcMover")
local handleResolver = require("tauer.dynamic-conversations.services.handles.handleResolver")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmSettings").mcm
local timerManager = require("tauer.dynamic-conversations.services.timers.timerManager")

--- Prepares conversation participants for conversations
---@class conversationPreparer : initializedService
local this = {}

---@private
---@type safeConversation|nil
this.activeConversation = nil

---@public
---@return boolean
function this.initialize()
	event.register(EVENTS.conversationScheduled, this.onConversationScheduled)
	event.register(EVENTS.conversationInterrupted, this.onConversationInterrupted)
	event.register(EVENTS.conversationEnded, this.onConversationEnded)
	return true
end

---@public
---@param eventData conversationScheduledEventData
function this.onConversationScheduled(eventData)
	local conversation = eventData.conversation

	local configuration = conversation.configuration
	local firstParticipant = conversation.firstParticipant
	local secondParticipant = conversation.secondParticipant

	this.activeConversation = {
		configuration = configuration,
		firstParticipant = tes3.makeSafeObjectHandle(firstParticipant --[[@as tes3reference]]),
		secondParticipant = tes3.makeSafeObjectHandle(secondParticipant --[[@as tes3reference]]),
	}

	if configuration.static then
		this.waitForPlayerToApproach(firstParticipant, secondParticipant)
	else
		this.waitForFirstParticipantToApproach(firstParticipant, secondParticipant)
	end
end

---@private
---@param firstParticipant tes3npcInstance
---@param secondParticipant tes3npcInstance
function this.waitForFirstParticipantToApproach(firstParticipant, secondParticipant)
	npcMover.approach({
		npc = firstParticipant,
		target = secondParticipant,
		onApproached = this.onFirstParticipantApproached
	})
	npcMover.wait(secondParticipant)
end

---@private
---@param firstParticipant tes3npcInstance
---@param secondParticipant tes3npcInstance
function this.onFirstParticipantApproached(firstParticipant, secondParticipant)
	npcMover.wait(firstParticipant)
	this.waitForPlayerToApproach(firstParticipant, secondParticipant)
end

---@private
---@param firstParticipant tes3npcInstance
---@param secondParticipant tes3npcInstance
function this.waitForPlayerToApproach(firstParticipant, secondParticipant)
	npcAnimator.faceNpc(firstParticipant, secondParticipant)
	npcAnimator.faceNpc(secondParticipant, firstParticipant)

	timerManager.start({
		id = "conversationPreparer.waitForPlayerToApproach",
		duration = 0.5,
		iterations = -1,
		onTick = this.onWaitForPlayerToApproachTimerTick,
		cancellationEvents = { EVENTS.conversationInterrupted },
	})
end

---@private
---@param callback mwseTimerCallbackData
function this.onWaitForPlayerToApproachTimerTick(callback)
	local timer = callback.timer

	if not this.activeConversation then
		timer:cancel()
		return
	end

	local firstParticipant = handleResolver.tryResolve({
		handle = this.activeConversation.firstParticipant,
		hint = "conversationPreparer.onWaitForPlayerToApproachTimerTick.firstParticipant",
	})

	local secondParticipant = handleResolver.tryResolve({
		handle = this.activeConversation.secondParticipant,
		hint = "conversationPreparer.onWaitForPlayerToApproachTimerTick.secondParticipant",
	})

	if not firstParticipant or not secondParticipant then
		return
	end

	if firstParticipant.mobile.playerDistance > mcm.conversationDistance then
		return
	end

	timer:cancel()

	local configuration = this.activeConversation.configuration

	---@type conversationStartedEventData
	local payload = {
		conversation = {
			configuration = configuration,
			firstParticipant = firstParticipant --[[@as tes3npcInstance]],
			secondParticipant = secondParticipant --[[@as tes3npcInstance]],
		}
	}
	event.trigger(EVENTS.conversationStarted, payload)
end

---@private
---@param _ conversationInterruptedEventData
function this.onConversationInterrupted(_)
	this.activeConversation = nil
end

---@private
---@param _ conversationEndedEventData
function this.onConversationEnded(_)
	this.activeConversation = nil
end

return this
