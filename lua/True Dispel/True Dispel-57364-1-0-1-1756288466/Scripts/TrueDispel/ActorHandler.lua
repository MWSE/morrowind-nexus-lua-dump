local types = require("openmw.types")

local cooldowns={}
local actorHandler = {engineHandlers = {},eventHandlers={}}

local function dispel(actor)
	for effectRefId,effect in pairs(types.Actor.activeSpells(actor)) do
		if effect.temporary then
			local id = effect.activeSpellId
			types.Actor.activeSpells(actor):remove(id)
		end
	end
end

function actorHandler.eventHandlers.onCastDispel(actor)
	dispel(actor)
end

return actorHandler
