local Activation = require('openmw.interfaces').Activationlocal types = require("openmw.types")

local desactivate = {}
local targetActor


local function ActivationHandlerForActor()
	Activation.addHandlerForObject(targetActor, function(object, actor)
		if actor.type == types.Player then
			if desactivate[targetActor] then
				return false -- Other handlers for the same object (including type handlers) will be skipped (So, no dialogue)
			else
				return true
			end
		end
	end)
end


return {
	eventHandlers = {
		ll_NoMorePassiveActors_Dialogue = function(e)
			targetActor = e.actor
			if desactivate[targetActor] == nil then -- If the activation handler isn't defined for this actor then
				desactivate[targetActor] = e.desactivate -- Desactivate dialogue variable (true or false)
				ActivationHandlerForActor() -- we define the activation handler for this actor
			else
				desactivate[targetActor] = e.desactivate
			end
		end,
	},
}
