local common = require("celediel.DoorRandomizer.common")
local config = require("celediel.DoorRandomizer.config").getConfig()

local function createTableVar(id) return mwse.mcm.createTableVariable({id = id, table = config}) end

local template = mwse.mcm.createTemplate({name = common.modName})
template:saveOnClose(common.configPath, config)

local page = template:createSideBarPage({
    label = "Main Options",
    description = string.format("%s v%s by %s\n\n%s\n\n", common.modName, common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createYesNoButton({label = "Pick wilderness cells?", variable = createTableVar("wildernessCells")})

category:createYesNoButton({
    label = "Pick only cells that place the player at doors?",
    variable = createTableVar("needDoor")
})

category:createDropdown({
    label = "Pick interior or exterior cells only",
    options = {
        {label = "Both", value = common.cellTypes.both},
        {label = "Interior Only", value = common.cellTypes.interior},
        {label = "Exterior Only", value = common.cellTypes.exterior},
        {label = "Match Original Destination", value = common.cellTypes.match}
    },
    defaultSetting = common.cellTypes.both,
    variable = createTableVar("interiorExterior")
})

category:createSlider({
    label = "Randomize Chance",
    min = 0,
    max = 100,
    step = 1,
    jump = 2,
    variable = createTableVar("randomizeChance")
})

category:createYesNoButton({
    label = "Keep randomized destination?",
    description = "Doors keep the randomized destination, or get " ..
        "reset to their original destination after cell change.\n\n" ..
        "Warning! This (presumably) permanently alters the door's " ..
        "destination for that save. Enable at your own peril!",
    variable = createTableVar("keepRandomized")
})

category:createYesNoButton({label = "Ignore scripted doors?", variable = createTableVar("ignoreScripted")})

category:createYesNoButton({label = "Debug logging", variable = createTableVar("debug")})

template:createExclusionsPage({
    label = "Ignored cells",
    description = "These cells will not even be considered when randomizing.",
    showAllBlocked = false,
    variable = createTableVar("ignoredCells"),
    filters = {
        {
            label = "Cells",
            callback = function()
                local cells = {}
                for cell, _ in pairs(tes3.dataHandler.nonDynamicData.cells) do table.insert(cells, cell) end
                return cells
            end
        }
    }
})

template:createExclusionsPage({
    label = "Ignored doors",
    description = "These doors will not be randomized.",
    showAllBlocked = false,
    variable = createTableVar("ignoredDoors"),
    filters = {{label = "Doors", type = "Object", objectType = tes3.objectType.door}}
})

return template
