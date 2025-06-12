local config = require("TamrielRebuilt.config")

----------------------
-- MCM Template --
----------------------

local function registerModConfig()

    local template = mwse.mcm.createTemplate{name="Tamriel Rebuilt"}
    template:saveOnClose("TamrielRebuilt", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{label="Preferences"}

    -- Feature Toggles
    local toggles = preferences:createCategory{label = "Settings"}
    toggles:createOnOffButton{
        label = "Firemoth Compatibility Warning",
        description = "Provides a warning upon starting the game with Tamriel Rebuilt and an incompatible Firemoth plugin without also having a patch that is recognized by this MWSE Addon.",
        variable = mwse.mcm.createTableVariable{
            id = "firemothWarning",
            table = config,
        },
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)