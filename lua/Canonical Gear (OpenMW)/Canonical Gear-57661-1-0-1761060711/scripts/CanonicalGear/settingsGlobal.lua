local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsCanonicalGear_toggles',
    page = 'CanonicalGear',
    l10n = 'CanonicalGear',
    name = 'toggles_group_name',
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'wizardStaffEnabled',
            name = 'wizardStaffsEnabled_name',
            description = 'wizardStaffsEnabled_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'wizardStaffForceEquip',
            name = 'wizardStaffForceEquip_name',
            description = 'wizardStaffForceEquip_description',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'mouthStaffEnabled',
            name = 'mouthStaffEnabled_name',
            description = 'mouthStaffEnabled_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'mouthStaffForceEquip',
            name = 'mouthStaffForceEquip_name',
            description = 'mouthStaffForceEquip_description',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'kingsOathEnabled',
            name = 'kingsOathEnabled_name',
            description = 'kingsOathEnabled_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'dorisasBooksEnabled',
            name = 'dorisasBooksEnabled_name',
            description = 'dorisasBooksEnabled_description',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsCanonicalGear_debug',
    page = 'CanonicalGear',
    l10n = 'CanonicalGear',
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