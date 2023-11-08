local self = require('openmw.self')
--local ui = require('openmw.ui')
local storage = require('openmw.storage')

local MOD_NAME = "comprehensive_rebalance"
local settings = storage.globalSection("SettingsGlobal" .. MOD_NAME .. "misc")

local function runHandler()
	if self.controls.run == true and settings:get("noBackwardsRunning") and self.controls.movement < 0 then
		self.controls.run = false  -- prevent running
		--ui.showMessage("why are u running?")
	end
end

return
{
	engineHandlers =
	{
		onFrame = runHandler
	}
}