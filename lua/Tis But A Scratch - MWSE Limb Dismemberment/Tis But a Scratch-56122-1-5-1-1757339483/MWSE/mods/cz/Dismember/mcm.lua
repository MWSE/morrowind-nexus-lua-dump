local config = require("cz.Dismember.config")

local template = mwse.mcm.createTemplate({ name = "Tis But a Scratch" })
template:saveOnClose("dismember", config)
template:register()

local page = template:createSideBarPage({ label = "Settings" })

page.sidebar:createInfo({
    text = (
        "Tis But a Scratch v1.0\n"
        .. "By CarlZee\n\n"
        .. "NPCs can now be dismembered on death, resulting in a bloody mess!\n\n"
    ),
})

local settings = page:createCategory("Settings")

settings:createYesNoButton({
    label = "Enable Mod",
    variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
})

settings:createSlider({
    label = "Base chance: ".."%s%%",
    description =
        "The base chance of an NPC getting dismembered on death.\n" ..
        "\n" ..
        "Default: 50%",
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = mwse.mcm.createTableVariable{id = "baseChance", table = config}
})

settings:createSlider({
    label = "Minimum damage: ".."%s",
    description =
        "The minimum damage required to be dealt for an NPC to get dismembered on death.\n" ..
        "\n" ..
        "Default: 15",
    min = 0,
    max = 200,
    step = 1,
    jump = 10,
    variable = mwse.mcm.createTableVariable{id = "minDamage", table = config}
})

settings:createOnOffButton({
    label = "Enable Creatures",
    description = "Allow creatures to dismember NPCs.",
    variable = mwse.mcm.createTableVariable{id = "enableCreatures", table = config}
})

settings:createOnOffButton({
    label = "Enable HandToHand",
    variable = mwse.mcm.createTableVariable{id = "enableFists", table = config}
})

settings:createOnOffButton({
    label = "Enable ShortBlade",
    variable = mwse.mcm.createTableVariable{id = "enableShortBlade", table = config}
})

settings:createOnOffButton({
    label = "Enable LongBladeOneHand",
    variable = mwse.mcm.createTableVariable{id = "enableLongBladeOneHand", table = config}
})

settings:createOnOffButton({
    label = "Enable LongBladeTwoHand",
    variable = mwse.mcm.createTableVariable{id = "enableLongBladeTwoHand", table = config}
})

settings:createOnOffButton({
    label = "Enable BluntOneHand",
    variable = mwse.mcm.createTableVariable{id = "enableBluntOneHand", table = config}
})

settings:createOnOffButton({
    label = "Enable BluntTwoClose",
    variable = mwse.mcm.createTableVariable{id = "enableBluntTwoClose", table = config}
})

settings:createOnOffButton({
    label = "Enable BluntTwoWide",
    variable = mwse.mcm.createTableVariable{id = "enableBluntTwoWide", table = config}
})

settings:createOnOffButton({
    label = "Enable Spear",
    variable = mwse.mcm.createTableVariable{id = "enableSpearTwoWide", table = config}
})

settings:createOnOffButton({
    label = "Enable AxeOneHand",
    variable = mwse.mcm.createTableVariable{id = "enableAxeOneHand", table = config}
})

settings:createOnOffButton({
    label = "Enable AxeTwoHand",
    variable = mwse.mcm.createTableVariable{id = "enableAxeTwoHand", table = config}
})

settings:createOnOffButton({
    label = "Enable MarksmanBow",
    variable = mwse.mcm.createTableVariable{id = "enableMarksmanBow", table = config}
})

settings:createOnOffButton({
    label = "Enable MarksmanCrossbow",
    variable = mwse.mcm.createTableVariable{id = "enableMarksmanCrossbow", table = config}
})

settings:createOnOffButton({
    label = "Enable MarksmanThrown",
    variable = mwse.mcm.createTableVariable{id = "enableMarksmanThrown", table = config}
})

return template