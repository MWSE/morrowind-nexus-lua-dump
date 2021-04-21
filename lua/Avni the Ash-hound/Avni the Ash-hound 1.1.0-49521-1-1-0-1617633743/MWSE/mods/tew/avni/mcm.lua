local configPath = "Avni the Ash-hound"
local config = require("tew.avni.config")
mwse.loadConfig("Avni the Ash-hound")
local modversion = require("tew\\avni\\version")
local version = modversion.version

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="Avni the Ash-hound",
    headerImagePath="\\Textures\\tew\\avni\\tew_avni_logo.tga"}

    local page = template:createPage{label="Main Settings", noScroll=true}
    page:createCategory{
        label = "Avni the Ash-hound "..version.." by tewlwolow.\nA Redoran-themed unique nix-hound companion, made for Spring Modjam 2021.\n\nSettings:",
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