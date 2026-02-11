
---@class ChargenScenariosScenario.Config
local config = {
    modName = "Chargen Scenarios",
    modDescription = [[
        Overhauls the character generation.
    ]],
    defaultLocation = {
        position = {61, 135, 24},
        orientation = {0, 0, 340},
        cell = "Imperial Prison Ship"
    },
    chargenLocation = {
        position = {61, 135, 1000},
        orientation = {0, 0, 340},
        cell = "Imperial Prison Ship"
    },

}

config.metadata = toml.loadMetadata("Chargen Scenarios") --[[@as MWSE.Metadata]]

---@class ChargenScenariosMcmConfig
local mcmDefault = {
    enabled = true,
    itemPackageLimit = 3,
    logLevel = "INFO",
    startingLocation = config.defaultLocation,
    startingLocations = {
        vanilla = config.defaultLocation,
    },
    registerLocationsEnabled = false,
    registerLocationsHotKey = {
        keyCode = tes3.scanCode.numpadEnter,
        isShiftDown = true
    },
    registerClutterEnabled = false,
    registerClutterHotKey = {
        keyCode = tes3.scanCode.e,
        isAltDown = true
    },
    --Testing
    doTests = false,
    exitAfterUnitTests = false,
    exitAfterIntegrationTests = false,

    --- The list of registered clutter groups
    registeredClutterGroups = {},
    chargenScenariosMenu_extrasMenu = false,
}


---@type ChargenScenariosMcmConfig
config.mcm = mwse.loadConfig(config.metadata.package.name, mcmDefault)

config.save = function()
    mwse.saveConfig(config.metadata.package.name, config.mcm)
end

return config