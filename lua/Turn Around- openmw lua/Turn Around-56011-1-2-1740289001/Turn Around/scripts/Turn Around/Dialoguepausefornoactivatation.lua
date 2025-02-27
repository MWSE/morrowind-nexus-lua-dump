local core = require('openmw.core')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')

-- Variable to hold our timer function
local stopFn

return {
    eventHandlers = {
        UiModeChanged = function(data)
            -- Check if we just entered dialogue mode and were not in any mode before
            if data.newMode == 'Dialogue' and data.oldMode == nil then
                -- If there's an existing timer, cancel it to prevent multiple timers running
                if stopFn then
                    stopFn()
                end
                
                -- Start a new timer
                stopFn = time.runRepeatedly(
                    function()
                        -- Pause the game
						print 'No activation  pause is pausing your game'
						core.sendGlobalEvent('Pause')
                        -- Cancel the timer after pausing
                        stopFn()
                    end,
                    5 * time.second, -- Duration until pause
                    { initialDelay = 2 * time.second } -- No initial delay, since we start immediately
                )
            elseif data.newMode == nil and data.oldMode == 'Dialogue' then
                -- If we exit dialogue mode, ensure no timer is running
                if stopFn then
                    stopFn()
                    stopFn = nil
                end
            end
        end,
    }
}