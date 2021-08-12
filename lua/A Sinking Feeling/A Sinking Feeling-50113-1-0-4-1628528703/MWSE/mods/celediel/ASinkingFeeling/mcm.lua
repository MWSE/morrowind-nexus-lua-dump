local common = require("celediel.ASinkingFeeling.common")
local config = require("celediel.ASinkingFeeling.config")

local function createTableVar(id) return mwse.mcm.createTableVariable {id = id, table = config} end

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.configString, config)

local page = template:createSideBarPage({
    label = "Sidebar Page???",
    description = string.format("%s v%s by %s\n\n%s", common.modName, common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createYesNoButton({
    label = "Enable the mod",
    description = "Does what it says!",
    variable = createTableVar("enabled")
})

category:createYesNoButton({
    label = "Player-only",
    description = "The mod only affects the player, not other actors.",
    variable = createTableVar("playerOnly")
})

category:createDropdown({
    label = "Down-pull formula",
    description = "Formula used to calculate down-pull amount.\n\nOptions are: Equipped Armour, Equipment Weight, Encumbrance\n\n" ..
        "Equipped Armour: Actors are pulled down by their combined armour class (Light = 1, Medium = 2, Heavy = 3), " ..
        "multiplied by a tenth of the down-pull multiplier. Default of 100 makes it impossible to surface in all heavy armour for all but the most Athletic.\n\n" ..
        "Equipment weight: Actors are pulled down by double the weight of all equipped gear multiplied by a hundredth of the down-pull multiplier.\n\n" ..
        "Encumbrance: Actors are pulled down by their encumbrance percentage multiplied by triple the down-pull multiplier.\n\n",
    options = {
        { label = "Equipped Armour", value = common.modes.equippedArmour },
        { label = "All Equipment", value = common.modes.allEquipment },
        { label = "Encumbrance", value = common.modes.encumbrancePercentage }
    },
    variable = createTableVar("mode")
})

category:createSlider({
    label = "Down-pull multiplier",
    description = "Multiplier used in the selected formula.\n\nDefault value of 100 acts similarly in all formulas.",
    variable = createTableVar("downPullMultiplier"),
    min = 0,
    max = 300,
    step = 1,
    jump = 10
})

category:createYesNoButton({
    label = "Debug logging",
    description = "Spam mwse.log with useless nonsense.",
    variable = createTableVar("debug")
})

return template
