return {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Hostility Indicator",
	rusName = "Индикатор враждебности",
    --Description for the MCM sidebar
    modDescription =
[[
Этот мод позволяет определять враждебность удаленных NPC и существ, удерживая горячую клавишу.
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