local configPath = "Show Septims"
local cfg = {}
local defaults = {
	currencyPreference = "Gold"
}

local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        defaultConfig = defaults,
        config = config
    })
    template:saveOnClose(configPath, config)

    local settings = template:createSideBarPage({ label = "Settings" })
    settings.showReset = true

    settings:createDropdown({
        label = "Currency Display Name",
        description = "Choose how currency is labeled in the UI.",
        options = {
            { label = "Gold", value = "Gold" },
            { label = "Septims", value = "Septims" },
            { label = "Drakes", value = "Drakes" },
            { label = "None", value = "None" },
        },
        config = config,
        configKey = "currencyPreference",
        defaultSetting = defaults.currencyPreference
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config