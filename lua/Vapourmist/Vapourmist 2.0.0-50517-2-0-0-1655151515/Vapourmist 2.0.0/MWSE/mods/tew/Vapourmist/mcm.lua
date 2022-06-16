local configPath = "Vapourmist"
local config = require("tew.Vapourmist.config")
mwse.loadConfig("Vapourmist")
local version = require("tew\\Vapourmist\\version")
local VERSION = version.version

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name = "Vapourmist",
    headerImagePath="\\Textures\\tew\\Vapourmist\\logo.dds"}

    local page = template:createPage{label="Main Settings", noScroll=true}
    page:createCategory{
        label = "Vapourmist "..VERSION.." by tewlwolow.\nLua-based 3D mist and clouds.\nWarning! Some of the higher settings can bottleneck your performance or freeze your game. Use with caution. Stick to defaults if you're not running a high-end PC.\nSettings:\n",
    }
    page:createYesNoButton{
        label = "Enable debug mode?",
        variable = registerVariable("debugLogOn"),
        restartRequired=true
    }


template:saveOnClose(configPath, config)
mwse.mcm.register(template)
