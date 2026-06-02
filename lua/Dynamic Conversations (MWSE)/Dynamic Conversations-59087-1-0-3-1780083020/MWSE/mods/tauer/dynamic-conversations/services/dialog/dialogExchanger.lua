local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")
local npcAnimator = require("tauer.dynamic-conversations.services.npcs.npcAnimator")
local handleResolver = require("tauer.dynamic-conversations.services.handles.handleResolver")
local dialogResolver = require("tauer.dynamic-conversations.services.dialog.dialogResolver")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmSettings").mcm
local timerManager = require("tauer.dynamic-conversations.services.timers.timerManager")
local npcClassifier = require("tauer.dynamic-conversations.services.npcs.npcClassifier")

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Responsible for exchanging dialog lines between two NPCs during a conversation
---@class dialogExchanger : initializedService
local this = {}

---@private
---@type mwseTimer|nil
this.dialogTimer = nil

---@public
---@return boolean
function this.initialize()
	event.register(EVENTS.conversationStarted, this.onConversationStarted)
	return true
end

---@public
---@param eventData conversationStartedEventData
function this.onConversationStarted(eventData)
	this.sayDialog({
		dialogIndex = 1,
		configuration = eventData.conversation.configuration,
		speaker = eventData.conversation.firstParticipant,
		listener = eventData.conversation.secondParticipant,
	})
end

---@private
---@param params sayDialogParams
function this.sayDialog(params)
	local dialogIndex = params.dialogIndex
	local configuration = params.configuration
	local speaker = params.speaker
	local listener = params.listener

	local dialog = dialogResolver.resolve({
		index = dialogIndex,
		configuration = configuration,
		race = npcClassifier.getRace(speaker),
		sex = npcClassifier.getSex(speaker),
	})
	if not dialog then
		return
	end

	tes3.say({
		reference = speaker --[[@as tes3reference]],
		soundPath = dialog.soundPath,
		subtitle = dialog.subtitle,
	})

	-- Beast race animations not supported yet
	if mcm.enableAnimations and not speaker.baseObject.race.isBeast and dialog.animation then
		npcAnimator.playAnimation(speaker, dialog.animation)
	end

	this.dialogTimer = timerManager.start({
		id = "dialogExchanger.sayDialog",
		duration = dialog.duration,
		iterations = 1,
		onTick = this.onDialogTimerTick,
		cancellationEvents = { EVENTS.conversationInterrupted },
		---@type dialogTimerCallbackData
		data = {
			dialogIndex = dialogIndex,
			configuration = configuration,
			speaker = tes3.makeSafeObjectHandle(speaker),
			listener = tes3.makeSafeObjectHandle(listener),
		},
	})
end

---@private
---@param callback mwseTimerCallbackData
function this.onDialogTimerTick(callback)
	---@type dialogTimerCallbackData
	local data = callback.timer.data

	local speaker = handleResolver.tryResolve({
		handle = data.speaker,
		hint = "dialogExchanger.onDialogTimerTick.speaker",
	})

	local listener = handleResolver.tryResolve({
		handle = data.listener,
		hint = "dialogExchanger.onDialogTimerTick.listener",
	})

	if not speaker or not listener then
		return
	end

	---@cast speaker -tes3reference, +tes3npcInstance
	---@cast listener -tes3reference, +tes3npcInstance

	local dialogIndex = data.dialogIndex
	local configuration = data.configuration

	if this.isLastDialog(dialogIndex, configuration) then
		this.finishDialog(configuration, speaker, listener)
		return
	end

	this.sayDialog({
		dialogIndex = dialogIndex + 1,
		configuration = configuration,
		speaker = listener,
		listener = speaker,
	})
end

---@private
---@param dialogIndex dialogIndex
---@param configuration conversationConfiguration
function this.isLastDialog(dialogIndex, configuration)
	return dialogIndex == table.size(configuration.dialog)
end

---@private
---@param configuration conversationConfiguration
---@param speaker tes3npcInstance
---@param listener tes3npcInstance
function this.finishDialog(configuration, speaker, listener)
	---@type lastDialogueSpokenEventData
	local payload = {
		conversation = {
			configuration = configuration,
			firstParticipant = speaker,
			secondParticipant = listener,
		},
	}
	event.trigger(EVENTS.lastDialogueSpoken, payload)
end

return this
