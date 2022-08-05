local postprocessing = require('openmw.postprocessing')
local self = require('openmw.self')
local core = require("openmw.core")

-- @globals
local shader = postprocessing.load('modern_combat_low_fatigue')

-- @utils:enable shader
shader:enable()

-- @temporary:utils
local greyscale_power = 0
local last_update_time = core.getRealTime()

return {
    engineHandlers = {
        onUpdate = function()
            -- @mechanics:normalize power inside menu
            local real_time = core.getRealTime()
            if core.isWorldPaused() then
                last_update_time = real_time
                greyscale_power = 1
                return;
            end

            -- @mechanics:calculate next greyscale strength
            local seconds_passed_since_update = real_time - last_update_time
            local a_fatigue = self.type.stats.dynamic.fatigue(self)
            local next_power = a_fatigue.current / a_fatigue.base
            if next_power < greyscale_power then
                next_power = greyscale_power - 0.7 * seconds_passed_since_update
            elseif next_power > greyscale_power then
                next_power = greyscale_power + 0.7 * seconds_passed_since_update
            end
            greyscale_power = math.max(0, math.min(next_power, 1))

            -- @mechanics:smooth power updates
            local smoothed_power = math.max(0, math.min(next_power + 0.2, 1))
            smoothed_power = math.sqrt(smoothed_power)
            shader:setFloat('uPower', smoothed_power)

            last_update_time = real_time
        end
    }
}
