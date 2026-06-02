local I = require('openmw.interfaces')

if I.Settings and I.Settings.registerPage then
    pcall(function()
        I.Settings.registerPage({
            key         = 'MagExpPage',
            l10n        = 'MagExp',
            name        = 'SF+ 1.87 (Spell Framework Plus)',
            description = 'Settings for OMW Spell Framework+'
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
                },
                {
                    key         = 'ShowAllCastVfx',
                    name        = 'Show All Cast VFX/Reduced Cast Vfx',
                    description = 'If enabled, spells cast will show cast VFX for all spell effects. If disabled, only the first effect\'s VFX will show.',
                    renderer    = 'checkbox',
                    default     = true
                }
            }
        })
    end)
end

print("MagExp settings script loaded")

return {}
