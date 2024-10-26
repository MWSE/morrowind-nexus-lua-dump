local configPath = "Sneaky Snatcher"
local config = require("tew.Sneaky Snatcher.config")
local defaults = require("tew.Sneaky Snatcher.defaults")
local metadata = toml.loadMetadata("Sneaky Snatcher")

local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config,
    }
end

local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\Sneaky Snatcher\\logo.dds" }

local mainPage = template:createPage { label = "Main Settings", noScroll = true }
mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" .. metadata.package.description .. "\n\nSettings:",
}

mainPage:createYesNoButton {
    label = string.format("Cover only objects player has no ownership for?\nDefault - %s", defaults.useOwnership and "Yes" or "No"),
    variable = registerVariable("useOwnership"),
}

mainPage:createSlider {
    label = string.format("Controls Sneak skill increase (progress percentage) on a successful snatch for containers.\nDefault - %s\nSkill increase for containers", defaults.sneakSkillIncreaseContainer),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("sneakSkillIncreaseContainer"),
}

mainPage:createSlider {
    label = string.format("Controls Sneak skill increase (progress percentage) on a successful snatch for doors.\nDefault - %s\nSkill increase for doors", defaults.sneakSkillIncreaseDoor),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("sneakSkillIncreaseDoor"),
}

mainPage:createSlider {
    label = string.format("Controls Sneak skill increase (progress percentage) on a successful snatch for all other objects.\nDefault - %s\nSkill increase for other objects", defaults.sneakSkillIncreaseObject),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("sneakSkillIncreaseObject"),
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
