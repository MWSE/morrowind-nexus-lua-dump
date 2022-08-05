local configPath = "Watch the Skies"
local config = require("tew.Watch the Skies.config")
local modversion = require("tew\\Watch the Skies\\version")
local version = modversion.version

local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate {
    name = "Watch the Skies",
    headerImagePath = "\\Textures\\tew\\Watch the Skies\\WtS_logo.tga" }

local page = template:createPage { label = "Main Settings" }
page:createCategory {
    label = "Watch the Skies " .. version .. " by tewlwolow.\nLua-based weather overhaul.\n\nSettings:",
}
page:createYesNoButton {
    label = "Enable debug mode?",
    variable = registerVariable("debugLogOn"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Enable randomised cloud textures?",
    variable = registerVariable("alterClouds"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Enable randomised hours between weather changes?",
    variable = registerVariable("alterChanges"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Enable weather changes in interiors?",
    variable = registerVariable("interiorTransitions"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Enable seasonal weather?",
    variable = registerVariable("seasonalWeather"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Enable seasonal daytime hours?",
    variable = registerVariable("daytime"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Randomise max particles?",
    variable = registerVariable("randomiseParticles"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Randomise clouds speed?",
    variable = registerVariable("randomiseCloudsSpeed"),
    restartRequired = true
}
page:createYesNoButton {
    label = "Randomise rain and snow particle meshes?",
    variable = registerVariable("randomiseParticleMeshes"),
    restartRequired = true
}
page:createSlider {
    label = "Changes % chance for a vanilla cloud texture to show up instead.\nDefault - 0%.\nChance %",
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("vanChance")
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
