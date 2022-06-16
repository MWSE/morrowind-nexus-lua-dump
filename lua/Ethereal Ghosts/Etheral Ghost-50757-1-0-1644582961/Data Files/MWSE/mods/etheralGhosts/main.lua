event.register("modConfigReady", function()
    require("etheralGhosts.mcm")
	config  = require("etheralGhosts.config")
end)

local function onMobileActivate(e)
	if e.mobile.reference and e.mobile.reference.baseObject and config.ghosts[e.mobile.reference.baseObject.id:lower()] then
		e.mobile.movementCollision = false
	end
end

local function onInitialized(e)
	if config.modEnabled then
		event.register("mobileActivated", onMobileActivate)
		mwse.log("[Etheral Ghosts]: enabled")
	else
		mwse.log("[Etheral Ghosts]: disabled")
	end
end

event.register("initialized", onInitialized)