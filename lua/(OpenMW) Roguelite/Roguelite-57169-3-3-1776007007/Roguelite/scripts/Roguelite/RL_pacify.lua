local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')

local function onLoad()
	local player = nearby.players[1]
	if player then
		local actorHealth = types.Actor.stats.dynamic.health(self)
		actorHealth.base = actorHealth.base * 1.02 + types.Actor.stats.level(player).current * 1.5 + 5
		actorHealth.current = actorHealth.base
	end
	core.sendGlobalEvent("Roguelite_detachPacify", self)
end

return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
	}
}
