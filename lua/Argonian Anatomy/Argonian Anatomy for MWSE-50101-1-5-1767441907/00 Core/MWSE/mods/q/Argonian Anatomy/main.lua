local config = require("q.Argonian Anatomy.config")
local util = require("q.Argonian Anatomy.util")


local log = mwse.Logger.new({
	name = "Argonian Anatomy",
	logLevel = config.logLevel
})
dofile("q.Argonian Anatomy.mcm")

local playerSkeletonLoaded = false

--- This function returns references to all actors in active cells
--- A filter parameter can be passed (optional). Filter is
--- a table with tes3.objectType.* constants. If no filter is passed, { tes3.objectType.npc } is used as a filter.
---@param filter? integer|integer[]
---@return fun(): tes3reference
local function actorsInActiveCells(filter)
	filter = filter or { tes3.objectType.npc }
	local function iter()
		for _, cell in pairs(tes3.getActiveCells()) do
			for reference in cell:iterateReferences(filter, false) do
				coroutine.yield(reference)
			end
		end
	end
	return coroutine.wrap(iter)
end

local function processNPCs()
	for reference in actorsInActiveCells(tes3.objectType.npc) do
		local mob = reference.mobile
		if mob and not mob.werewolf then
			util.loadSkeleton(reference)
		end
	end
end

local function updatePlayer()
	if tes3.mobilePlayer.werewolf then
		if playerSkeletonLoaded then
			playerSkeletonLoaded = false
			util.removeSkeleton(tes3.player)
		end
		return
	end
	if playerSkeletonLoaded then return end

	playerSkeletonLoaded = true
	util.loadSkeleton(tes3.player)
end

local function setup()
	playerSkeletonLoaded = false
	if event.isRegistered(tes3.event.simulate, updatePlayer) then
		event.unregister(tes3.event.simulate, updatePlayer)
	end
	if not tes3.isCharGenFinished() then return end
	if not util.isArgonian(tes3.player) then return end

	event.register(tes3.event.simulate, updatePlayer)
end

event.register(tes3.event.loaded, setup)
event.register(tes3.event.charGenFinished, setup)
event.register(tes3.event.cellChanged, processNPCs)
