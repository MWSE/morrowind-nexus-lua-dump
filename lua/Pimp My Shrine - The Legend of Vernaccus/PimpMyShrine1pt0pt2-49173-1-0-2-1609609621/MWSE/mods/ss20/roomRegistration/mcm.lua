local common = require('ss20.roomRegistration.common')
local config = common.config
local modName = config.modName
local mcmConfig = common.mcmConfig
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(modName, mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = config.modDescription

    settings:createKeyBinder{
        label = "Assign Keybind for Room Registration Hotkey",
        description = "hotkey that activates the Room Registration Menu",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "menuKey",
            table = mcmConfig,
        }
    }

end
event.register("modConfigReady", registerModConfig)