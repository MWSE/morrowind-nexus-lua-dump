local common = require("blight.common")

event.register("cellChanged", function(e)
    -- Update exterior global
    if e.cell.isInterior and not e.cell.behavesAsExterior then
        tes3.setGlobal("TB_IsInExternalCell", 0)
        return
    end
    tes3.setGlobal("TB_IsInExternalCell", 1)

    if not common.config.enableBlightstormTransmission then return end

    -- Only proc during blight storm.
    local wc = tes3.worldController.weatherController
    if wc.currentWeather.index ~= tes3.weather.blight then
        return
    end

    common.debug("Player is contracting blight from blightstorm.")
    event.trigger("blight:TriggerBlight", { reference = tes3.player })
end)
