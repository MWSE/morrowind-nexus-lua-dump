local seph = include("seph")
if not seph or seph.version:isLessThan(seph.Version:new{major = 1, minor = 0, patch = 0}) then
	event.register("enterFrame",
		function()
			tes3.messageBox{message = "\"Захват душ NPC\" требует более новой версии \"Seph's Library\". Пожалуйста, закройте Morrowind и установите последнюю версию.", buttons = {"Ок"}}
		end,
		{doOnce = true}
	)
	return
end

local mod = require("seph.npcSoulTrapping.mod")
mod:run()