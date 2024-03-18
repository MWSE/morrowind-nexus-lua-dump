--[[
only attack to/from player will trigger Battle music
]]

-- begin configurable params
local logLevel = 0 -- set it to 0/1 to disable/enable logging
local eventPriority = 20000 -- increase if needed
-- end configurable params

local author = 'abot'
local modName = 'Smart Battle Music'
local modPrefix = author .. '/'.. modName

local situations = table.invert(tes3.musicSituation)

local lastAttacker, lastTarget

local function resetLastAttackerAndTarget()
	lastAttacker = nil
	lastTarget = nil
end

local player, mobilePlayer

local function combatStarted(e)
	lastAttacker = e.actor
	lastTarget = e.target
end

local tes3_musicSituation_combat = tes3.musicSituation.combat

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_escort = tes3.aiPackage.escort
---local tes3_aiPackage_wander = tes3.aiPackage.wander
--- nope no room local tes3_aiPackage_none = tes3.aiPackage.none

---local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

local function isValidMobile(mob)
	local mobRef = mob.reference
	if mobRef.disabled then
		return false
	end
	if mobRef.deleted then
		return false
	end
	if mob.actorType == tes3_actorType_npc then
		return true
	end
	local mobObj = mobRef.object
	local lcId = string.lower(mobObj.id)
	if lcId == 'ab01guguarpackmount' then -- this is a good one
		return true
	end
	if string.startswith(lcId, 'ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
		return false
	end
	local script = mobObj.script
	if script then
		local lcId2 = string.lower(script.id)
		if string.startswith(lcId2, 'ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
			if logLevel >= 3 then
				mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, mobRef.id)
			end
			return false
		end
	end
	return true
end

local function isValidFollower(mob)
	local aiPlanner = mob.aiPlanner
	if not aiPlanner then
		return false
	end
	local activePackage = aiPlanner:getActivePackage()
	if activePackage then
		local ai = activePackage.type
		if (ai == tes3_aiPackage_follow)
		or (ai == tes3_aiPackage_escort) then
			local targetActor = activePackage.targetActor
			if mobilePlayer == targetActor then
				return true
			end
		end
	end
	return false
end

local function musicSelectTrack(e)
	if not (e.situation == tes3_musicSituation_combat) then
		return
	end
	if not lastAttacker then
		return
	end
	if not lastTarget then
		return
	end
	if lastTarget == mobilePlayer then
		return
	end
	if lastAttacker == mobilePlayer then
		return
	end
	if isValidFollower(lastAttacker)
	and isValidMobile(lastAttacker) then
		return
	end
	if isValidFollower(lastTarget)
	and isValidMobile(lastTarget) then
		return
	end
	if logLevel > 0 then
		mwse.log([[%s: musicSelectTrack(e) e.situation = %s (%s)
lastAttacker = "%s", lastTarget = "%s", skip changing music]],
		modPrefix, e.situation, situations[e.situation], lastAttacker.reference, lastTarget.reference)
	end
	resetLastAttackerAndTarget()
	return false
end

local doOnce = false
local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	resetLastAttackerAndTarget()
	if doOnce then
		return
	end
	doOnce = true
	event.register('musicSelectTrack',
		musicSelectTrack, {priority = eventPriority})
	event.register('combatStarted',
		combatStarted, {prority = eventPriority})
end

event.register('modConfigReady',
	function ()	event.register('loaded', loaded) end
)
