local self = require('openmw.self')
--local ui = require('openmw.ui')
local settings = require("scripts.comprehensive_rebalance.lib.settings")

local function runHandler()
    local section = settings.GetSection("misc")
	if self.controls.run == true and section:get("noBackwardsRunning") and self.controls.movement < 0 then
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
