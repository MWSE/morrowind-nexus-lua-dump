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
local function loaded()
	lastAttacker = nil
	lastTarget = nil
end
event.register('loaded', loaded)

local function combatStart(e)
	lastAttacker = e.actor
	lastTarget = e.target
end
event.register('combatStart', combatStart, {prority = eventPriority})

local tes3_musicSituation_combat = tes3.musicSituation.combat

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
	local mobilePlayer = tes3.mobilePlayer
	if lastTarget == mobilePlayer then
		return
	end
	if lastAttacker == mobilePlayer then
		return
	end
	if logLevel > 0 then
		mwse.log([[%s: musicSelectTrack(e) e.situation = %s (%s)
lastAttacker = "%s", lastTarget = "%s", skip changing music]],
		modPrefix, e.situation, situations[e.situation], lastAttacker.reference, lastTarget.reference)
	end
	return false
end
event.register('musicSelectTrack', musicSelectTrack, {priority = eventPriority})