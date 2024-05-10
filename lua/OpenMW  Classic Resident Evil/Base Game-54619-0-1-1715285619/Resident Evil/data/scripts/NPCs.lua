local self=require('openmw.self')
local types = require('openmw.types')

return {
	engineHandlers = {
        onUpdate = function()
        	
		if types.Actor.getStance(self)==1 then
			self.controls.movement=0
		end
		
		types.Actor.stats.attributes.speed(self).modifier=types.Actor.stats.attributes.speed(self).base*types.Actor.getEncumbrance(self)/types.NPC.getCapacity(self)


	end
	}
}


