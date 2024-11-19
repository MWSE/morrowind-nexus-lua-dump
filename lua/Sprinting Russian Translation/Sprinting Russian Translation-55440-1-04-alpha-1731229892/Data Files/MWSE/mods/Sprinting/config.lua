local this = {}

this.configPath = "sprinting"
this.defaults = {
	enableMod                        = true,
    speedMultiplierMaxAmount         = 1.75,
    speedMultiplierIncrement         = 0.075,
    fatigueDrawbackMaxAmount         = 0.75,
    fatigueDrawbackMinAmount         = 0.25,
    fatigueDrawbackAthleticsModifier = 0.005,
    fatigueDrawbackAllowFainting     = false,
    minimumRecoveryDuration          = 10,
    minimumRecoveryFatiguePercentage = 0.5,
    enableRecoveryNotifications      = true,
    enableSprintingZoom              = true,
    defaultZoomAmount                = 1.0,
    sprintingZoomMaxAmount           = 1.075,
    sprintingZoomSpeed               = 0.01,
    keySprinting                     = {
		    keyCode       = tes3.scanCode.lAlt,
		    isShiftDown   = false,
		    isAltDown     = false,
		    isControlDown = false
		},
	enableMultiDirectionalMovement   = false
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
		        		event.trigger("Sprinting:UpdateConfiguration")
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