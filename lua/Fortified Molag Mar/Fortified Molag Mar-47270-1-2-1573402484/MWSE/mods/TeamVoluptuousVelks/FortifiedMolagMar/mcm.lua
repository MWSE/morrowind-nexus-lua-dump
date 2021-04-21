local config = require("TeamVoluptuousVelks.FortifiedMolagMar.config")


local function createGeneralCategory(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description = "Hover over a setting to learn more about it."
    }

    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Debug Messages",
        description = "If enabled, Morrowind will show all debug messages related to this mod in-game and in the MWSE.log.",
        variable = mwse.mcm.createTableVariable{
            id = "showDebug",
            table = config
        }
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Error Messages",
        description = "If enabled, Morrowind will show all error messages related to this mod in-game and in the MWSE.log.",
        variable = mwse.mcm.createTableVariable{
            id = "showErrors",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Fortified Molag Mar")
template:saveOnClose("Fortified-Molag-Mar", config)

createGeneralCategory(template)

mwse.mcm.register(template)