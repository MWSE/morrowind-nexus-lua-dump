local config = require("ImmersiveWait.config")
local this = {}

this.adjustTravelTimeIfConfigured = function()
    -- Change the travel time multiplier if enabled in the config, revert to original value if not.
    -- This allows us to just toggle this from the MCM.
    if config.adjustTravelTime then
        local effectiveTimescale = tes3.findGlobal("Timescale").value

        -- Let's not divide by zero.
        if math.abs(effectiveTimescale) < 0.1 then
            effectiveTimescale = 0.1
        end

        -- Travel time is (distance / fTravelTimeMult), so the higher this GMST, the less time elapses.
        -- This formula changes the GMST to make travel time proportional to timescale.
        -- (30 and 16000 are vanilla values for timescale and fTravelTimeMult, respectively.)
        tes3.findGMST("fTravelTimeMult").value = 16000 / ( effectiveTimescale / 30 )
    else
        -- Revert to default value.
        tes3.findGMST("fTravelTimeMult").value = 16000
    end
end

this.changeTimescale = function(newTimescale, debugMessages)

    -- Actually change the timescale.
    tes3.findGlobal("Timescale").value = newTimescale

    -- Possibly show the new timescale depending on mod settings and where this function is called from.
    if debugMessages then
        tes3.messageBox("Timescale is now %.0f.", tes3.findGlobal("Timescale").value)
    end
end

return this
