local options = require("OperatorJack.SecurityEnhanced.options")

-- Load configuration.
return mwse.loadConfig("Security-Enhanced") or {
    -- Initialize lockpick settings.
    lockpickEquipHotKey = {
        keyCode = tes3.scanCode.l,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    lockpickEquipHotKeyCycle = options.lockpick.equipHotKeyCycle.ReequipWeapon,
    lockpickEquipOrder = options.lockpick.equipOrder.BestLockpickFirst,
    lockpickAutoEquipOnActivate = true,

    -- Initialize probe settings.
    probeEquipHotKey = {
        keyCode = tes3.scanCode.p,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    probeEquipHotKeyCycle = options.probe.equipHotKeyCycle.ReequipWeapon,
    probeEquipOrder = options.probe.equipOrder.BestProbeFirst,
    probeAutoEquipOnActivate = true,

    -- Initialize other settings.
    debugMode = false
}