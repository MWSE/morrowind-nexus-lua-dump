local types = require('openmw.types')

function takeAllItems(e)
	containerInventory = e.container
	local containerInventory = types.Container.content(e.container)
	local playerInventory = types.Actor.inventory(e.player)
	
	local object_list = containerInventory:getAll()
	
	for index, item in pairs(object_list) do
		item:moveInto(playerInventory)
	end
end

function takeBook(e)
	bookItem = e.book
	local playerInventory = types.Actor.inventory(e.player)
	bookItem:moveInto(playerInventory)
end

return {
	eventHandlers = {
		takeAllEvent = takeAllItems,
		takeBook = takeBook
	}
}