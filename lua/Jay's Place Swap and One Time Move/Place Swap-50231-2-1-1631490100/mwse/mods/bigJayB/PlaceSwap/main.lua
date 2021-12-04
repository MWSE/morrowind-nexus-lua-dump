local mcm = require("bigJayB.PlaceSwap.mcm")
local conf = require("bigJayB.PlaceSwap.mer_save").config

--swap positions with npcs.
local function swapPcs(ref)
	-- gets player current cell
	local current_cell = tes3.getPlayerCell()
	-- get copy of the player's position
	local player_pos = tes3.mobilePlayer.position:copy()
	-- get copy of the npc's position
	local npc_pos = ref.position:copy()
	-- swaps both using position cell
	tes3.positionCell(
		{
		  reference = tes3.mobilePlayer,
		  cell = current_cell,
		  position = npc_pos,
		  forceCellChange = false,
		  suppressFader = true,
		  teleportCompanions = false
		}
	)
	tes3.positionCell(
		{
		  reference = ref,
		  cell = current_cell,
		  position = player_pos,
		  forceCellChange = false,
		  suppressFader = true,
		  teleportCompanions = false
		}
	)
	return
end

-- moves the NPC using AIWander given a range.
local function wander(ref, ran, dur)
	tes3.setAIWander(
		{
			reference = ref,
			idles = { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
			range = ran,
			duration = dur,
			reset = true
		}
	)
	return
end

-- makes npcs move around and stop after 3 seconds.
local function moveAway(ref)
	wander(ref, 100, 1)
	local wanderingTimer = timer.start(
		{
			duration = 3,
			callback = function ()
				wander(ref, 0, 0)
			end
		}
	)
end

-- returns true if ref is a passive npc, false otherwise.
local function isRefValid(ref)
	if (ref ~= nil and ref.object.objectType == tes3.objectType.npc) then
		if not (ref.object.mobile.inCombat) then
			return true
		end
	end
	return false
end

-- checks if player is looking at an npc
-- and executes the proper use cases.
local function checkTarget(e)
	local target_ref = tes3.getPlayerTarget()
	if (e.isShiftDown and isRefValid(target_ref)) then
		swapPcs(target_ref)
	end
	if (e.isControlDown and isRefValid(target_ref)) then
		moveAway(target_ref)
	end
	return
end

local function init()
	event.register("keyDown", checkTarget, { filter = conf.key.keyCode } )
	mwse.log("[Jay's Place Swap & Move Away] Initialized!")
	return
end

event.register('initialized', init)