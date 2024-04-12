local EasyMCM = require("EasyMCM.EasyMCM")
local config = require("omy1.AdjustableSoulSizeMultiplier.config")
local template = EasyMCM.createTemplate("AdjustableSoulSizeMultiplier")
template:saveOnClose("AdjustableSoulSizeMultiplier", config)
template:register()

local page = template:createSideBarPage({
    label = "Settings",
})

local settings = page:createCategory("Settings")

settings:createOnOffButton({
    label = "Mod Enabled",
    description = "Toggle the mod on or off. Restart the game after changing this option.",
    variable = EasyMCM.createTableVariable {
        id = "modEnabled",
        table = config
    }
})

settings:createSlider({
    label = "Soul Size Multiplier",
    description = "Adjust the multiplier for the soul size of creatures.",
    min = 0.1,
    max = 100000,
    step = 0.1,
    jump = 1,
    variable = EasyMCM.createTableVariable{
        id = "soulSizeMultiplier",
        table = config
    }
})

-- Add any additional settings you want to include in the MCM here.

return template