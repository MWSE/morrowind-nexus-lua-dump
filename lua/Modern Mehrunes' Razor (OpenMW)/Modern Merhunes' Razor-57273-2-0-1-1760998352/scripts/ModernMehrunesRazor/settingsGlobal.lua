local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsModernMehrunesRazor_general',
    page = 'ModernMehrunesRazor',
    l10n = 'ModernMehrunesRazor',
    name = 'general_group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'modEnabled',
            name = 'modEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'preset',
            name = 'preset_name',
            description = 'preset_description',
            renderer = 'select',
            argument = {
                l10n = "ModernMehrunesRazor",
                items = {
                    "Oblivion-style",
                    "Skyrim-style",
                    "Custom",
                    "Cheater"
                },
            },
            default = "Custom"
        },
        {
            key = 'baseChance',
            name = 'baseChance_name',
            description = 'baseChance_description',
            renderer = 'number',
            integer = false,
            default = 1,
        },
        {
            key = 'luckModifier',
            name = 'luckModifier_name',
            description = 'luckModifier_description',
            renderer = 'number',
            integer = false,
            default = 0.05,
        },
        {
            key = 'counterRollEnabled',
            name = 'counterRollEnabled_name',
            description = 'counterRollEnabled_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'counterRollModifier',
            name = 'counterRollModifier_name',
            renderer = 'number',
            integer = false,
            default = 0.01,
        },
        {
            key = 'debugMode',
            name = 'debugMode_name',
            description = 'debugMode_description',
            renderer = 'checkbox',
            default = false,
        },
    }
}