local config = require("OperatorJack.GalerionsTools.config")

local function createGeneralCategory(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description = "Hover over a setting to learn more about it."
    }

    local category = page:createCategory{
        label = "General Settings"
    }

    category:createSlider{
        label = "Soul Extraction Base Chance",
        description = "Use this option to set a base chance when using the soul extractor. The base chance will be added to the normal chance calculation result. So a value of 10 on this setting will give all items a chance of at least 10, plus whatever the normal formula returns. This value added to the chance caluclation after the chance calculation result is increased from any negative number to 0, but before the chance calculation result is decreased from any positive number over 100 to 100.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "baseChance",
            table = config
        }
    }

    category:createSlider{
        label = "Soul Extraction Chance Percentage Modifier",
        description = "Use this option to increase or decrease the difficulty of using the soul extractor. The modifier is applied directly against the chance calculation result as a percentage. So a value of 100 on this setting will multiply the result by 100%, or 1, keeping the default caluclation value. A value of 125 on this setting will multiply the result by 125%, or 1.25. If the chance calculation result is less than 0, the chance caluclation will be increased to 0 and this setting will have no affect.",
        min = 0,
        max = 500,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "chanceModifierPercent",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Galerion's Tools")
template:saveOnClose("Galerions-Tools", config)

createGeneralCategory(template)

mwse.mcm.register(template)