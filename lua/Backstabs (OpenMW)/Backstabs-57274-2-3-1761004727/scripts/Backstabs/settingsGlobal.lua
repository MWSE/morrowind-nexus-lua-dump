local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsBackstabs_toggles',
    page = 'Backstabs',
    l10n = 'Backstabs',
    name = 'toggles_group_name',
    order = 0,
    permanentStorage = true,
    settings = {
        {
            key = 'modEnabled',
            name = 'modEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'playerCanBeBackstabbed',
            name = 'playerCanBeBackstabbed_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'creatureBackstabsEnabled',
            name = 'creatureBackstabsEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'requireCrouching',
            name = 'requireCrouching_name',
            description = 'requireCrouching_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'enableSpecialWeaponInstakill',
            name = 'enableSpecialWeaponInstakill_name',
            description = 'enableSpecialWeaponInstakill_description',
            renderer = 'checkbox',
            default = false,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBackstabs_weaponTypes',
    page = 'Backstabs',
    l10n = 'Backstabs',
    name = 'weaponTypes_group_name',
    order = 2,
    permanentStorage = true,
    settings = {
        {
            key = 'axeOneEnabled',
            name = 'axeOneEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'axeTwoEnabled',
            name = 'axeTwoEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'bluntOneEnabled',
            name = 'bluntOneEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'bluntTwoCloseEnabled',
            name = 'bluntTwoCloseEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'bluntTwoWideEnabled',
            name = 'bluntTwoWideEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'longBladeOneEnabled',
            name = 'longBladeOneEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'longBladeTwoEnabled',
            name = 'longBladeTwoEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'shortBladesnabled',
            name = 'shortBladesEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'spearsEnabled',
            name = 'spearsEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'marksmanBowEnabled',
            name = 'marksmanBowEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'marksmanCrossbowEnabled',
            name = 'marksmanCrossbowEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'marksmanThrownEnabled',
            name = 'marksmanThrownEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'h2hEnabled',
            name = 'h2hEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBackstabs_values',
    page = 'Backstabs',
    l10n = 'Backstabs',
    name = 'values_group_name',
    description = "values_group_description",
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'mode',
            name = 'mode_name',
            description = 'mode_description',
            renderer = 'select',
            argument = {
                l10n = "Backstabs",
                items = {
                    "Linear",
                    "Threshold",
                    "Instakill"
                },
            },
            default = "Linear"
        },
        {
            key = 'flatMult',
            name = 'flatMult_name',
            description = 'flatMult_description',
            renderer = 'number',
            integer = false,
            default = 1.5,
        },
        {
            key = 'sneakMult',
            name = 'sneakMult_name',
            description = 'sneakMult_description',
            renderer = 'number',
            integer = false,
            default = 0.05,
        },
        {
            key = 'thresholdStep',
            name = 'thresholdStep_name',
            renderer = 'number',
            integer = true,
            default = 25,
            min = 1
        },
        {
            key = 'npcFov',
            name = 'npcFov_name',
            renderer = 'number',
            integer = false,
            default = 220,
            min = 0,
            max = 360
        },
        {
            key = 'fightingMult',
            name = 'fightingMult_name',
            description = 'fightingMult_description',
            renderer = 'number',
            integer = false,
            default = 0.25,
            min = 0.01
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBackstabs_debug',
    page = 'Backstabs',
    l10n = 'Backstabs',
    name = 'debug_group_name',
    order = 100,
    permanentStorage = true,
    settings = {
        {
            key = 'alwaysBackstab',
            name = 'alwaysBackstab_name',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'printToConsole',
            name = 'printToConsole_name',
            description = 'printToConsole_description',
            renderer = 'checkbox',
            default = false,
        },
    }
}