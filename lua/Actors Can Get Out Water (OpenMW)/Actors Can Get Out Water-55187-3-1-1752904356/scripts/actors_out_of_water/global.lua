local core = require("openmw.core")

return {
	eventHandlers = {
		ll_Actors_Out_Of_Water_Move = function(e)
			e.actor:teleport(e.cell, e.position)
		end,
	},
}
