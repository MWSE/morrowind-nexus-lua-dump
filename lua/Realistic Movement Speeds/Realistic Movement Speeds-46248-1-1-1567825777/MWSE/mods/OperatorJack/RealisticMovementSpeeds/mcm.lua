local config = require("OperatorJack.RealisticMovementSpeeds.config")

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Realistic Movement Speeds")
template:saveOnClose("Realistic-Movement-Speeds", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Hover over a setting to learn more about it."
}

local category = page:createCategory{
    label = "General Settings"
}

category:createSlider{
    label = "Backwards Movement Percentage Multiplier",
    description = "Use this option to select the percentage to use in the backwards speed calculation. Default is 60%. Each step represents 1%. Select a lower percentage for slower speeds.",
    min = 1,
    max = 100,
    step = 1,
    jump = 10,
    variable = mwse.mcm.createTableVariable{
        id = "backwardsMovementMultiplier",
        table = config
    }
}

-- Create option to capture debug mode.
category:createSlider{
    label = "Strafing Movement Percentage Multiplier",
    description = "Use this option to select the percentage to use in the strafing speed calculation. Default is 80%. Each step represents 1%. Select a lower percentage for slower speeds.",
    min = 1,
    max = 100,
    step = 1,
    jump = 10,
    variable = mwse.mcm.createTableVariable{
        id = "strafingMovementMultiplier",
        table = config
    }
}

mwse.mcm.register(template)