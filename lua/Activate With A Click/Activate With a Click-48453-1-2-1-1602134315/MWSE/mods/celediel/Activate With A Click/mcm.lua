local common = require("celediel.Activate With A Click.common")
local config = require("celediel.Activate With A Click.config")

local function createTableVar(id) return mwse.mcm.createTableVariable {id = id, table = config} end

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.configString, config)

local page = template:createSideBarPage({
    label = "Sidebar Page???",
    description = string.format("%s v%s by %s\n\n%s", common.modName, common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createYesNoButton({
    label = "Activate with a click?",
    description = "Does what it says!",
    variable = createTableVar("clickActivate")
})

category:createYesNoButton({
    label = "Disable when weapon is out?",
    description = "Don't activate with a click when weapon is readied.",
    variable = createTableVar("disableWithWeapon")
})

category:createDropdown({
    label = "Select which mouse button activates",
    options = {
        {label = "Left", value = common.click.left},
        {label = "Right", value = common.click.right},
        {label = "Middle", value = common.click.middle},
        {label = "Four", value = common.click.four},
        {label = "Five", value = common.click.five},
        {label = "Six", value = common.click.six},
        {label = "Seven", value = common.click.seven},
        {label = "Eight", value = common.click.eight}
    },
    variable = createTableVar("activateMouseButton")
})

return template
