local types = require('openmw.types')
local doOnce = {}




function harvest(data)
	local player = data[1]
	local obj = data[2]
	if doOnce[obj.id] then
		return
	end
	if obj.type == types.Item then
		doOnce[obj.id] = true
		obj:activateBy(player)
	elseif not types.Container.content(obj):isResolved() or types.Container.content(obj):getAll()[1] then
		doOnce[obj.id] = true
		obj:activateBy(player)
	end
end

return {
	eventHandlers = {
		HoldHarvest_harvest = harvest,
	},
}