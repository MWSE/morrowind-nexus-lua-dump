local handleResolver = require("tauer.dynamic-conversations.services.handles.handleResolver")
local timerManager = require("tauer.dynamic-conversations.services.timers.timerManager")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

--- Encapsulates logic for animating NPCs
---@class npcAnimator : initializedService
local this = {}

---@private
---@type number
this.animationDuration = 0.2

---@private
---@type number
this.animationRate = 60

---@public
---@return boolean
function this.initialize()
	event.register(EVENTS.npcStateRestored, this.onNpcStateRestored)
	return true
end

--- Turns an NPC to face a target NPC over a short duration (shamelessly stolen from MWSE channel on Discord server)
---@public
---@param npc tes3npcInstance The NPC to turn
---@param target tes3npcInstance The target NPC to face
function this.faceNpc(npc, target)
	local targetAngle = math.rad(npc.mobile:getViewToActor(target.mobile))
	local iterations = this.animationDuration * this.animationRate

	timerManager.start({
		id = "npcAnimator.faceNpc",
		type = timer.simulate,
		duration = (1 / this.animationRate),
		iterations = iterations,
		onTick = this.onFaceNpcTimer,
		---@type faceNpcTimerData
		data = {
			npc = tes3.makeSafeObjectHandle(npc),
			target = tes3.makeSafeObjectHandle(target),
			angleChangePerIteration = targetAngle / iterations,
		},
	})
end

--- Plays the specified animation on the given NPC
---@public
---@param npc tes3npcInstance The NPC to play the animation on
---@param animation animation The animation to play
---@param loop? boolean Whether to loop the animation (default: false)
function this.playAnimation(npc, animation, loop)
	local reference = npc --[[@as tes3reference]]

	tes3.loadAnimation({ reference = reference, file = animation.path })

	local hasShieldEquipped = tes3.getEquippedItem({
		actor = npc.mobile,
		objectType = tes3.objectType.armor,
		slot = tes3.armorSlot.shield
	})

	local hasLightEquipped = tes3.getEquippedItem({
		actor = npc.mobile,
		objectType = tes3.objectType.light
	})

	if hasShieldEquipped then
		tes3.playAnimation({
			reference = reference,
			group = tes3.animationGroup[animation.group],
			shield = tes3.animationGroup.idle,
			loopCount = loop and -1 or 0,
		})
	elseif hasLightEquipped then
		tes3.playAnimation({
			reference = reference,
			group = tes3.animationGroup[animation.group],
			shield = tes3.animationGroup.torch,
			loopCount = loop and -1 or 0,
		})
	else
		tes3.playAnimation({
			reference = reference,
			group = tes3.animationGroup[animation.group],
			loopCount = loop and -1 or 0,
		})
	end
end

---@private
---@param callback mwseTimerCallbackData
function this.onFaceNpcTimer(callback)
	local timer = callback.timer

	---@type faceNpcTimerData
	local data = timer.data

	local npc = handleResolver.tryResolve({
		handle = data.npc,
		hint = "npcAnimator.onFaceNpcTimer.npc",
	})

	local target = handleResolver.tryResolve({
		handle = data.target,
		hint = "npcAnimator.onFaceNpcTimer.target",
	})

	if not npc or not target then
		return
	end

	---@cast npc -tes3reference, +tes3npcInstance
	---@cast target -tes3reference, +tes3npcInstance

	local currentAngleDifference = math.rad(npc.mobile:getViewToActor(target.mobile))
	if math.isclose(currentAngleDifference, 0, 0.1) then
		timer:cancel()
		return
	end

	local originalModified = npc.modified
	local orientation = npc.orientation:copy()

	---@cast npc +tes3reference
	npc.orientation = tes3vector3.new(orientation.x, orientation.y, orientation.z + data.angleChangePerIteration)
	npc.modified = originalModified
end

---@private
---@param eventData npcStateRestoredEventData
function this.onNpcStateRestored(eventData)
	this.resetAnimation(eventData.npc)
end

---@private
---@param npc tes3npcInstance The NPC to reset the animation for
function this.resetAnimation(npc)
	local reference = npc --[[@as tes3reference]]
	tes3.loadAnimation({ reference = reference, startFlag = tes3.animationStartFlag.normal })
end

return this
