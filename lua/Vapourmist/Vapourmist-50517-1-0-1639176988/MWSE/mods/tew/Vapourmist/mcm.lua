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
    page:createYesNoButton{
        label = "Enable low-hanging mist at dawn, dusk, night and in overcast/foggy weather?",
        variable = registerVariable("mistOn"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable high altitude clouds?",
        variable = registerVariable("cloudsOn"),
        restartRequired=true
    }

    page:createSlider{
        label = "Changes max cloud amount in a cell. Default = 20.\nRequires changing cell or weather. Cloud amount",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable=registerVariable("CLOUD_LIMIT")
    }

    page:createSlider{
        label = "Changes % cloud density. Default = 10%.\nRequires changing cell or weather. Cloud density %",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable=registerVariable("CLOUD_DENSITY")
    }

    page:createSlider{
        label = "Changes cloud speed. Default = 20.\nCloud speed",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable=registerVariable("MOVE_SPEED")
    }


template:saveOnClose(configPath, config)
mwse.mcm.register(template)
