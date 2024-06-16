local acti = require("openmw.interfaces").Activation
local types = require('openmw.types')

local function activateBook(cont, player)
	player:sendEvent("TakeAll_openedBook", {cont, player})
end

local function activateContainer(cont, player)
	player:sendEvent("TakeAll_openedContainer", {cont, player})
end

local function takeAll(data)
	local player = data[1]
	local container = data[2]
	local i =0
	for _, thing in pairs(types.Container.inventory(container):getAll(objtype)) do
		i=i+1
		thing:moveInto(types.Player.inventory(player))
	end
	player:sendEvent("TakeAll_closeUI")
	if i>0 then
		player:sendEvent("TakeAll_PlaySound","Item Ingredient Up")
	end
end

local function takeBook(data)
	local player = data[1]
	local book = data[2]
	book:moveInto(types.Player.inventory(player))
	player:sendEvent("TakeAll_closeUI")
	player:sendEvent("TakeAll_PlaySound","Item Book Up")
end

acti.addHandlerForType(types.Book, activateBook)
acti.addHandlerForType(types.Container, activateContainer)
acti.addHandlerForType(types.NPC, activateContainer)
acti.addHandlerForType(types.Creature, activateContainer)

return {
	eventHandlers = {
		TakeAll_takeAll = takeAll,
		TakeAll_takeBook = takeBook,
	}
}