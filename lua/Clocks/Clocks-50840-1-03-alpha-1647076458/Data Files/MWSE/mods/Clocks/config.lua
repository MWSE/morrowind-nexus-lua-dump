local constants = require("Clocks.common.constants")

local relativePositions = constants.enumRelativePositions

local this = {}

this.configPath = "clocks"
this.defaults = {
	enableMod              = true,
    showGameTime           = true,
    showRealTime           = false,
    useTwelveHourTime      = true,
    clocksRelativePosition = relativePositions.above,
    enableUISetupsCycling  = true,
    keyUISetupsCycling     = {
		    keyCode       = tes3.scanCode.n,
		    isShiftDown   = false,
		    isAltDown     = false,
		    isControlDown = false
		}
}

local loadedConfig = mwse.loadConfig(this.configPath, this.defaults)
local updateTimer = {
	state = timer.expired
}

this.config = setmetatable(
	{
	    save = function(triggerUpdate)

	        mwse.saveConfig(this.configPath, loadedConfig)

	        if triggerUpdate and updateTimer.state == timer.expired then
        		--[[
        			Info: We trigger the update during a simulation in order for the layout to
        			update on time.
        		]]--
	        	updateTimer = timer.delayOneFrame(
	        		function()
		        		event.trigger("Clocks:UpdateConfiguration")
		        	end
	      		)
	        end
	    end
	},
	{
	    __index = function(_, key)
	        return loadedConfig[key]
	    end,
	    __newindex = function(_, key, value)
	        loadedConfig[key] = value
	    end,
	}
)

return this