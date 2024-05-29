local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI

return {
	engineHandlers = {
        onUpdate = function()
        	
		if types.Actor.getStance(self)==1 then
			self.controls.movement=0
		end
		
		types.Actor.stats.attributes.speed(self).modifier=types.Actor.stats.attributes.speed(self).base*types.Actor.getEncumbrance(self)/types.NPC.getCapacity(self)

		if self.type~=types.Player then
			for i, actor in pairs(nearby.actors) do
				if actor.id~=self.id and actor.type==types.Creature and types.Actor.isDead(actor)==false then
					if AI.getActivePackage().target then
						if ((actor.position-self.position):length()<(AI.getActivePackage().target.position-self.position):length() or types.Actor.isDead(actor)==false) and actor~=AI.getActivePackage().target  then
							AI.startPackage({type='Combat',target=actor})
						elseif types.Actor.isDead(AI.getActivePackage().target) and  (actor.position-self.position):length()<2000 then
							AI.startPackage({type='Combat',target=actor})
						end
					elseif (actor.position-self.position):length()<3000 then
						AI.startPackage({type='Combat',target=actor})
					end
				end
			end
		end

	end
	}
}


