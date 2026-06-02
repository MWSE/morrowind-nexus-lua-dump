local core = require("openmw.core")

return {
	eventHandlers = {
		ll_ActorsOverObstacles_Move = function(e)
			e.actor:teleport(e.cell, e.position)
		end,
	},
}
