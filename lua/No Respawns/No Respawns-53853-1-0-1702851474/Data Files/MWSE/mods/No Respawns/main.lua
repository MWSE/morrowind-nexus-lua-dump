
--- @param e leveledCreaturePickedEventData
local function onCreatureSpawn(e)
	-- No point in staying if there wasn't a result.
	if (e.pick == nil) then
		return
	end

	-- We only care about leveled creatures that come from a placed leveled creature reference.
	if (e.source ~= "reference") then
		return
	end

	-- We also just want to flat-out block all leveled creatures created during loading.
	if (tes3.dataHandler.nonDynamicData.isSavingOrLoading) then
		return false
	end

	local spawnerData = e.spawner.data
	local spawnedBefore = spawnerData.spawnedBefore
	local now = tes3.getSimulationTimestamp()

	if (spawnedBefore) then
		return false
	end

	-- Update our spawner to mark the cooldown.
	spawnerData.spawnedBefore = now
	e.spawner.modified = true
end
event.register(tes3.event.leveledCreaturePicked, onCreatureSpawn)
