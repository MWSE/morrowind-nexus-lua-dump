local core = require('openmw.core')

return {
	eventHandlers = {
		doRemoveItem = function(data)
			local count = data.count
			local sender = data.sender
		
			sender:remove(count)
		end
	}
}