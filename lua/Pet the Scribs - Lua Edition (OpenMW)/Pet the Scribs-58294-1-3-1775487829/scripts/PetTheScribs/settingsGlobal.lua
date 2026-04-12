local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = 'SettingsPetTheScribs_settings',
    page = 'PetTheScribs',
    l10n = 'PetTheScribs',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'minJelly',
            name = 'minJelly_name',
            renderer = 'number',
            default = 1,
            min = 0,
        },
        {
            key = 'maxJelly',
            name = 'maxJelly_name',
            renderer = 'number',
            default = 2,
            min = 0,
        },
        {
            key = 'jellyCooldown',
            name = 'jellyCooldown_name',
            renderer = 'number',
            default = 6,
            min = 1,
        },
        {
            key = 'diseaseChance',
            name = 'diseaseChance_name',
            description = 'diseaseChance_desc',
            renderer = 'number',
            default = .5,
            min = 0,
            max = 1,
        },
        {
            key = 'blightChance',
            name = 'blightChance_name',
            description = 'blightChance_desc',
            renderer = 'number',
            default = .5,
            min = 0,
            max = 1,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPetTheScribs_other',
    page = 'PetTheScribs',
    l10n = 'PetTheScribs',
    name = 'other_groupName',
    permanentStorage = true,
    order = 100,
    settings = {
        {
            key = 'enableMessages',
            name = 'enableMessages_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}