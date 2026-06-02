local world = require("openmw.world")

return {
	eventHandlers = {
		STV_Water_Safe = function()
			world.mwscript.getGlobalVariables()["STV_Sun"] = -1
		end,
	},
}
