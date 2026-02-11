local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')


local function onActivated(actor)
	--print("item onActivated!")
	--print(self.object.recordId)
	core.sendGlobalEvent("onItemActivated", self.object) 
end


return {
	engineHandlers = {
		onActivated = onActivated
	},


}
