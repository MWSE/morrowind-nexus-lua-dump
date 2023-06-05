local compass = require("sb_compass.interop")
if not compass then return end

local companions = { "sb_remiros", "remi.tga" }

local function initializedCallback(e)
    compass.registerMidSoon { obj = companion[1], icon = "Icons\\sb_remiros\\" .. companion[2], colour = compass.mcm.colours.indigo }
end
event.register(tes3.event.initialized, initializedCallback)