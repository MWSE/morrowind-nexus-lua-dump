local I = require('openmw.interfaces')

if I.Settings and I.Settings.registerPage then
    pcall(function()
        I.Settings.registerPage({
            key         = 'MagExpPage',
            l10n        = 'MagExp',
            name        = 'Spell Framework Plus 1.8',
            description = 'Framework settings for OMW Spell Framework Plus'
        })
    end)

    pcall(function()
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
    end)
end

print("MagExp settings script loaded")

return {}
