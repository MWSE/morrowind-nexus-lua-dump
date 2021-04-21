local config = require("PassTheTime.config")
local this = {}

this.changeFastTravelTime = function(adjustTravelTime)
    if adjustTravelTime then
        local effectiveTimescale = tes3.findGlobal("Timescale").value

        -- Let's not divide by zero.
        if effectiveTimescale == 0 then
            effectiveTimescale = 0.1
        end

        -- Fast travel time is (distance / fTravelTimeMult), so the higher this GMST, the less time elapses.
        -- This formula changes the GMST to make travel time proportional to timescale.
        -- (30 and 16000 are vanilla values for timescale and fTravelTimeMult, respectively.)
        tes3.findGMST("fTravelTimeMult").value = 16000 / ( effectiveTimescale / 30 )
    end
end

this.changeTimescale = function(newTimescale, adjustTravelTime, displayMessages)

    -- Actually change the timescale.
    tes3.findGlobal("Timescale").value = newTimescale

    -- Possibly change the fast travel GMST depending on mod settings.
    this.changeFastTravelTime(adjustTravelTime)

    -- Possibly show the new timescale depending on mod settings and where this function is called from.
    if displayMessages then
        tes3.messageBox("Timescale is now %.0f.", tes3.findGlobal("Timescale").value)
    end
end

return this