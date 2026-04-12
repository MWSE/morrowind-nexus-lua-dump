local I = require('openmw.interfaces')

if I.Settings and I.Settings.registerPage then
    I.Settings.registerPage({
        key         = 'MagExpPage',
        l10n        = 'MagExp',
        name        = 'Magicka Expanded v1.0',
        description = 'Framework settings for OMW Magicka Expanded Framework'
    })

    I.Settings.registerGroup({
        key              = 'SettingsMagExp_General',
        page             = 'MagExpPage',
        l10n             = 'MagExp',
        name             = 'General',
        permanentStorage = true,
        order            = 1,
        settings         = {
            {
                key         = 'DebugMode',
                name        = 'Debug Mode',
                description = 'Enable to see framework logs in the console (F1).',
                renderer    = 'checkbox',
                default     = false
            }
        }
    })
end

return {}
