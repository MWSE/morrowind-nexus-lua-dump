local configurationSelector = require("tauer.dynamic-conversations.services.configurations.configurationSelector")
local npcLoader = require("tauer.dynamic-conversations.services.npcs.npcLoader")
local npcSelector = require("tauer.dynamic-conversations.services.npcs.npcSelector")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmSettings").mcm
local timerManager = require("tauer.dynamic-conversations.services.timers.timerManager")

--- Schedules conversations between NPCs based on configurations and conditions
---@class conversationScheduler : initializedService
local this = {}

---@private
---@type conversationConfiguration[]
this.configurations = {}

---@private
---@type mwseTimer
this.scheduleTimer = nil

---@public
---@return boolean
function this.initialize()
	event.register(tes3.event.load, this.onLoad)
	event.register(tes3.event.loaded, this.onLoaded)
	event.register(tes3.event.cellChanged, this.onCellChanged)
	event.register(EVENTS.conversationEnded, this.onConversationEnded)
	event.register(EVENTS.conversationInterrupted, this.onConversationInterrupted)
	event.register(EVENTS.modStateChanged, this.onModStateChanged)
	event.register(EVENTS.conversationInteropStarted, this.onConversationInteropStarted)

	return true
end

---@private
function this.startScheduleTimer()
	if not mcm.enabled then
		return
	end

	this.scheduleTimer = timerManager.start({
		id = "conversationScheduler.startScheduleTimer",
		duration = mcm.conversationTimer,
		iterations = -1,
		onTick = this.onScheduleTimerTick,
	})
end

---@private
function this.stopScheduleTimer()
	if this.scheduleTimer then
		this.scheduleTimer:cancel()
		this.scheduleTimer = nil
	end
end

---@private
function this.restartScheduleTimer()
	this.stopScheduleTimer()
	this.startScheduleTimer()
end

---@private
---@param _ mwseTimerCallbackData
function this.onScheduleTimerTick(_)
	local chance = math.random()
	if chance <= mcm.conversationChance then
		this.scheduleConversation()
	end
end

---@private
function this.scheduleConversation()
	local npcs = npcLoader.load()
	if not npcs then
		this.scheduleTimer:cancel()
		return
	end

	local configuration = configurationSelector.select(npcs)
	if not configuration then
		return
	end

	local firstParticipant, secondParticipant = npcSelector.select(npcs, configuration)
	if not firstParticipant or not secondParticipant then
		return
	end

	this.scheduleTimer:cancel()

	---@type conversationScheduledEventData
	local payload = {
		conversation = {
			configuration = configuration,
			firstParticipant = firstParticipant,
			secondParticipant = secondParticipant,
		},
	}
	event.trigger(EVENTS.conversationScheduled, payload)
end

---@private
---@param _ loadEventData
function this.onLoad(_)
	this.stopScheduleTimer()
end

---@private
---@param _ loadedEventData
function this.onLoaded(_)
	this.startScheduleTimer()
end

---@private
---@param _ cellChangedEventData
function this.onCellChanged(_)
	this.restartScheduleTimer()
end

---@private
---@param _ conversationEndedEventData
function this.onConversationEnded(_)
	this.restartScheduleTimer()
end

---@private
---@param _ conversationInterruptedEventData
function this.onConversationInterrupted(_)
	this.restartScheduleTimer()
end

---@private
---@param _ modStateChangedEventData
function this.onModStateChanged(_)
	this.restartScheduleTimer()
end

---@private
function this.onConversationInteropStarted()
	this.stopScheduleTimer()
end

return this
