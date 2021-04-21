local config = require("OperatorJack.OperatorJacksDeleveler.config")

local function createGeneralCategory(template)
    local page = template:createPage{
        label = "General Settings",
    }
	page:createYesNoButton{
    label = "Delevel creature leveled lists? [requires restarting the game]",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
        id = "levcEnabled",
        table = config
    	}
	}

	page:createYesNoButton{
    label = "Delevel item leveled lists? [requires restarting the game]",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
        id = "leviEnabled",
        table = config
    	}
	}
end

local template = mwse.mcm.createTemplate("OperatorJack's Deleveler")
template:saveOnClose("OJ-Deleveler", config)

createGeneralCategory(template)

mwse.mcm.register(template)