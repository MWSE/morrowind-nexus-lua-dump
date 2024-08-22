local configPath = "Persuasion Hotkeys"
---@class bsPersuasionHotkey<K, V>: { [K]: V }
local defaults = {
    persuade = { --Keycode to trigger menu
        keyCode = tes3.scanCode.p,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    admire = { --Keycode to trigger menu
        keyCode = tes3.scanCode.a,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    intimidate = { --Keycode to trigger menu
        keyCode = tes3.scanCode.i,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    taunt = { --Keycode to trigger menu
        keyCode = tes3.scanCode.t,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
}


---@class bsPersuasionHotkey
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath, defaultConfig = defaults, config = config })
        template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    settings.showReset = true

    settings:createKeyBinder({
        label = "Persuasion",
        configKey = "persuade",
        allowCombinations = false,
    })

    settings:createKeyBinder({
        label = "Admire",
        configKey = "admire",
        allowCombinations = false,
    })

    settings:createKeyBinder({
        label = "Intimidate",
        configKey = "intimidate",
        allowCombinations = false,
    })

    settings:createKeyBinder({
        label = "Taunt",
        configKey = "taunt",
        allowCombinations = false,
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config