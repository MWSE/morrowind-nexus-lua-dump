local mcm = require("teaMerchants.mcm")
local function initialized()
	if tes3.isModActive("Ashfall.esp") then
		require("teaMerchants.teaMerchant")
		require("teaMerchants.addTea")
		mwse.log("[%s %s] Initialized", mcm.mod, mcm.version)
	else
		tes3.messageBox("Tea Merchants requires Ashfall. Please install Ashfall to use this mod.")
	end
end
event.register("initialized", initialized)
require("teaMerchants.mcm")
