local configPath = "Merchant Inventory Reset"
local cfg = {}  -- Initialize the cfg table
---@class MerchantReset
local defaults = {
    resetTime = 72,
    notifyPlayer = true,
    manualReset = true,
    manualResetKeybind = { keyCode = tes3.scanCode.r, isShiftDown = true, isAltDown = false, isControlDown = false },
    manualNote = true
}

---@class MerchantReset
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        defaultConfig = defaults,
        config = config
    })
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    settings.showReset = true

    settings:createSlider({
        label = "How Many Days for Merchant Inventories to Reset in Hours. Default : 72",
        configKey = "resetTime",
        min = 24, max = 168, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Enable Message Notification on Inventory Reset",
		description = "Default : Yes",
		configKey = "notifyPlayer"
	})

    settings:createYesNoButton({
		label = "Enable Manual Inventory Reset",
		description = "Default : Yes",
		configKey = "manualReset"
	})

    settings:createKeyBinder({
        label = "Manual Reset Keybind",
        description = "Default: Shift + R",
        configKey = "manualResetKeybind",
    })

    settings:createYesNoButton({
		label = "Enable Message Notification on Manual Inventory Reset",
		description = "Default : Yes",
		configKey = "manualNote"
	})

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config