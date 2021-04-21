return mwse.loadConfig("PassTheTime") or {
    normalTimescale = 30,
    fastForwardHotkey = {
        keyCode = tes3.scanCode.y,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    fastForwardTimescale = 360,
    turboTimescale = 3600,
    adjustFastTravelTime = false,
    displayMessages = false,
}