local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")

return {
	engineHandlers = {
		onUpdate = function()
			if types.Actor.isSwimming(self) then
				core.sendGlobalEvent("STV_Water_Safe")
			end
		end,
	},
}
