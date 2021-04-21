local configPath = "Glass Domes"
local config = require("tew.Glass Domes.config")
mwse.loadConfig("Glass Domes")
local version="1.2.8"

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="Glass Domes",
    headerImagePath="\\Textures\\tew\\Glass Domes\\Moonrain_logo.tga"}

    local page = template:createPage{label="Main Page", noScroll=true}

    page:createCategory{
        label = "Glass Domes of Vivec, Moonrain Edition v"..version.." by Sade1212, qwertyquit, Leyawynn, RandomPal and tewlwolow.\n\nThis is a configuration page for lua script controlling dome weather."
    }

    page:createYesNoButton{
        label = "Enable debug mode?",
        variable = registerVariable("debugLogOn"),
        restartRequired=true
    }

    page:createYesNoButton{
        label = "Use green sun tint for dome interiors (excluding Arena Pit)?\nDefault: No.",
        variable = registerVariable("greenTint"),
        restartRequired=true
    }

    page:createDropdown{
        label = "Choose sun tint strength. Reload or re-enter cell after changing this setting. Default: Moderate.",
        options = {
            {label = "Weak", value = "Weak"},
            {label = "Moderate", value = "Moderate"},
            {label = "Strong", value = "Strong"},
        },
        variable=registerVariable("tintStrength")
    }


template:saveOnClose(configPath, config)
mwse.mcm.register(template)