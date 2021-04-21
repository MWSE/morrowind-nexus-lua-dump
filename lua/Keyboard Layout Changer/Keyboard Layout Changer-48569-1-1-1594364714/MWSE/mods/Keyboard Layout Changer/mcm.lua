local keys = require("Keyboard Layout Changer.keys")
local common = require("Keyboard Layout Changer.common")
local config = require("Keyboard Layout Changer.config").getConfig()

local restartMessage = "Restart the game or click the Apply button to apply changes."

local function createTableVar(id)
    return mwse.mcm.createTableVariable({
        id = id,
        table = config,
        restartRequired = true,
        restartRequiredMessage = restartMessage
    })
end

local function createOptions()
    local options = {}
    -- I guess I don't know how ipairs works
    local i = 1
    for name, _ in pairs(keys) do
        options[i] = {label = name:gsub("^%l", string.upper), value = name}
        i = i + 1 -- wtf lua
    end
    return options
end

local function applyLayout()
    local message = "Changing layout to " .. config.keyboardLayout
    tes3.messageBox(message)
    common.log(message)
    common.changeLayout(config.keyboardLayout)
end

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.configString, config)

local page = template:createSideBarPage({
    label = "Sidebar page",
    description = string.format("%s v%s by %s\n\n%s\n\n", common.modName,
                                common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createDropdown({
    label = "Keyboard layout",
    options = createOptions(),
    variable = createTableVar("keyboardLayout")
})

category:createButton({
    label = "Apply changes",
    buttonText = "Apply",
    callback = applyLayout
})

return template
