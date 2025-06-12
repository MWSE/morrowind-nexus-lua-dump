local I = require('openmw.interfaces')

local l10nKey = 'TamrielRebuilt'
local settingsPageKey = "Settings_TamrielRebuilt"

I.Settings.registerPage({
    key = settingsPageKey,
    l10n = l10nKey,
    name = 'TamrielRebuilt_modName',
    description = settingsPageKey .. "_Description",
})

I.Settings.registerGroup({
    key = settingsPageKey .. '_Misc',
    page = settingsPageKey,
    l10n = l10nKey,
    name = settingsPageKey .. '_MiscName',
    permanentStorage = true,
    settings = {
        {
            key = 'FiremothComp',
            renderer = 'checkbox',
            name = settingsPageKey .. '_FiremothCompWarning',
            description = settingsPageKey .. '_FiremothCompDescription',
            default = true
        }
    },
})
