local common = require('mer.chargenScenarios.common')
local config = require('mer.chargenScenarios.config')
local modName = "Chargen Scenario Builder"
local mcmConfig = common.config.mcm
--MCM MENU
local this = {}

local function createSettingsPage(template)
    local settings = template:createSideBarPage("Settings")
    template:saveOnClose("Chargen Scenarios", mcmConfig)
    settings.description = config.modDescription

    --Locations
    local registerLocationsCategory = settings:createCategory("Register Locations Utility")
    registerLocationsCategory:createOnOffButton{
        label = string.format("Enable"),
        description = "Turn the Register Locations Utility on or off. When enabled, you can press a hotkey to register your current location as a starting position for a scenario. You will be prompted to give the location a unique name, and it will be saved to  Morrowind/Data Files/MWSE/config/Chargen Scenario Utilities.json.",
        variable = mwse.mcm.createTableVariable{id = "registerLocationsEnabled", table = mcmConfig}
    }
    registerLocationsCategory:createKeyBinder{
        label = "Hot Key",
        description = "Press this key to register your current location as a scenario starting position.",
        variable = mwse.mcm.createTableVariable{ id = "registerLocationsHotKey", table = mcmConfig},
        allowCombinations = true,
    }

    --Clutter
    local registerClutterCategory = settings:createCategory("Register Clutter Utility")
    registerClutterCategory:createOnOffButton{
        label = string.format("Enable"),
        description = "Turn the Register Clutter Utility on or off. When enabled, you can press a hotkey to register your current location as a starting position for a scenario. You will be prompted to give the location a unique name, and it will be saved to  Morrowind/Data Files/MWSE/config/Chargen Scenario Utilities.json.",
        variable = mwse.mcm.createTableVariable{id = "registerClutterEnabled", table = mcmConfig}
    }
    registerClutterCategory:createKeyBinder{
        label = "Hot Key",
        description = "Press this key to register your current location as a scenario starting position.",
        variable = mwse.mcm.createTableVariable{ id = "registerClutterHotKey", table = mcmConfig},
        allowCombinations = true,
    }
end

local function createDevOptionsPage(template)
    local devOptions = template:createSideBarPage("Development Options")
    devOptions.description = "Tools for debugging etc."

    --Testing
    devOptions:createOnOffButton{
        label = "Enable Unit Tests",
        description = "Turn the Unit Tests on or off.",
        variable = mwse.mcm.createTableVariable{id = "doTests", table = mcmConfig}
    }
end

this.registerModConfig = function()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(modName, mcmConfig)
    template:register()
    createSettingsPage(template)
    createDevOptionsPage(template)
end

return this