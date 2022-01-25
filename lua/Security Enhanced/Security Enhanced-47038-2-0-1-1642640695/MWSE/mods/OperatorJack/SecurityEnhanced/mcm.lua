local options = require("OperatorJack.SecurityEnhanced.options")
local config = require("OperatorJack.SecurityEnhanced.config")

local function createLockpickCategory(page)
    local category = page:createCategory{
        label = "Lockpick Settings"
    }

    -- Create option to capture hotkey.
    category:createKeyBinder{
        label = "Assign Keybind for Lockpick Hotkey",
        description = "Use this option to set the hotkey for equipping a lockpick. Click on the option and follow the prompt.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "hotKey",
            table = config.lockpick,
            defaultSetting = {
                keyCode = tes3.scanCode.l,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false,
            },
            restartRequired = true
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Lockpick Hotkey Cycle Action",
        description = "Use this option to set the cycle action that occurs when repeatedly pressing the hotkey." ..
         " 'Go To Next Lockpick' will cycle to the next lockpick type in your inventory." ..
         " 'Re-equip Weapon' will cycle back to the weapon you had equipped when you pressed the hotkey, if available.",
        options = {
            { label = "Go to Next Lockpick", value = options.equipHotKeyCycle.Next },
            { label = "Re-equip Weapon", value = options.equipHotKeyCycle.ReequipWeapon}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipHotKeyCycle",
            table = config.lockpick
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Lockpick Equip Order",
        description = "Use this option to set the equip order when equipping a lockpick through the hotkey or auto-equip mechanisms." ..
        " 'Best Lockpick First' will equip the highest level lockpick you have available first." ..
        " 'Worst Lockpick First' will equip the lowest level lockpick you have available first." ..
        " If you have 'Go To Next Lockpick' selected under 'Lockpick Hotkey Cycle Action', you will cycle in this order as well.",
        options = {
            { label = "Best Lockpick First", value = options.equipOrder.BestFirst },
            { label = "Worst Lockpick First", value = options.equipOrder.WorstFirst}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipOrder",
            table = config.lockpick
        }
    }

    -- Create option to capture auto-equip on activation.
    category:createOnOffButton{
        label = "Enable Lockpick Auto-Equip On Locked Object Activation",
        description = "Use this option to enable auto-equip functionality. If enabled, a lockpick will automatically " ..
        "be equipped based on your other configuration options, as if you had pressed the hotkey, when you activate a " ..
        "locked object.",
        variable = mwse.mcm.createTableVariable{
            id = "autoEquipOnActivate",
            table = config.lockpick,
            restartRequired = true
        }
    }

    return category
end

local function createProbeCategory(page)
    local category = page:createCategory{
        label = "Probe Settings"
    }

    -- Create option to capture hotkey.
    category:createKeyBinder{
        label = "Assign Keybind for Probe Hotkey",
        description = "Use this option to set the hotkey for equipping a Probe. Click on the option and follow the prompt.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "hotKey",
            table = config.probe,
            defaultSetting = {
                keyCode = tes3.scanCode.p,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false,
            },
            restartRequired = true
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Probe Hotkey Cycle Action",
        description = "Use this option to set the cycle action that occurs when repeatedly pressing the hotkey." ..
         " 'Go To Next Probe' will cycle to the next Probe type in your inventory." ..
         " 'Re-equip Weapon' will cycle back to the weapon you had equipped when you pressed the hotkey, if available.",
        options = {
            { label = "Go to Next Probe", value = options.equipHotKeyCycle.Next },
            { label = "Re-equip Weapon", value = options.equipHotKeyCycle.ReequipWeapon}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipHotKeyCycle",
            table = config.probe
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Probe Equip Order",
        description = "Use this option to set the equip order when equipping a Probe through the hotkey or auto-equip mechanisms." ..
        " 'Best Probe First' will equip the highest level Probe you have available first." ..
        " 'Worst Probe First' will equip the lowest level Probe you have available first." ..
        " If you have 'Go To Next Probe' selected under 'Probe Hotkey Cycle Action', you will cycle in this order as well.",
        options = {
            { label = "Best Probe First", value = options.equipOrder.BestFirst },
            { label = "Worst Probe First", value = options.equipOrder.WorstFirst}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipOrder",
            table = config.probe
        }
    }

    -- Create option to capture auto-equip on activation.
    category:createOnOffButton{
        label = "Enable Probe Auto-Equip On Trapped Object Activation",
        description = "Use this option to enable auto-equip functionality. If enabled, a Probe will automatically " ..
        "be equipped based on your other configuration options, as if you had pressed the hotkey, when you activate a " ..
        "trapped object.",
        variable = mwse.mcm.createTableVariable{
            id = "autoEquipOnActivate",
            table = config.probe,
            restartRequired = true
        }
    }

    return category
end

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Debug Mode",
        description = "Use this option to enable debug mode.",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Security Enhanced")
template:saveOnClose("Security-Enhanced-2", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Hover over a setting to learn more about it."
}

createGeneralCategory(page)
createLockpickCategory(page)
createProbeCategory(page)

mwse.mcm.register(template)