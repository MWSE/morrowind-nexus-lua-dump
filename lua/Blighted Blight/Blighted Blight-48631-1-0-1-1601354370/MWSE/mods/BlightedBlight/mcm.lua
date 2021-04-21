local mod = "Blighted Blight"
local version = "1.0.1"

local config = require("BlightedBlight.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod implements the possibility of contracting blight diseases when out in a blight storm.",
    }

    page:createSlider{
        label = "Blight chance",
        description =
            "With this mod, each time you change cells, and the weather in the new cell is a blight storm, there is a chance that you will contract a blight disease.\n" ..
            "\n" ..
            "This setting is the base chance, as a percentage, of contracting a blight disease each time you cellchange into a blight storm. This applies both when transitioning from an interior to an exterior and when traveling from one exterior cell to another.\n" ..
            "\n" ..
            "This chance will be modified by any magnitude of Resist Blight Disease (or Weakness to Blight Disease) that you're affected by.\n" ..
            "\n" ..
            "Default: 10",
        variable = mwse.mcm.createTableVariable{
            id = "blightChance",
            table = config,
        },
        max = 100,
        defaultSetting = 10,
    }

    return page
end

local template = mwse.mcm.createTemplate("Blighted Blight")
template:saveOnClose("BlightedBlight", config)

createPage(template)

mwse.mcm.register(template)