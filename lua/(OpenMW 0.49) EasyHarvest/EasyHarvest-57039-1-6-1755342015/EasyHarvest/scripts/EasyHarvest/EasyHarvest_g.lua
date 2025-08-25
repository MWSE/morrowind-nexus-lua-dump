local types = require('openmw.types')

function harvest(data)
	local player = data[1]
	local obj = data[2]
	if obj.type == types.Item then
		obj:activateBy(player)
	elseif not types.Container.content(obj):isResolved() or types.Container.content(obj):getAll()[1] then
		--doOnce[obj.id] = true
		obj:activateBy(player)
	end
end

return {
	eventHandlers = {
		HoldHarvest_harvest = harvest,
	},
}