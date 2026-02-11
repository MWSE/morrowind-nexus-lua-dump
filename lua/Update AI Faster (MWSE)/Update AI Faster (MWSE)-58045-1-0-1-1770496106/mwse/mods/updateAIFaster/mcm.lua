local EasyMCM = require ("easyMCM.EasyMCM")
local config = require("updateAIFaster.config").loaded
local defaultConfig = require("updateAIFaster.config").default

local modName = ("Update AI Faster")
local template = EasyMCM.createTemplate(modName)
template:saveOnClose("updateAIFaster", config)
template:register()

local page = template:createSideBarPage({
    label = "Settings",
    description = "This mod adds a configurable interval at which AI will update. This is meant to avoid enemies that just wait for you to walk up to them",
    showReset = true
})

local settings = page:createCategory ("Update AI Faster - Settings")

settings:createSlider{
    label = "AI update interval in seconds",
    description = "This value determines an interval in seconds at which the AI will update and change behaviors for NPCs. The value is set when the NPC or enemy is loaded.",
    max = 5,
    min = 0.1,
    step = 0.1,
    decimalPlaces = 1,
    defaultSetting = defaultConfig.aiUpdateTime,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "aiUpdateTime",
        table = config
    }
}