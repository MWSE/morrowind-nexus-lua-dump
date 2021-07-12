local config = require("OperatorJack.MiscastEnhanced.config")


local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Miscast Messages",
        description = "Use this option to enable Miscast messages. This includes being notified when some effects start and finish.",
        variable = mwse.mcm.createTableVariable{
            id = "showMessages",
            table = config
        }
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Debug Mode",
        description = "Use this option to enable debug mode. This will make miscast occur 100% of the time.",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Miscast Enhanced")
template:saveOnClose("Miscast-Enhanced", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Hover over a setting to learn more about it."
}

createGeneralCategory(page)

mwse.mcm.register(template)