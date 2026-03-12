local strings = require("alchemyQuickOpen.strings")

local config = mwse.loadConfig(strings.mcm.modName, {})

local function onModConfigReady()
    local template = mwse.mcm.createTemplate{
        name = strings.mcm.modName,
        config = config,
    }
    template:register()
    template:saveOnClose(strings.mcm.modName, config)

    local page = template:createSideBarPage{label = strings.mcm.settings};
    local settings = page:createCategory(strings.mcm.settings)

    settings:createKeyBinder{
        label = strings.mcm.keybind,
        description = strings.mcm.keybindDesc,
        allowCombinations = true,
        allowMouse = true,
        configKey = "keybind",
        keybindName = strings.mcm.keybindName,
        defaultSetting = {
            keyCode = tes3.scanCode.a,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        showDefaultSetting = true,
    }
end

event.register(tes3.event.modConfigReady, onModConfigReady)

return config
