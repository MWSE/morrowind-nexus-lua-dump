local EasyMCM = require ("easyMCM.EasyMCM")
local config = require("updateAIFaster.config").loaded
local defaultConfig = require("updateAIFaster.config").default

local modName = ("Update AI Faster")
local template = EasyMCM.createTemplate(modName)
template:saveOnClose("updateAIFaster", config)
template:register()

local page = template:createSideBarPage({
    label = "Settings",
    description = "This mod adds a configurable interval at which AI will update. This is meant to avoid enemies that just wait for you to walk up to them. \n\nThe vanilla behavior is for the engine to set their own intervals depending on how many AI entities are loaded. This sets the same interval for all actors when they are loaded.\n\nMade by Robin Hjelte.",
    showReset = true
})

local settings = page:createCategory ("Update AI Faster - Settings")

settings:createSlider{
    label = "AI update interval in seconds",
    description = "This value determines an interval in seconds + 1 second, at which the AI will update and change behaviors for NPCs. The value is set when the NPC or enemy is loaded. Example: A value of 1, means the AI update every 2 seconds. 0.1, means it update ever 1.1 second. Lower values can have a performance impact.",
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