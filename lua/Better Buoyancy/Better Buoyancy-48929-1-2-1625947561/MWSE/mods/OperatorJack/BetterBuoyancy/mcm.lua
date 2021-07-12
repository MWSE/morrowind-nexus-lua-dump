local config = require("OperatorJack.BetterBuoyancy.config")

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    category:createOnOffButton{
        label = "Enable Underwater Controls",
        description = "Use this option to enable underwater controls. The jump key will cause you to float up, the sneak key will cause you to sink down.",
        variable = mwse.mcm.createTableVariable{
            id = "underwaterControlsEnabled",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Levitation Controls",
        description = "Use this option to enable levitation controls. The jump key will cause you to float up, the sneak key will cause you to sink down.",
        variable = mwse.mcm.createTableVariable{
            id = "levitationControlsEnabled",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Better Buoyancy")
template:saveOnClose("Better-Buoyancy", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Hover over a setting to learn more about it."
}

createGeneralCategory(page)

mwse.mcm.register(template)