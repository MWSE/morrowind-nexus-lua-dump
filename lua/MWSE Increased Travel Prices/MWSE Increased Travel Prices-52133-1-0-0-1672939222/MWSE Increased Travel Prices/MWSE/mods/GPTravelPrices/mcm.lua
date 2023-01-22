local config  = require("gptravelprices.config")
local modName = 'MWSE Increased Travel Prices';
local template = mwse.mcm.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()

local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "MWSE Increased Travel Prices \n\n by GOOGLEPOX \n\n This mod adds a configurable multiplier to trvael prices. Global multipler and additional multipiers for specific travel services."
    }
    return page
end

-- Settings

local settings = createPage("Settings")

local globalSettings = settings:createCategory("Price Settings")

globalSettings:createSlider {
    label = "Global Price Multiplier",
    description = "Sets the base multiplier before any other specific multipliers. Default 2",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "globalPriceMult",
        table = config
    }
}

globalSettings:createSlider {
    label = "Mages' Guild Price Multiplier",
    description = "Sets the multiplier for the Mages' Guild guides. Default 5",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "magesGuildPriceMult",
        table = config
    }
}

globalSettings:createSlider {
    label = "Silt Strider Price Multiplier",
    description = "Sets the multiplier for the silt stringer caravaneers. Default 3",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "siltStriderPriceMult",
        table = config
    }
}

globalSettings:createSlider {
    label = "Boat Price Multiplier",
    description = "Sets the multiplier for the boat captains. Default 4",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "boatPriceMult",
        table = config
    }
}

globalSettings:createSlider {
    label = "Gondola Price Multiplier",
    description = "Sets the multiplier for the gondoliers. Default 1",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "gondolaPriceMult",
        table = config
    }
}

globalSettings:createSlider {
    label = "Guar Cart Price Multiplier",
    description = "Sets the multiplier for the Guar Pack Travel mod. Default 1",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "guarPriceMult",
        table = config
    }
}

globalSettings:createSlider {
    label = "Companion Price Multiplier",
    description = "Sets the multiplier for each player companion. Default 1",
    max = 100,
    min = 0,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "companionMult",
        table = config
    }
}