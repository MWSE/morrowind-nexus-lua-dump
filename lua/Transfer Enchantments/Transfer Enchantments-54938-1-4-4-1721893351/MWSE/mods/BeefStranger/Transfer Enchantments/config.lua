local configPath = "Transfer Enchantment"

---@class bsTransferEnchant<K, V>: { [K]: V }
local defaults = {
    enabled = true,
    giveXP = true,
    keepOg = false,
    combine = true,
    combineMult = 1.5,
    combineMags = false,
    allowScript = false,
    autoExit = true,

    keycode = { --Keycode to trigger menu
        keyCode = tes3.scanCode.y,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
}


---@class bsTransferEnchant
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath, defaultConfig = defaults, config = config })
        template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    settings:createYesNoButton({
        label = "Enable Mod",
        configKey = "enabled"
    })

    settings:createYesNoButton({
        label = "Gain Experience for Enchantment Transfer",
        configKey = "giveXP"
    })

    settings:createYesNoButton({
        label = "Keep Original Item",
        configKey = "keepOg"
    })

    settings:createYesNoButton({
        label = "Enable Enchantment Combination",
        configKey = "combine"
    })

    settings:createYesNoButton({
        label = "Combine Magnitudes",
        configKey = "combineMags",
    })

    settings:createSlider({
        label = "Combination Cost Multiplier",
        configKey = "combineMult",
        min = 0, max = 5, step = 0.01, jump = 0.10, decimalPlaces = 2,
    })

    settings:createYesNoButton({
        label = "Allow Scripted Items",
        configKey = "allowScript"
    })

    settings:createYesNoButton({
        label = "Auto Exit Menu After Enchanting",
        configKey = "autoExit"
    })


    settings:createKeyBinder({
        label = "Key To Open Transfer Menu",
        configKey = "keycode",
        allowCombinations = false,
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config