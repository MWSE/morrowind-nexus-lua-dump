local common = require("JosephMcKean.furnitureCatalogue.common")
local config = require("JosephMcKean.furnitureCatalogue.config")

local logging = require("JosephMcKean.furnitureCatalogue.logging")

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = common.mod })
	template:saveOnClose(common.mod, config)
	local settings = template:createSideBarPage({ label = "Settings" })
	settings:createSlider({
		label = "Stock Amount",
		description = "Set the maximim number of in stock furniture every day. Default: 50",
		min = 0,
		max = 600,
		step = 1,
		variable = mwse.mcm.createTableVariable { id = "stockAmount", table = config },
	})
	settings:createOnOffButton({
		label = "Debug mode",
		variable = mwse.mcm.createTableVariable { id = "debugMode", table = config },
		callback = function(self) for _, log in ipairs(logging.loggers) do log:setLogLevel(self.variable.value and "DEBUG" or "INFO") end end,
	})
	template:register()
end

event.register("modConfigReady", registerModConfig)
