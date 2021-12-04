local config = require("poisonCrafting.config")
config.version = 2.1

local template = mwse.mcm.createTemplate{name="Poison Crafting"}
template:saveOnClose("poisonCrafting", config)
template:register()

local page = template:createSideBarPage{}
page.sidebar:createInfo{text=("Poison Crafting v%.1f\n\nBy Greatness7"):format(config.version)}

page:createOnOffButton{
    label = "Add Effect Icons",
    description = "This feature adds magic effect icons to appropritate inventory item tiles.",
    variable = mwse.mcm:createTableVariable{
        id = "useEffectIcons",
        table = config,
    },
}

page:createOnOffButton{
    label = "Alchemy Exploit Fix",
    description = "This feature forces the alchemy systems to use the player's base attributes and skills, rather than their drained or fortified values.",
    variable = mwse.mcm:createTableVariable{
        id = "useBaseStats",
        table = config,
    },
}

page:createOnOffButton{
    label = "Alchemy Bonus Progress",
    description = "This feature grants additional alchemy skill progress dependent on the number of magic effects in a created potion.\n\nFor each effect beyond the first, your progress gained will be increased by an additional 10 percent.",
    variable = mwse.mcm:createTableVariable{
        id = "useBonusProgress",
        table = config,
    },
}

page:createOnOffButton{
    label = "Apply Poison Prompt",
    description = "This feature causes a menu prompt to appear when applying poisons to weapons, to help avoid potential misclicks.",
    variable = mwse.mcm:createTableVariable{
        id = "useApplyMessage",
        table = config,
    },
}
