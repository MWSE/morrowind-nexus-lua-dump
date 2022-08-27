-- this is for registering new water containers added by this mod
local interop = require("mer.ashfall.interop")
interop.registerWaterContainers({
    jsmk_Misc_Com_Bottle = {
        capacity = 90,
        weight = 3,
        value = 4,
        holdsStew = false
    },
    includeOverrides = true -- i don't actually know what this does
})
