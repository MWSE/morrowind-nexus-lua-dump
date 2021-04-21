local config = require("OEA.OEA1 Neo.config")

----MCM
local template = mwse.mcm.createTemplate({ name = "Neo Combat" })
template:saveOnClose("Neo_Combat", config)

local page = template:createPage()
page.noScroll = true
page.indent = 0
page.postCreate = function(self)
    self.elements.innerContainer.paddingAllSides = 10
end

 
local hotkey = page:createKeyBinder{
    label = "Assign Counter Key",
    allowCombinations = true,
    variable = mwse.mcm:createTableVariable{
        id = "attackKey",
        table = config,
    }
}

local hotkey2 = page:createKeyBinder{
    label = "Assign Block Key",
    allowCombinations = true,
     variable = mwse.mcm:createTableVariable{
        id = "attackKey2",
        table = config,
    }
}

local hotkey3 = page:createKeyBinder{
    label = "Assign Rage Key",
    allowCombinations = true,
    variable = mwse.mcm:createTableVariable{
        id = "attackKey3",
        table = config,
    }
}

local hotkey4 = page:createYesNoButton{
    label = "Decide Whether Non-Rage Messages Appear",
    variable = mwse.mcm:createTableVariable{
        id = "msgkey",
        table = config,
    }
}
mwse.mcm.register(template)
