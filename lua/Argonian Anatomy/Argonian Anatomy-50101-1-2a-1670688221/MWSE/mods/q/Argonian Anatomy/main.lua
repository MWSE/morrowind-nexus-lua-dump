local util = require("q.Argonian Anatomy.util")

local transformed = false

-- This function returns references to all actors in active cells, and optionally
-- the player reference. A filter parameter can be passed (optional). Filter is
-- a table with tes3.objectType.* constants. If no filter is passed, { tes3.objectType.npc } is used as a filter.
---@param includePlayer boolean
---@param filter number|number[]|nil
---@return tes3reference[]
local function actorsInActiveCells(includePlayer, filter )
    includePlayer = includePlayer or false
    filter = filter or { tes3.objectType.npc }

    return coroutine.wrap(function() ---@diagnostic disable-line
        for _, cell in pairs(tes3.getActiveCells()) do
            for reference in cell:iterateReferences(filter) do
                coroutine.yield(reference)
            end
        end
        if includePlayer then
            coroutine.yield(tes3.player)
        end
    end)
end

local function processNPCs()
    for reference in actorsInActiveCells(false, { tes3.objectType.npc }) do
		if reference.mobile and (not reference.mobile.werewolf) and (not reference.disabled) then
			util.loadSkeleton(reference)
		end
    end
end

local function updatePlayer()
	if tes3.mobilePlayer.werewolf then
		if transformed then
			transformed = false
			util.removeSkeleton(tes3.player)
			return
		else
			return
		end
	else
		if not transformed then
			transformed = true
			util.loadSkeleton(tes3.player)
			return
		else
			return
		end
	end
end

local function setup()
	transformed = false
	if event.isRegistered(tes3.event.simulate, updatePlayer) then
		event.unregister(tes3.event.simulate, updatePlayer)
	end
	if not tes3.isCharGenFinished() then return end
	if not util.isArgonian(tes3.player) then return end

	event.register(tes3.event.simulate, updatePlayer)
end

event.register(tes3.event.initialized, function()
	event.register(tes3.event.loaded, setup)
	event.register(tes3.event.charGenFinished, setup)
    event.register(tes3.event.cellChanged, processNPCs)
end)

event.register(tes3.event.modConfigReady, function()
	dofile("q.Argonian Anatomy.mcm")
end)
