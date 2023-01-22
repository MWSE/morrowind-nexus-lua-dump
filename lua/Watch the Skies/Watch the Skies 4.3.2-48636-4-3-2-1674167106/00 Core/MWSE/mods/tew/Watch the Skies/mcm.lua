local configPath = "Watch the Skies"
local config = require("tew.Watch the Skies.config")
local modversion = require("tew.Watch the Skies.version")
local version = modversion.version

local template = mwse.mcm.createTemplate {
    name = "Watch the Skies",
    headerImagePath = "\\Textures\\tew\\Watch the Skies\\WtS_logo.tga"
}

local page = template:createPage { label = "Main Settings" }
page:createCategory {
    label = "Watch the Skies " .. version .. " by tewlwolow.\nLua-based weather overhaul.\n\nSettings:"
}

local function createYesNoButton(label, id, restartRequired)
    restartRequired = restartRequired or true

    page:createYesNoButton {
        label = label,
        variable = mwse.mcm.createTableVariable {
            id = id,
            table = config
        },
        restartRequired = restartRequired
    }
end

createYesNoButton("Enable debug mode?", "debugLogOn")
createYesNoButton("Enable randomised cloud textures?", "skyTexture")
createYesNoButton("Use vanilla sky textures as well? Note that these need to be in your Data Files/Textures folder, BSA will not work.", "useVanillaSkyTextures")
createYesNoButton("Enable randomised hours between weather changes?", "dynamicWeatherChanges")
createYesNoButton("Enable weather changes in interiors?", "interiorTransitions")
createYesNoButton("Enable seasonal weather?", "seasonalWeather")
createYesNoButton("Enable seasonal daytime hours?", "seasonalDaytime")
createYesNoButton("Randomise max particles?", "particleAmount")
createYesNoButton("Randomise clouds speed?", "cloudSpeed")
createYesNoButton("Randomise rain and snow particle meshes?", "particleMesh")

page:createDropdown {
	label = "Cloud speed mode:",
	options = {
		{ label = "Vanilla", value = 100 },
		{ label = "Skies .iv", value = 500 }
	},
	variable = mwse.mcm.createTableVariable {
        id = "cloudSpeedMode",
        table = config
    },
    restartRequired = true
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)