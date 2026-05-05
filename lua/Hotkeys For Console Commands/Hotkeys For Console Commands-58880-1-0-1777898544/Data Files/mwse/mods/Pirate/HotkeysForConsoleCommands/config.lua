local config = {}
config.modVersion = "1.0"
config.configPath = "HotkeysForConsoleCommands"
config.mcmDefault = {
            RAKey = {
                keyCode = tes3.scanCode.F6,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false
                    },
            FixMeKey = {
                keyCode = tes3.scanCode.F7,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false
                    },
        }
config.mcm = mwse.loadConfig(config.configPath, config.mcmDefault)
return config
