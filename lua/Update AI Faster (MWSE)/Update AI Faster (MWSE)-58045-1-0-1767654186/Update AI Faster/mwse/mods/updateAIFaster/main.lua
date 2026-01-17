local config = {}

local function setAIIntervalTime(e)
    e.mobile.scanInterval = config.aiUpdateTime
end

event.register(tes3.event.mobileActivated,  setAIIntervalTime)

event.register(tes3.event.modConfigReady, function()
    require("updateAIFaster.mcm")
	config = require("updateAIFaster.config").loaded
    print("[Update AI Faster] initialized")
end)