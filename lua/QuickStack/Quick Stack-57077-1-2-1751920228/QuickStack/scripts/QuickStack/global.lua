local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
				
local function changeInventory(data)
	local playerCount
	--Re-getting player count of item in case it has changed to 0
	if tostring(data.sourceContainer.type) == 'Player' then
		local playerInventory = types.Actor.inventory(data.sourceContainer)
		playerCount = data.item.count
	-- If item count is now 0 then abort transfer
		if playerCount == 0 then return end
	end
	if tostring(data.destinationContainer.type) == 'Container' then
		data.item:moveInto(types.Container.content(data.destinationContainer))
	elseif tostring(data.destinationContainer.type) == 'NPC' or tostring(data.destinationContainer.type) == 'Actor' then
		data.item:moveInto(types.Actor.inventory(data.destinationContainer))
	end
end

local function togglePauseTag(tag)
end

return {
	eventHandlers = { 
	ChangeInventory = changeInventory,
	TogglePauseTag = togglePauseTag
	},
}