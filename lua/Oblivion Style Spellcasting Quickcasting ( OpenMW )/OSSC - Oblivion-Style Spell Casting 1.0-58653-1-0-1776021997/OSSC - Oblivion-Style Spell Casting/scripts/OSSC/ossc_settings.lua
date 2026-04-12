print("--- OSSC SETTINGS INITIALIZATION START ---")
local I     = require('openmw.interfaces')
local input = require('openmw.input')

-- Register the Quick Cast input action so it can be bound by the player in Settings > Controls
input.registerAction {
    key          = 'OSSC_QuickCast',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'OSSC',
    defaultValue = false,
}

if I.Settings and I.Settings.registerPage then
    I.Settings.registerPage({
        key = 'OSSCPage',
        l10n = 'OSSC',
        name = 'Oblivion-Style Spell Casting v1.0',
        description = 'Settings for the OSSC Mod'
    })

    I.Settings.registerGroup({
        key = 'SettingsOSSC_Keys',
        page = 'OSSCPage',
        l10n = 'OSSC',
        name = 'Controls',
        permanentStorage = true,
        order = 1,
        settings = {
            {
                key         = 'QuickCastBinding',
                renderer    = 'inputBinding',
                default     = 'OSSC_QuickCast_default',
                name        = 'Quick Cast',
                description = 'Key used to quick-cast the currently selected spell as a projectile.',
                argument    = {
                    type = 'action',
                    key  = 'OSSC_QuickCast',
                },
            }
        }
    })

    I.Settings.registerGroup({
        key = 'SettingsOSSC_General',
        page = 'OSSCPage',
        l10n = 'OSSC',
        name = 'Gameplay',
        permanentStorage = true,
        order = 2,
        settings = {
            {
                key = 'UseFatigue',
                name = 'Use Fatigue',
                description = 'Enable/disable fatigue usage upon spellcasting.(MCP Formula)',
                renderer = 'checkbox',
                default = true
            },
            {
                key         = 'DebugMode',
                name        = 'Debug Mode',
                description = 'Show OSSC logic debug messages in the console (F1).',
                renderer    = 'checkbox',
                default     = false
            },
            {
                key = 'SkillExperience',
                name = 'Skill Experience Ratio',
                description = 'Ratio of XP awarded for a successful spellcast.',
                renderer = 'number',
                default = 1.0,
                min = 0,
                max = 100
            }
        }
    })

    I.Settings.registerGroup({
        key = 'SettingsOSSC_Speeds',
        page = 'OSSCPage',
        l10n = 'OSSC',
        name = 'Projectile Speeds',
        permanentStorage = true,
        order = 3,
        settings = {
            { key = 'SpeedFire',        name = 'Fire Speed',        description = 'Speed for Fire magic.',        renderer = 'number', default = 4500 },
            { key = 'SpeedFrost',       name = 'Frost Speed',       description = 'Speed for Frost magic.',       renderer = 'number', default = 2500 },
            { key = 'SpeedShock',       name = 'Shock Speed',       description = 'Speed for Shock magic.',       renderer = 'number', default = 3200 },
            { key = 'SpeedPoison',      name = 'Poison Speed',      description = 'Speed for Poison magic.',      renderer = 'number', default = 2900 },
            { key = 'SpeedHeal',        name = 'Restoration Speed', description = 'Speed for Restoration.',      renderer = 'number', default = 2800 },
            { key = 'SpeedIllusion',    name = 'Illusion Speed',    description = 'Speed for Illusion magic.',    renderer = 'number', default = 3000 },
            { key = 'SpeedAlteration',  name = 'Alteration Speed',  description = 'Speed for Alteration magic.',  renderer = 'number', default = 2900 },
            { key = 'SpeedConjuration', name = 'Conjuration Speed', description = 'Speed for Conjuration magic.', renderer = 'number', default = 3000 },
            { key = 'SpeedMysticism',   name = 'Mysticism Speed',   description = 'Speed for Mysticism magic.',   renderer = 'number', default = 2900 },
            { key = 'SpeedDefault',     name = 'Default Speed',     description = 'Speed for others.',            renderer = 'number', default = 1500 }
        }
    })

end

print("--- OSSC SETTINGS INITIALIZATION FINISHED ---")
return {}
