local world = require('openmw.world')
local types = require('openmw.types')

return {
  eventHandlers = {
    grm_setGlobals = function(data)
      world.mwscript.getGlobalVariables()[data.name] = data.value
    end,
		grm_addItem = function(data) -- data = {source = obj, id = str, count = int} | if count is not provided then 1 object is added.
			local item = world.createObject(data.id, data.count)
			item:moveInto(types.Actor.inventory(data.source))
			data.source:sendEvent('grm_itemAdded', item)
		end,
		grm_removeItem = function(data) -- data = {item = obj, count = int} | if count is not provided then the entire stack is removed
			data.item:remove(data.count)
			data.source:sendEvent('grm_itemRemoved', data.item)
		end,
  }
}
