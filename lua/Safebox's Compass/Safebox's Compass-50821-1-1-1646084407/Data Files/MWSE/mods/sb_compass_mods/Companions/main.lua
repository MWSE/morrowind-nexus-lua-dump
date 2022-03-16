local compass = require("sb_compass.interop")

local companions = {
    { "tew_avni", "avni.tga" },
    { "md_corgi_dinky", "dinky.tga" },
    { "AA1_Kolka", "kolka.tga" },
    { "AA1_Paxon", "paxon.tga" },
    { "1A_comp_PrixiCR", "prixi.tga" },
    { "sb_tel_shadow", "tel-shadow.tga" },
    { "AA1_Tetra", "tetra.tga" },
    { "TDM_VA_Companion", "vaba-amus.tga" },
    { "TDM_VA_Racer", "vaba-amus.tga" },
    { "TDM_VA_VabaAmusTalker", "vaba-amus.tga" }
}

local function initializedCallback(e)
    for _, companion in ipairs(companions) do
        compass.registerMidSoon { obj = companion[1], icon = "Icons\\sb_compass_mods\\Companions\\" .. companion[2], colour = compass.mcm.colours.green }
    end
end
event.register(tes3.event.initialized, initializedCallback)