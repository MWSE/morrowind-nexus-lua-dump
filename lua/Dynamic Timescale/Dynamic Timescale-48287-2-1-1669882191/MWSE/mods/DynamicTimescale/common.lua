local config = require("DynamicTimescale.config")
local this = {}

this.changeFastTravelTime = function(timescale)
    if config.adjustFastTravelTime then
        timescale = tonumber(timescale)

        -- Let's not divide by zero.
        if timescale == 0 then
            timescale = 0.1
        end

        -- Fast travel time is (distance / fTravelTimeMult), so the higher this GMST, the less time elapses.
        -- This formula changes the GMST to make travel time proportional to wilderness timescale.
        -- (30 and 16000 are vanilla values for timescale and fTravelTimeMult, respectively.)
        tes3.findGMST(tes3.gmst.fTravelTimeMult).value = 16000 / ( timescale / 30 )
    end
end

return this