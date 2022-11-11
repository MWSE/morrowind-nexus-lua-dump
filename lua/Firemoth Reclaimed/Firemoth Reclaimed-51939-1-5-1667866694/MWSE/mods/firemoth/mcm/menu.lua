local configPath = "firemoth"
local config = require("firemoth.mcm.config")

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="Firemoth Reclaimed",
    headerImagePath="\\Textures\\fm\\fm_logo.dds"}

    local mainPage = template:createPage{label="Main Settings", noScroll=true}
    mainPage:createCategory{
        label = string.format("")
    }
	mainPage:createDropdown {
		label = "Turn off battle music in Firemoth? Default: Yes.",
		options = {
			{ label = "Yes", value = tes3.musicSituation.uninterruptible },
			{ label = "No", value = tes3.musicSituation.explore }
		},
		restartRequired = true,
		variable = registerVariable("musicSituation")
	}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
