local common = require("York.Extradimensional Pockets.common")
local confPath = "York_Pockets"
local config = mwse.loadConfig(confPath)

if not config then config = {} end

local function registerModConfig(e)
	common.info("Registering MCM Menu")
	local menu = mwse.mcm.createTemplate{name = "Extradimensional Pockets"}
	menu:saveOnClose(confPath, config)
	
	--main page
	local features = menu:createPage("Mod Features")
	local emc = features:createCategory("Emergency Buttons")
	
	emc:createButton{
		buttonText = "Panic Button",
		description = "will pull all items from all pockets to players inventory",
		callback = function() event.trigger("York:PocketPanic") end,
		inGameOnly = true
	}
	
	mwse.mcm.register(menu)
	common.info("Created MCM Menu")
end
common.info("registering for mod config")
event.register("modConfigReady", registerModConfig)
common.info("registered for mod config")
return config