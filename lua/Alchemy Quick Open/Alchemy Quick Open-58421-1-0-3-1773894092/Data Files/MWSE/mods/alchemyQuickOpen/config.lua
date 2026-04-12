local i18n = require("alchemyQuickOpen.i18n")

local defaultKeybind = {
    keyCode = tes3.scanCode.a,
    isShiftDown = false,
    isAltDown = false,
    isControlDown = false,
}

local defaultConfig = {
    keybind = defaultKeybind,
}

local configFilename = "Alchemy Quick Open"

local config = mwse.loadConfig(configFilename, defaultConfig)

local function onModConfigReady()
    local template = mwse.mcm.createTemplate{
        name = i18n("mcm.modName"),
        config = config,
    }
    template:register()
    template:saveOnClose(configFilename, config)

    local page = template:createSideBarPage{label = i18n("mcm.settings")};
    local settings = page:createCategory(i18n("mcm.settings"))

    settings:createKeyBinder{
        label = i18n("mcm.keybind.label"),
        description = i18n("mcm.keybind.desc"),
        allowCombinations = true,
        allowMouse = true,
        configKey = "keybind",
        keybindName = i18n("mcm.keybind.name"),
        defaultSetting = defaultKeybind,
        showDefaultSetting = true,
    }
end

event.register(tes3.event.modConfigReady, onModConfigReady)

return config
