local common = require("celediel.NoMoreFriendlyFire.common")
local config = require("celediel.NoMoreFriendlyFire.config").getConfig()

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.modConfig, config)

local page = template:createSideBarPage({
    label = "Основные настройки",
    description = string.format("%s v%s от %s\n\n%s", common.modName, common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createYesNoButton({
    label = "Выключить дружественный урон",
    variable = mwse.mcm.createTableVariable({id = "stopDamage", table = config})
})

category:createYesNoButton({
    label = "Выключить дружественный бой",
    variable = mwse.mcm.createTableVariable({id = "stopCombat", table = config})
})

category:createDropdown({
    label = "Уровень журнала",
    options = {
        {label = "No", value = common.logLevels.no},
        {label = "Small", value = common.logLevels.small},
        {label = "Big", value = common.logLevels.big}
    },
    variable = mwse.mcm.createTableVariable({id = "debugLevel", table = config})
})

template:createExclusionsPage({
    label = "Исключения",
    description = "NPC, существа и целиком все объекты из плагинов, внесенные в этот список, не будут считаться компаньонами.",
    showAllBlocked = false,
    filters = {
        {label = "Плагины", type = "Plugin"},
        {label = "NPC", type = "Object", objectType = tes3.objectType.npc},
        {label = "Существа", type = "Object", objectType = tes3.objectType.creature}
    },
    variable = mwse.mcm.createTableVariable({id = "ignored", table = config})
})

return template
