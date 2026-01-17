local types = require('openmw.types')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local doOnce = {}


local function harvest(data)
	local player = data[1]
	local obj = data[2]
	local now = core.getSimulationTime()
	
	if doOnce[obj.id] and now < doOnce[obj.id] then
		return
	end
	
	if obj.type == types.Item then
		obj:activateBy(player)
		doOnce[obj.id] = now + 0.5
	elseif not types.Container.content(obj):isResolved() or types.Container.content(obj):getAll()[1] then
		obj:activateBy(player)
		doOnce[obj.id] = now + 0.5
	end
end

function harvestNextFrame(data)
	async:newUnsavableSimulationTimer(0, function()
		harvest(data)
	end)
end

return {
	eventHandlers = {
		HoldHarvest_harvest = harvestNextFrame,
	},
}