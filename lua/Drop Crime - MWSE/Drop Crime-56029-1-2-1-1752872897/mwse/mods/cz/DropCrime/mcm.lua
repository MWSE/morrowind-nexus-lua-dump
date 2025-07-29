local config = require("cz.DropCrime.config")

local function getItems()
    local temp = {}

    local itemTypes = { 
        [tes3.objectType.alchemy] = true,
        [tes3.objectType.ammunition] = true,
        [tes3.objectType.apparatus] = true,
        [tes3.objectType.armor] = true,
        [tes3.objectType.book] = true,
        [tes3.objectType.clothing] = true,
        [tes3.objectType.ingredient] = true,
        [tes3.objectType.light] = true,
        [tes3.objectType.lockpick] = true,
        [tes3.objectType.miscItem] = true,
        [tes3.objectType.probe] = true,
        [tes3.objectType.repairItem] = true,
        [tes3.objectType.weapon] = true
    }

    for itemType, _ in pairs(itemTypes)do
        for obj in tes3.iterateObjects(itemType) do
            temp[obj.id:lower()] = true
        end
    end

    local list = {}
    for id in pairs(temp) do
        list[#list+1] = id
    end

    table.sort(list)
    return list
end

local function getNPCs()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.npc) do
        temp[obj.id:lower()] = true
    end

    local list = {}
    for id in pairs(temp) do
        list[#list+1] = id
    end

    table.sort(list)
    return list
end

local template = mwse.mcm.createTemplate({ name = "Drop Crime" })
template:saveOnClose("dropcrime", config)
template:register()

local page = template:createSideBarPage({ label = "Settings" })

page.sidebar:createInfo({
    text = (
        "Drop Crime v1.1\n"
        .. "By CarlZee\n\n"
        .. "Contraband like Skooma and Moonsugar are now not only illegal to carry, but to dispose of as well!\n\n"
    ),
})

local settings = page:createCategory("Settings")

settings:createYesNoButton({
    label = "Enable Mod",
    variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
})

settings:createYesNoButton({
    label = "Guards Only",
    description =
        "If enabled, only guards (100 alarm actors) will react and trigger crime events when contraband is dropped or picked up.\n" ..
        "\n" ..
        "Default: no",
    variable = mwse.mcm.createTableVariable({ id = "guardsOnly", table = config }),
})

settings:createYesNoButton({
    label = "Enable Dwemer Contraband",
    description =
        "If enabled, Dwemer/Dwarven items will be considered contraband and will trigger a crime alarm when dropped.\n" ..
        "\n" ..
        "Default: yes",
    variable = mwse.mcm.createTableVariable({ id = "contrabandDwemer", table = config }),
})

settings:createYesNoButton({
    label = "Dwemer Contraband No Gear",
    description =
        "If enabled, and Dwemer Contraband is enabled, Dwemer weapons and armor will not trigger a crime alarm when dropped.\n" ..
        "\n" ..
        "Default: yes",
    variable = mwse.mcm.createTableVariable({ id = "contrabandDwemerNoGear", table = config }),
})

settings:createYesNoButton({
    label = "Enable Ebony Contraband",
    description =
        "If enabled, Raw Ebony will be considered contraband and will trigger a crime alarm when dropped.\n" ..
        "\n" ..
        "Default: yes",
    variable = mwse.mcm.createTableVariable({ id = "contrabandEbony", table = config }),
})

settings:createYesNoButton({
    label = "Enable Glass Contraband",
    description =
        "If enabled, Raw Glass will be considered contraband and will trigger a crime alarm when dropped.\n" ..
        "\n" ..
        "Default: yes",
    variable = mwse.mcm.createTableVariable({ id = "contrabandGlass", table = config }),
})

template:createExclusionsPage({
    label = "Contraband List",
    leftListLabel = "Contraband",
    rightListLabel = "Items",
    variable = mwse.mcm.createTableVariable{
		id = "contrabandList",
		table = config,
	},
    filters = {
        { label = "Items", callback = getItems }
    },
    showReset = true
})

template:createExclusionsPage({
    label = "Not Contraband List",
    leftListLabel = "Not Contraband",
    rightListLabel = "Items",
    variable = mwse.mcm.createTableVariable{
		id = "notContrabandList",
		table = config,
	},
    filters = {
        { label = "Items", callback = getItems }
    },
    showReset = true
})

template:createExclusionsPage({
    label = "Smuggler List",
    leftListLabel = "Smugglers",
    rightListLabel = "NPCs",
    variable = mwse.mcm.createTableVariable{
		id = "smugglerList",
		table = config,
	},
    filters = {
        { label = "NPCs", callback = getNPCs }
    },
    showReset = true
})

return template