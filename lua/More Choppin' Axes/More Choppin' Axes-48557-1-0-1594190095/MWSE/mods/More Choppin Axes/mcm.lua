local common = require("More Choppin Axes.common")
local config = require("More Choppin Axes.config").getConfig()

-- local restartMessage = "Restart the game or click the 'Apply Fixes' button."

local function createTableVar(id)
    return mwse.mcm.createTableVariable({
        id = id,
        table = config,
        restartRequired = true
        -- restartRequiredMessage = restartMessage
    })
end

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.configString, config)

local page = template:createSideBarPage({
    label = "Sidebar page",
    description = string.format("%s v%s by %s\n\n%s\n\n", common.modName,
                                common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createYesNoButton({
    label = "Mod enabled?",
    variable = createTableVar("enabled")
})

category:createDropdown({
    label = "Fix mode",
    description = common.fixTypesDescription,
    options = {
        {label = "Boost minimum", value = common.fixTypes.boostMin},
        {label = "Boost maximum", value = common.fixTypes.boostMax},
        {label = "Swap", value = common.fixTypes.swap}
    },
    variable = createTableVar("fixType")
})

category:createDropdown({
    label = "Log level",
    description = common.logLevelsDescription,
    options = {
        {label = "None", value = common.logLevels.none},
        {label = "Small", value = common.logLevels.small},
        {label = "Medium", value = common.logLevels.medium},
        {label = "Large", value = common.logLevels.large}
    },
    variable = createTableVar("logLevel")
})

-- todo: make this work
-- category:createButton({
--     buttonText = "Apply",
--     label = "Apply Fixes",
--     description = "Apply changes without restarting the game.",
--     inGameOnly = true,
--     callback = function() common.applyFixes(currentConfig.fixType, currentConfig.logLevel) end
-- })

return template
