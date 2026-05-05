---@diagnostic disable: undefined-global

local config = require("weapons_sheath_when_equip_change.config")

local function registerModConfig()
    local currentConfig = config.get()

    local template = mwse.mcm.createTemplate({
        name = "Weapons Sheath When Equip Change",
        config = currentConfig,
        defaultConfig = config.getDefaults(),
    })

    template:saveOnClose("weapons_sheath_when_equip_change\\config", currentConfig)

    local page = template:createPage({ label = "General" })

    page:createInfo({
        text = table.concat({
            "Forces a visual transition when changing the equipped weapon.",
            "Normal swaps are blocked and replayed as sheathe + draw.",
            "The mod no longer adds an extra post-sheathe delay or a scripted fallback path.",
        }, "\n\n"),
    })

    local featureCategory = page:createCategory({ label = "Behavior" })

    featureCategory:createOnOffButton({
        label = "Enable mod",
        description = "Turns the swap queue with animation on or off.",
        variable = mwse.mcm.createTableVariable({
            id = "enabled",
            table = currentConfig.featureFlags,
        }),
    })

    featureCategory:createOnOffButton({
        label = "Detailed logging",
        description = "Keeps the mod's detailed diagnostics in MWSE.log.",
        variable = mwse.mcm.createTableVariable({
            id = "debugLogging",
            table = currentConfig.featureFlags,
        }),
    })

    template:register()
end

event.register("modConfigReady", registerModConfig)