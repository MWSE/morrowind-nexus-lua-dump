local function Loading(e)
	mwse.log("[Neo Combat] Initialized.")
end
event.register("initialized", Loading)

local function OnGameStart(e)
	require("OEA.OEA1 Neo.config")
	require("OEA.OEA1 Neo.spells")
	require("OEA.OEA1 Neo.rage")
	require("OEA.OEA1 Neo.bash")
	require("OEA.OEA1 Neo.block")
	require("OEA.OEA1 Neo.counter")
end
event.register("loaded", OnGameStart)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    	require("OEA.OEA1 Neo.mcm")
end)