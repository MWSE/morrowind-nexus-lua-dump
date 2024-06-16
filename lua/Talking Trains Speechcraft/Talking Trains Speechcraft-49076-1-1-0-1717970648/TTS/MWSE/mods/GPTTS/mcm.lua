local config  = require("gptts.config")
local modName = 'Talking Trains Speechcraft';
local template = mwse.mcm.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()

local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "Talking Trains Speechcraft \n\n by GOOGLEPOX \n\n This mod adds a configurable amount of Speech XP for each dialogue topic clicked. "
    }
    return page
end

-- Settings

local settings = createPage("Settings")

local globalSettings = settings:createCategory("XP Settings")

globalSettings:createSlider {
    label = "Speechcraft XP",
    description = "Changes the XP gain from each dialogue option clicked. Divided by 10. Default 10",
    max = 25,
    min = 0,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "speechXP",
        table = config
    }
}