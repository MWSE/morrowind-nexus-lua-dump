--Data Files/MWSE/mods/CAPS/main.lua
local ashfall = include("mer.ashfall.interop")
if ashfall then

    --Object Registration

    ashfall.registerActivators{
        RPNR_bucket_water = "waterClean",
        RPNR_water_cirle512_c = "waterClean",
    }

end