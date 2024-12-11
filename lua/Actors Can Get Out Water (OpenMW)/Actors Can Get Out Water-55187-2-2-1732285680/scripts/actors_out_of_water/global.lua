local core = require("openmw.core")

return {
	eventHandlers = {
		Move = function(e)
			e.actor:teleport(e.cell, e.position)
		end,
	},
}
