local interfaces = require('openmw.interfaces')
local input = require('openmw.input')

interfaces.Settings.registerPage({
    key = 'DashDodge',
    l10n = 'DashDodge',
    name = 'name',
    description = 'description',
})

-- Input settings
input.registerAction {
    key = 'DashDodgeAction',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'DashDodge',
    defaultValue = false,
}

interfaces.Settings.registerGroup({
    key = 'DashDodge_Controls',
    page = 'DashDodge',
    l10n = 'DashDodge',
    name = 'Controls',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = "DashDodgeActionButton",
            renderer = "inputBinding",
            default = "Dash_Dodge_Action_Button",
            name = "Dash Dodge",
            description = 'Press this button to perform a dash dodge when in combat stance.',
            argument = {
                type = "action",
                key = "DashDodgeAction"
            },
        }
    }
})
