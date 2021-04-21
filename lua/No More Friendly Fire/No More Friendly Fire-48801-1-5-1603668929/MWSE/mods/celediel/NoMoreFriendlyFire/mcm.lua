local common = require("celediel.NoMoreFriendlyFire.common")
local config = require("celediel.NoMoreFriendlyFire.config").getConfig()

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.modConfig, config)

local page = template:createSideBarPage({
    label = "Main options",
    description = string.format("%s v%s by %s\n\n%s", common.modName, common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createYesNoButton({
    label = "Stop friendly damage",
    variable = mwse.mcm.createTableVariable({id = "stopDamage", table = config})
})

category:createYesNoButton({
    label = "Stop friendly combat from occurring",
    variable = mwse.mcm.createTableVariable({id = "stopCombat", table = config})
})

category:createDropdown({
    label = "Debug log level",
    options = {
        {label = "No", value = common.logLevels.no},
        {label = "Small", value = common.logLevels.small},
        {label = "Big", value = common.logLevels.big}
    },
    variable = mwse.mcm.createTableVariable({id = "debugLevel", table = config})
})

template:createExclusionsPage({
    label = "Ignored things",
    description = "NPCs, creatures, and anything from plugins on this list won't be counted as a follower.",
    showAllBlocked = false,
    filters = {
        {label = "Plugins", type = "Plugin"},
        {label = "NPCs", type = "Object", objectType = tes3.objectType.npc},
        {label = "Creatures", type = "Object", objectType = tes3.objectType.creature}
    },
    variable = mwse.mcm.createTableVariable({id = "ignored", table = config})
})

return template
