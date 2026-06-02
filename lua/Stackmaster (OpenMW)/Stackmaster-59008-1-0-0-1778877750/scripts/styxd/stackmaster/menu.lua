local input = require'openmw.input'
local storage = require'openmw.storage'
local I = require'openmw.interfaces'

local commonKeys = require'scripts.styxd.stackmaster.commonKeys'

-- The inputBinding setting renderer in OpenMW is completely insane.
-- The "default" property is not the default, but needs to be some globally
-- unique id.
-- And the way to actually set the default is this magic function,
-- taken from Discord.
-- https://discord.com/channels/260439894298460160/854806553310920714/1494122004822102096
local function setActionDefaultKey(id, action, button)
    local bindingSection = storage.playerSection'OMWInputBindings'

    if not bindingSection:get(id) then
        bindingSection:set(id, {
            device = 'keyboard',
            button = button,
            type = 'action',
            key = action
        })
    end
end

input.registerAction{
    key = commonKeys.actions.DumpAll,
    l10n = commonKeys.l10n,
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false
}

setActionDefaultKey(
    commonKeys.settings.bindings.DumpAll.key,
    commonKeys.actions.DumpAll,
    input.KEY.LeftAlt
)

input.registerAction{
    key = commonKeys.actions.PickOne,
    l10n = commonKeys.l10n,
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false
}

setActionDefaultKey(
    commonKeys.settings.bindings.PickOne.key,
    commonKeys.actions.PickOne,
    input.KEY.LeftShift
)

I.Settings.registerPage{
    key = commonKeys.settings.page.key,
    l10n = commonKeys.l10n,
    name = commonKeys.settings.page.name,
    description = commonKeys.settings.page.desc
}

I.Settings.registerGroup{
    key = commonKeys.settings.bindings.key,
    page = commonKeys.settings.page.key,
    l10n = commonKeys.l10n,
    name = commonKeys.settings.bindings.name,
    permanentStorage = true,
    settings = {
        {
            key = commonKeys.settings.bindings.DumpAll.key,
            name = commonKeys.settings.bindings.DumpAll.name,
            description = commonKeys.settings.bindings.DumpAll.desc,
            renderer = 'inputBinding',
            argument = {
                key = commonKeys.actions.DumpAll,
                type = 'action'
            },
            default = commonKeys.settings.bindings.DumpAll.key
        },
        {
            key = commonKeys.settings.bindings.PickOne.key,
            name = commonKeys.settings.bindings.PickOne.name,
            description = commonKeys.settings.bindings.PickOne.desc,
            renderer = 'inputBinding',
            argument = {
                key = commonKeys.actions.PickOne,
                type = 'action'
            },
            default = commonKeys.settings.bindings.PickOne.key,
        }
    }
}
