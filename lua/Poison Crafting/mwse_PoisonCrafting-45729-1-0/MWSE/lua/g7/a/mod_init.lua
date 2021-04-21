--[[
	Plugin: mwse_PoisonCrafting.esp
--]]

local function initialized(e)
	if tes3.isModActive("mwse_PoisonCrafting.esp") then
		-- load modules
		local common = require("g7.a.common")
		local apparatus = require("g7.a.apparatus")
		local poison = require("g7.a.poison")

		-- load user config
		common.loadConfig()

		-- load item labels
		common.loadLabels()

		-- load HUD context
		common.prepareHUD()

		-- check MCP status
		common.confirmMCP()

		-- register events
		common.register()
		apparatus.register()
		poison.register()

		mwse.log("[g7a] Initialized MWSE Poison Crafting v%d", common.config.version)
		mwse.log(json.encode(common.config, {indent=true}))
	end
end
event.register("initialized", initialized)
