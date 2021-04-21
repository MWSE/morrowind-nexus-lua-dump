local config = require("OperatorJack.SpeedBoost.config")

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createSlider{
        label = "Speed Modifier Percentage",
        description = ("The percent modifier applied to all movement speeds for all actors."),
        min = 0,
        max = 1000,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "modifier",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Speed Boost")
template:saveOnClose("Speed-Boost", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Hover over a setting to learn more about it."
}

createGeneralCategory(page)

mwse.mcm.register(template)