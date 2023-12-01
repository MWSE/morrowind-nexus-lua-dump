local compass = require("sb_compass.interop")

local function initializedCallback(e)
        compass.registerMidSoon { obj = "sb_luce_cat", icon = "Icons\\sb_compass_mods\\sb_luce_cat\\luce.tga", colour = compass.mcm.colours.red }
end
event.register(tes3.event.initialized, initializedCallback)