local handleResolver = require("tauer.dynamic-conversations.services.handles.handleResolver")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

local logger = mwse.Logger.new()

--- Encapsulates logic for managing NPC states during conversations
---@class npcStateManager : initializedService
local this = {}

---@private
---@type { [mwseSafeObjectHandle]: npcState }
this.cachedOriginalStates = {}

---@private
---@type { [mwseSafeObjectHandle]: npcState }
this.cachedConversationStates = {}

---@private
---@type { [mwseSafeObjectHandle]: npcState }
this.cachedOriginalStatesCombat = {}

---@public
---@return boolean
function this.initialize()
	event.register(EVENTS.conversationScheduled, this.onConversationScheduled)
	event.register(EVENTS.conversationEnded, this.onConversationEnded)
	event.register(EVENTS.conversationInterrupted, this.onConversationInterrupted)
	event.register(tes3.event.save, this.onSave)
	event.register(tes3.event.saved, this.onSaved)
	event.register(tes3.event.combatStart, this.onCombatStart)
	event.register(tes3.event.combatStopped, this.onCombatStopped)

	return true
end

---@private
---@param eventData conversationScheduledEventData
function this.onConversationScheduled(eventData)
	local firstParticipant = eventData.conversation.firstParticipant
	local secondParticipant = eventData.conversation.secondParticipant

	this.saveState(firstParticipant)
	this.saveState(secondParticipant)
	this.disableHello(firstParticipant)
	this.disableHello(secondParticipant)
end

---@private
---@param _ conversationEndedEventData
function this.onConversationEnded(_)
	this.restoreStates()
end

---@private
---@param _ conversationInterruptedEventData
function this.onConversationInterrupted(_)
	this.restoreStates()
end

---@private
---@param npc tes3npcInstance
function this.saveState(npc)
	local handle = tes3.makeSafeObjectHandle(npc)
	local state = this.getState(npc --[[@as tes3reference]])

	this.cachedOriginalStates[handle] = state
end

---@private
function this.restoreStates()
	for handle, state in pairs(this.cachedOriginalStates) do
		local npc = handleResolver.tryResolve({
			handle = handle,
			hint = "npcStateManager.restoreStates.handle",
		})

		this.cachedOriginalStates[handle] = nil

		if npc then
			this.applyState(npc, state)

			local payload = {
				npc = npc --[[@as tes3npcInstance]]
			}
			event.trigger(EVENTS.npcStateRestored, payload)
		end
	end
end

---@private
function this.onSave()
	for handle, originalState in pairs(this.cachedOriginalStates) do
		local npc = handleResolver.tryResolve({
			handle = handle,
			hint = "npcStateManager.onSave.handle",
		})

		local conversationState = this.getState(npc)

		if npc and conversationState then
			this.cachedConversationStates[handle] = conversationState
			this.applyState(npc, originalState)
		end
	end
end

---@private
function this.onSaved()
	for handle, conversationState in pairs(this.cachedConversationStates) do
		local npc = handleResolver.tryResolve({
			handle = handle,
			hint = "npcStateManager.onSaved.handle",
		})

		this.cachedConversationStates[handle] = nil

		if npc then
			this.applyState(npc, conversationState)
		end
	end
end

---@private
---@param eventData combatStartEventData
function this.onCombatStart(eventData)
	for handle, state in pairs(this.cachedOriginalStates) do
		local npc = handleResolver.tryResolve({
			handle = handle,
			hint = "npcStateManager.onCombatStart.handle",
		})

		if not npc then
			this.cachedOriginalStates[handle] = nil
		end

		if npc and (npc == eventData.actor.reference or npc == eventData.target.reference) then
			this.cachedOriginalStatesCombat[handle] = state
			this.cachedOriginalStates[handle] = nil
		end
	end
end

---@private
---@param eventData combatStoppedEventData
function this.onCombatStopped(eventData)
	for handle, state in pairs(this.cachedOriginalStatesCombat) do
		local npc = handleResolver.tryResolve({
			handle = handle,
			hint = "npcStateManager.onCombatStopped.handle",
		})

		if not npc then
			this.cachedOriginalStatesCombat[handle] = nil
		end

		if npc and npc == eventData.actor.reference then
			this.applyState(npc, state)
			this.cachedOriginalStatesCombat[handle] = nil
		end
	end
end

---@private
---@param npc tes3reference
---@param state npcState
function this.applyState(npc, state)
	local modified = npc.modified

	if state.packageType == tes3.aiPackage.wander then
		tes3.setAIWander({
			reference = npc,
			idles = state.idleChances,
			range = state.range,
			duration = state.duration,
		})
	elseif state.packageType == tes3.aiPackage.travel then
		tes3.setAITravel({
			reference = npc,
			destination = state.destination,
			reset = false,
		})
	end

	npc.mobile.hello = state.helloValue
	npc.modified = modified
end

---@private
---@param npc tes3reference|nil
---@return npcState|nil
function this.getState(npc)
	if not npc then
		return nil
	end

	local package = npc.mobile and npc.mobile.aiPlanner and npc.mobile.aiPlanner:getActivePackage()
	if not package then
		logger:error("Package for '%s' was nil", npc.object.id)
		return nil
	end

	---@type npcState
	local state = {
		position = npc.mobile.position:copy(),
		helloValue = npc.mobile.hello,
		idleChances = this.idlesNodesToIdleChances(package.idles),
		range = package.distance,
		duration = package.duration,
		packageType = package.type,
		orientation = npc.orientation:copy(),
		destination = package.destination and package.destination:copy() or nil,
	}

	return state
end

---@private
---@param idlesNodes tes3aiPackageWanderIdleNode[]
---@return aiPackageIdleChance[]
function this.idlesNodesToIdleChances(idlesNodes)
	if not idlesNodes then
		return {}
	end
	---@type aiPackageIdleChance[]
	local idlesChances = {}
	for _, idle in ipairs(idlesNodes) do
		idlesChances[idle.index] = idle.chance
	end
	return idlesChances
end

---@private
---@param npc tes3npcInstance
function this.disableHello(npc)
	npc.mobile.hello = 0
end

return this
