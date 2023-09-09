local metadata = toml.loadMetadata("Avni the Ash-hound")
local configPath = metadata.package.name
local config = require("tew.avni.config")
mwse.loadConfig(metadata.package.name)


local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\avni\\tew_avni_logo.tga"}

    local page = template:createPage{label="Main Settings", noScroll=true}
    page:createCategory{
        label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" .. metadata.package.description .. "\n\nSettings:",
    }

    page:createYesNoButton{
        label = "Enable debug mode?",
        variable = registerVariable("debugLogOn"),
        restartRequired=true
    }

    page:createYesNoButton{
        label = "Enable springtime UI colors?",
        variable = registerVariable("useColors"),
    }

    page:createKeyBinder{
        label = "This key will bring up a teleport menu to summon Avni if you'd lost her.\nDefault = O.",
        allowCombinations = false,
        variable = registerVariable("summonKey"),
    }



template:saveOnClose(configPath, config)
mwse.mcm.register(template)