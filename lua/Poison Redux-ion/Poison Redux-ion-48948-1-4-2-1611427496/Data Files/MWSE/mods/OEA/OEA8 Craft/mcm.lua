local config = require("OEA.OEA8 Craft.config")

----MCM
local template = mwse.mcm.createTemplate({ name = "Poison Redux-ion" })
template:saveOnClose("Poison_Redux-ion", config)

local page = template:createPage()
page.label = "Toggles"
page.noScroll = true
page.indent = 0
page.postCreate = function(self)
    self.elements.innerContainer.paddingAllSides = 10
end

page:createYesNoButton{
    label = "Enable poison creation/application messages?",
    variable = mwse.mcm:createTableVariable{
        id = "Messages",
        table = config
    }
}

page:createYesNoButton{
    label = "Allow yourself to apply poisons outside of menus?",
    variable = mwse.mcm:createTableVariable{
         id = "Menu",
         table = config
    }
}

page:createYesNoButton{
    label = "Allow yourself to apply poisons during combat (can be overriden by above menu toggle)?",
    variable = mwse.mcm:createTableVariable{
         id = "Combat",
         table = config
    }
}

page:createYesNoButton{
    label = "Re-apply poisons to inventory on loading a save (can cause crashes when loading from within the game)?",
    variable = mwse.mcm:createTableVariable{
         id = "Startup",
         table = config
    }
}

page:createYesNoButton{
    label = "Allow enemies to resist your poisons?",
    variable = mwse.mcm:createTableVariable{
         id = "ResistLife",
         table = config
    }
}


page:createYesNoButton{
    label = "Use Poison Crafting's additional icons and models (must restart to apply change)?",
    variable = mwse.mcm:createTableVariable{
        id = "useLabels",
        table = config
    }
}

page:createYesNoButton{
    label = "Gain more alchemy XP by making potions with more effects?",
    variable = mwse.mcm:createTableVariable{
        id = "SkillBuff",
        table = config
    }
}

page:createYesNoButton{
    label = "Use base stats for alchemy instead of fortified ones?",
    variable = mwse.mcm:createTableVariable{
         id = "StatChange",
         table = config
    }
}

page:createYesNoButton{
    label = "Utilize apparati both in the world and in inventory?",
    variable = mwse.mcm:createTableVariable{
         id = "World",
         table = config
    }
}

page:createYesNoButton{
    label = "Remove *Potion* from the end of heterodox potion names?",
    variable = mwse.mcm:createTableVariable{
         id = "Excise",
         table = config
    }
}

page:createTextField{
    label = "Up to how many projectiles should be poisoned at once?",
    variable = mwse.mcm:createTableVariable{
        id = "Batchings", 
        table = config
    },
    numbersOnly = true
}

page:createSlider{
    label = "How many hits of poison do weapons get?",
    variable = mwse.mcm:createTableVariable{
        id = "MultiHit",
        table = config
    },
    min = 1,
    max = 20,
    step = 1,
    jump = 4
}

local neoPage = template:createPage()
neoPage.label = "Resistances"
neoPage.noScroll = false
neoPage.indent = 0
neoPage.postCreate = function(self)
    self.elements.innerContainer.paddingAllSides = 10
end

for class, _ in pairs(tes3.dataHandler.nonDynamicData.classes) do
	neoPage:createSlider{
        	label = ("%s Chance to Resist Poison"):format(_),
       		variable = mwse.mcm:createTableVariable{
			id = ("Resist_%s"):format(_), 
			table = config
		},
		min = 0,
		max = 100,
		step = 1,
		jump = 10
    	}
end

mwse.mcm.register(template)
