local config = require("celediel.MoreAttentiveGuards.config").getConfig()
local common = require("celediel.MoreAttentiveGuards.common")

-- {{{ helper functions

local function createTableVar(id) return mwse.mcm.createTableVariable({id = id, table = config}) end

local function createLanguageOptions()
    local options = {}
    -- I guess I don't know how ipairs works
    local i = 1
    for name, _ in pairs(common.dialogues) do
        options[i] = {label = name:gsub("^%l", string.upper), value = name}
        i = i + 1 -- wtf lua
    end
    return options
end

-- }}}

-- {{{ main settings page

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.configString, config)

local page = template:createSideBarPage({
    label = "Sidebar page",
    description = string.format("%s v%s by %s\n\n%s\n\n", common.modName, common.version, common.author, common.modInfo)
})

local mainCategory = page:createCategory(common.modName)

-- }}}

-- {{{ general settings

local generalCategory = mainCategory:createCategory("Common settings")

generalCategory:createDropdown({
    label = "Language",
    options = createLanguageOptions(),
    variable = createTableVar("language")
})

generalCategory:createYesNoButton({
    label = "Debug mode",
    description = "Print debug messages to the log.",
    variable = createTableVar("debug")
})

-- }}}

-- {{{ sneak settings

local sneakCategory = mainCategory:createCategory("Sneak Settings")

sneakCategory:createYesNoButton({
    label = "Enable sneak module",
    description = "Guards who catch you sneaking will follow you for a bit of time.",
    variable = createTableVar("sneakEnable")
})

sneakCategory:createYesNoButton({
    label = "Sneak dialogue",
    description = "Guards sometimes say things to you when you sneak.",
    variable = createTableVar("sneakDialogue")
})

sneakCategory:createSlider({
    label = "Sneak dialogue chance",
    description = "Percent chance a guard will say something each time the dialogue timer fires.",
    min = 0,
    max = 100,
    step = 1,
    jump = 5,
    variable = createTableVar("sneakDialogueChance")
})

sneakCategory:createSlider({
    label = "Sneak dialogue timer",
    description = "Roll for dialogue every x seconds while following.",
    min = 0,
    max = 60,
    step = 1,
    jump = 5,
    variable = createTableVar("sneakDialogueTimer")
})

-- }}}

-- {{{ combat settings

local combatCategory = mainCategory:createCategory("Combat Settings")

combatCategory:createYesNoButton({
    label = "Enable combat module",
    description = "Guards will come to the rescue of a player who is attacked unprovoked.",
    variable = createTableVar("combatEnable")
})

combatCategory:createSlider({
    label = "Guard alert range",
    description = "How far away guards are alerted to combat against the player",
    min = 1,
    max = 20000,
    step = 10,
    jump = 50,
    variable = createTableVar("combatDistance")
})

combatCategory:createYesNoButton({
    label = "Enable combat dialogue",
    description = "Guards have things to say when they come to the rescue of a player who is attacked unprovoked.",
    variable = createTableVar("combatDialogue")
})

-- }}}

template:createExclusionsPage({
    label = "Ignored NPCs/Creatures",
    description = "Guards will not respond to these NPCs or creatures attacking the player.",
    showAllBlocked = false,
    filters = {
        {label = "Plugins", type = "Plugin"},
        {label = "NPCs", type = "Object", objectType = tes3.objectType.npc},
        {label = "Creatures", type = "Object", objectType = tes3.objectType.creature}
    },
    variable = createTableVar("ignored")
})

return template

-- vim:fdm=marker
