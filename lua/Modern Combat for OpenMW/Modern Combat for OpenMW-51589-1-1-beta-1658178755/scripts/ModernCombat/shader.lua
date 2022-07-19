local postprocessing = require('openmw.postprocessing')
local self = require('openmw.self')
local core = require("openmw.core")

local shader = postprocessing.load('modern_combat_low_fatigue')

shader:enable()

local prev_power = 0

local last_update_time = core.getRealTime()
return {
    engineHandlers = {
        onUpdate = function()
            local real_time = core.getRealTime()

            if core.isWorldPaused() then
                last_update_time = real_time
                prev_power = 1
                return;
            end

            local seconds_passed_since_update = real_time - last_update_time

            local fatigue = self.type.stats.dynamic.fatigue(self)
            local next_power = fatigue.current / fatigue.base
            if next_power < prev_power then
                next_power = prev_power - 0.7 * seconds_passed_since_update
            elseif next_power > prev_power then
                next_power = prev_power + 0.7 * seconds_passed_since_update
            end
            prev_power = math.max(0, math.min(next_power, 1))

            local power = math.max(0, math.min(next_power + 0.2, 1))
            power = math.sqrt(power)
            shader:setFloat('uPower', power)

            last_update_time = real_time
        end
    }
}
