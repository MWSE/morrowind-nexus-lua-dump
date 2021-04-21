return mwse.loadConfig("ImmersiveWait") or {
    waitHotkey = {
        keyCode = tes3.scanCode.t,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    normalTimescale = 30,
    waitTimescale = 600,
    safeDistance = 4000,
    adjustTravelTime = false,
    debugMessages = false,
}
