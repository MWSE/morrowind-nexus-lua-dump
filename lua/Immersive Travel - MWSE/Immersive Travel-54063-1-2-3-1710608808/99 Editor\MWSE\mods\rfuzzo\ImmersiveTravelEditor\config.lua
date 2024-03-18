local defaultConfig = {
    mod = "Immersive Travel Editor",
    id = "IT",
    version = 1.0,
    author = "rfuzzo",
    -- configs
    logLevel = "INFO",
    grain = 20,
    tracemax = 6,
    traceOnSave = true,
    -- keybinds
    placekeybind = {keyCode = tes3.scanCode["keyRight"]},
    openkeybind = {keyCode = tes3.scanCode["rCtrl"]},
    editkeybind = {keyCode = tes3.scanCode["lCtrl"]},
    deletekeybind = {keyCode = tes3.scanCode["delete"]},
    tracekeybind = {keyCode = tes3.scanCode["forwardSlash"]}
}

return mwse.loadConfig("ImmersiveTravelEditor", defaultConfig)
