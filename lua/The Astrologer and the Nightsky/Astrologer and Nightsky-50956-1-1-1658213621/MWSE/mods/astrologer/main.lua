local seph = include("seph")
if not seph or seph.version:isLessThan(seph.Version:new{major = 1, minor = 0, patch = 0}) then
	event.register("enterFrame",
		function()
			tes3.messageBox{message = "'The Astrologer and the Nightsky' requires a newer version of 'Seph's Library'. Please close Morrowind and install the most recent version.", buttons = {"Okay"}}
		end,
		{doOnce = true}
	)
	return
end

local mod = require("astrologer.mod")
mod:run()