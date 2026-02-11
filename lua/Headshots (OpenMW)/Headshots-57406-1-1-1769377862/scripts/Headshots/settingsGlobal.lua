local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsHeadshots_values',
    page = 'Headshots',
    l10n = 'Headshots',
    name = 'values_group_name',
    description = "values_group_description",
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'headHeight',
            name = 'headHeight_name',
            description = 'headHeight_description',
            renderer = 'number',
            integer = false,
            default = 0.85,
            min = 0,
            max = 1
        },
        -- River Odai is about 1000 units wide in the vanilla Balmora (where the stone paths are)
        {
            key = 'distanceMin',
            name = 'distanceMin_name',
            description = 'distanceMin_description',
            renderer = 'number',
            integer = true,
            default = 1000,
            min = 0
        },
        {
            key = 'mode',
            name = 'mode_name',
            description = 'mode_description',
            renderer = 'select',
            argument = {
                l10n = "Headshots",
                items = {
                    "Linear",
                    "Threshold",
                    -- TODO
                    -- "No helmet instakill",
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
            key = 'marksmanMult',
            name = 'marksmanMult_name',
            description = 'marksmanMult_description',
            renderer = 'number',
            integer = false,
            default = 0.01,
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
            key = 'damagePerUnit',
            name = 'damagePerUnit_name',
            description = 'damagePerUnit_description',
            renderer = 'number',
            integer = false,
            default = 1,
            min = 0
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsHeadshots_weaponTypes',
    page = 'Headshots',
    l10n = 'Headshots',
    name = 'weaponTypes_group_name',
    order = 2,
    permanentStorage = true,
    settings = {
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
    }
}

I.Settings.registerGroup {
    key = 'SettingsHeadshots_debug',
    page = 'Headshots',
    l10n = 'Headshots',
    name = 'debug_group_name',
    order = 100,
    permanentStorage = true,
    settings = {
        {
            key = 'printToConsole',
            name = 'printToConsole_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}