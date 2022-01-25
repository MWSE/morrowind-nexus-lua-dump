local options = require("OperatorJack.SecurityEnhanced.options")

-- Load configuration.
return mwse.loadConfig("Security-Enhanced-2") or {
    -- Initialize lockpick settings.
    lockpick = {
        hotKey = {
            keyCode = tes3.scanCode.l,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        equipHotKeyCycle = options.equipHotKeyCycle.ReequipWeapon,
        equipOrder = options.equipOrder.BestFirst,
        autoEquipOnActivate = true,
    },
    probe = {
        hotKey = {
            keyCode = tes3.scanCode.p,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        equipHotKeyCycle = options.equipHotKeyCycle.ReequipWeapon,
        equipOrder = options.equipOrder.BestFirst,
        autoEquipOnActivate = true,
    },

    -- Initialize other settings.
    debugMode = false
}