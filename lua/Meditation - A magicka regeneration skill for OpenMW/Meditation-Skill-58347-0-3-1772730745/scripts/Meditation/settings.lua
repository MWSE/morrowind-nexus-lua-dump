local input = require('openmw.input')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local core = require('openmw.core')

I.Settings.registerPage({
    key      = 'SettingsMeditationPage',
    l10n     = 'Meditation',
    name     = 'skill_meditation_name',
    description = 'skill_meditation_desc',
})

I.Settings.registerGroup({
    key      = 'SettingsMeditationControls',
    page     = 'SettingsMeditationPage',
    l10n     = 'Meditation',
    name     = 'settings_controls_name',
    description = 'settings_controls_desc',
    permanentStorage = true,
    settings = {
        {
            key      = 'MeditationKeybind',
            renderer = 'inputBinding',
            name     = 'keybind_meditate_name',
            description = 'keybind_meditate_desc',
            default  = '',
            argument = {
                type = 'trigger',
                key  = 'MeditationToggle',
            },
        },
    },
})

I.Settings.registerGroup({
    key      = 'SettingsMeditationGameplay',
    page     = 'SettingsMeditationPage',
    l10n     = 'Meditation',
    name     = 'settings_gameplay_name',
    description = 'settings_gameplay_desc',
    permanentStorage = false,
    settings = {
        {
            key      = 'ConcentrationBase',
            renderer = 'number',
            name     = 'setting_concentration_base_name',
            description = 'setting_concentration_base_desc',
            default  = 4,
            argument = { min = 2, max = 20 },
        },
        {
            key      = 'MagickaPerConcentration',
            renderer = 'number',
            name     = 'setting_magicka_rate_name',
            description = 'setting_magicka_rate_desc',
            default  = 0.8,
            argument = { min = 0.3, max = 5.0 },
        },
    },
})