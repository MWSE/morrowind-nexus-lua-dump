-- Checking whether Locks and Traps Detection is on
local LnTDLockData = include("AdituV.DetectTrap.LockData")
local LnTDConfig

if LnTDLockData then
	event.register("modConfigReady", function()
		LnTDConfig = require("AdituV.DetectTrap.Config")
		if LnTDConfig.modEnabled == false then
			LnTDLockData = nil
		end
	end)
end

--- @param reference tes3reference
local function clearVisual(reference)
	if not reference.sceneNode then return end

	local activeEffectNode = reference.sceneNode:getObjectByName("SoulActive")
	if activeEffectNode then
		activeEffectNode.appCulled = true
	end

	-- Try to remove the enchanted effect.
	reference.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
	reference.sceneNode:updateEffects()
end

local trappable = {
	[tes3.objectType.container] = true,
	[tes3.objectType.door] = true,
}

--- @param reference tes3reference
local function canApplyVisual(reference)
	if not trappable[reference.object.objectType]
	or not reference.lockNode then
		return false
	end

	local trap = reference.lockNode.trap
	if not trap then
		return false
	end

	-- L&TD is on and trap wasn't detected by it? No effect.
	if LnTDLockData then
		local ld = LnTDLockData.getForReference(reference)
		ld:attemptDetectTrap()
		if not ld:getTrapDetected() then
			return false
		end
	end

	return true
end

--- @param reference tes3reference
local function applyVisual(reference)
	if not canApplyVisual(reference) then return end
	--- @diagnostic disable-next-line: param-type-mismatch
	tes3.worldController:applyEnchantEffect(reference.sceneNode, reference.lockNode.trap)
	reference.sceneNode:updateEffects()
end


local function onInitialized()
	event.register(tes3.event.referenceSceneNodeCreated, function(e)
		applyVisual(e.reference)
	end)
end
event.register(tes3.event.initialized, onInitialized)


--- @param e trapDisarmEventData
local function onTrapDisarm(e)
	local handle = tes3.makeSafeObjectHandle(e.reference) --[[@as mwseSafeObjectHandle]]
	timer.delayOneFrame(function()
		if not handle:valid() then return end
		local ref = handle:getObject()
		clearVisual(ref)
	end)
end

event.register(tes3.event.trapDisarm, onTrapDisarm, { priority = -300 })