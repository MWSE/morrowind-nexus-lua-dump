local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")
local handleResolver = require("tauer.dynamic-conversations.services.handles.handleResolver")
local timerManager = require("tauer.dynamic-conversations.services.timers.timerManager")

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Encapsulates logic for manipulating NPC movement
---@class npcMover
local this = {}

---@private
---@type number
this.interval = 0.5 -- Check every half second

---@private
---@type number
this.maxIterations = 360 -- Wait for max 3 minutes

---@private
---@type number
this.distanceThreshold = 150

--- Makes the NPC wait in place
---@public
---@param npc tes3npcInstance The NPC to make wait
function this.wait(npc)
	this.freeze(npc)
end

--- Makes an NPC approach a target NPC
---@public
---@param params approachParams The approach parameters
function this.approach(params)
	local npc = params.npc
	local target = params.target

	---@cast npc +tes3reference, -tes3npcInstance
	tes3.setAITravel({
		reference = npc,
		destination = target.mobile.position,
		reset = false,
	})

	timerManager.start({
		id = "npcMover.approach",
		duration = this.interval,
		iterations = this.maxIterations,
		onTick = this.onApproachTimerTick,
		onExpire = this.onApproachTimerExpire,
		cancellationEvents = { EVENTS.conversationInterrupted },
		---@type approachTimerData
		data = {
			npc = tes3.makeSafeObjectHandle(npc),
			target = tes3.makeSafeObjectHandle(target),
			onApproached = params.onApproached,
		},
	})
end

---@private
---@param npc tes3npcInstance
function this.freeze(npc)
	---@cast npc +tes3reference, -tes3npcInstance
	tes3.setAIWander({
		reference = npc,
		idles = this.zeroIdles(),
		range = 0,
		duration = 0,
	})
end

---@private
---@return table<number, number>
function this.zeroIdles()
	return {
		[tes3.animationGroup.idle] = 0,
		[tes3.animationGroup.idle2] = 0,
		[tes3.animationGroup.idle3] = 0,
		[tes3.animationGroup.idle4] = 0,
		[tes3.animationGroup.idle5] = 0,
		[tes3.animationGroup.idle6] = 0,
		[tes3.animationGroup.idle7] = 0,
		[tes3.animationGroup.idle8] = 0,
		[tes3.animationGroup.idle9] = 0,
	}
end

---@private
---@param callback mwseTimerCallbackData
function this.onApproachTimerTick(callback)
	local timer = callback.timer

	---@type approachTimerData
	local data = timer.data

	local npc = handleResolver.tryResolve({
		handle = data.npc,
		hint = "npcMover.onApproachTimerTick.npc",
	})

	local target = handleResolver.tryResolve({
		handle = data.target,
		hint = "npcMover.onApproachTimerTick.target",
	})

	if not npc or not target then
		return
	end

	if npc.position:distance(target.mobile.position) < this.distanceThreshold then
		timer:cancel()
		---@cast npc +tes3npcInstance, -tes3reference
		---@cast target +tes3npcInstance, -tes3reference
		data.onApproached(npc, target)
		return
	end
end

---@private
---@param callback mwseTimerCallbackData
function this.onApproachTimerExpire(callback)
	---@type approachTimerData
	local data = callback.timer.data

	local npc = handleResolver.tryResolve({
		handle = data.npc,
		hint = "npcMover.onApproachTimerExpire.npc",
	})

	if not npc then
		return
	end

	---@type npcTravelTimeExceededEventData
	local payload = {
		npc = npc --[[@as tes3npcInstance ]],
	}
	event.trigger(EVENTS.npcTravelTimeExceeded, payload)
end

return this
