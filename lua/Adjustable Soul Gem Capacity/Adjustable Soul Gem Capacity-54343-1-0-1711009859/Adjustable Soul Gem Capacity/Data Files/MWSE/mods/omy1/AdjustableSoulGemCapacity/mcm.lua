-- Load the required modules
local EasyMCM = require("EasyMCM.EasyMCM")
local config = require("omy1.AdjustableSoulGemCapacity.config")

-- Create the MCM
local template = EasyMCM.createTemplate("AdjustableSoulGemCapacity")
template:saveOnClose("AdjustableSoulGemCapacity", config)
template:register()

local page = template:createSideBarPage({
    label = "Settings",
})

local settings = page:createCategory("Settings")

settings:createOnOffButton({
    label = "Mod Enabled",
    description = "Current Status of the mod. Restart the game after changing this option.",
    variable = EasyMCM.createTableVariable {
        id = "modEnabled",
        table = config
    }
})

-- Soul Gem Capacity
    settings:createSlider({
        label = "Soul Gem Capacity Multiplier",
        description = "This setting adjusts the Soul Gem capacity multiplier. You are gonna need to restart the game after you change this for it to take effect.",
        min = 0,
        max = 100000,
        step = 1,
        jump = 100,
        variable = EasyMCM:createTableVariable{
            id = "fSoulGemMult",
            table = config
        }
    })