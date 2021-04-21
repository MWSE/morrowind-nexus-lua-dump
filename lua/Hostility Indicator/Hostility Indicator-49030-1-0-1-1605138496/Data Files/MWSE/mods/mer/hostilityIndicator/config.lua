return {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Hostility Indicator",
    --Description for the MCM sidebar
    modDescription =
[[
This mod allows you to determine the hostility of distant NPCs and Creatures by holding down a hotkey.
]],
    mcmDefaultValues = {
        enabled = true, 
        debug = false,
        hotkey = {
            keyCode = tes3.scanCode.lShift
        },
        maxTargetDistance = 3000
    },
}