local configPath = "Happenstance Hodokinesis"
local config = require("tew.Happenstance Hodokinesis.config")
local metadata = toml.loadMetadata("Happenstance Hodokinesis")
local defaults = require("tew.Happenstance Hodokinesis.defaults")

local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\hodokinesis\\hodokinesis-logo.dds" }

local mainPage = template:createPage { label = "Main Settings", noScroll = true }
mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" .. metadata.package.description .."\n\nSettings:"
}

mainPage:createSlider(
    {
        label = string.format("This setting controls the current percentage threshold of player's max health, fatigue, and magicka to be considered a factor. Default = %s%%. Percent chance", defaults.vitalsThreshold),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = registerVariable("vitalsThreshold")
    }
)

mainPage:createYesNoButton {
	label = "Show messages on action trigger?",
	variable = registerVariable("showInfoMessages"),
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
