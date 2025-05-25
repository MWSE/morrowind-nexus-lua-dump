local config = require("Danae.Classes.config")

event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate("Ahead of the Classes")
    template:saveOnClose("Ahead of the Classes", config.mcm)
    template:register()

    local settings = template:createSideBarPage("Settings")

    settings:createYesNoButton({
        label = "Enable Spells",
        description = "Enable or disable starting spells.",
        variable = mwse.mcm.createTableVariable{
            id = "enableSpells",
            table = config.mcm,
        },
    })

    settings:createYesNoButton({
        label = "Enable Gear",
        description = "Enable or disable starting gear.",
        variable = mwse.mcm.createTableVariable{
            id = "enableGear",
            table = config.mcm,
        },
    })
end)