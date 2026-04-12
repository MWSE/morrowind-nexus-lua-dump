local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsArrowStick',
    page = 'ArrowStick',
    l10n = 'ArrowStick',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'despawnArrows',
            name = 'despawnArrows_name',
            description = "despawnArrows_desc",
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'stickChance',
            name = 'stickChance_name',
            description = "stickChance_desc",
            renderer = 'number',
            default = 1,
            min = -1,
            max = 1,
        },
        {
            key = 'stickAOEEnchants',
            name = 'stickAOEEnchants_name',
            description = "stickAOEEnchants_desc",
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'stickUnderwater',
            name = 'stickUnderwater_name',
            description = "stickUnderwater_desc",
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'enableScatter',
            name = 'enableScatter_name',
            description = "enableScatter_desc",
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsArrowStick_impactEffects',
    page = 'ArrowStick',
    l10n = 'ArrowStick',
    name = 'impactEffects_groupName',
    description = "impactEffects_groupDesc",
    permanentStorage = true,
    order = 100,
    settings = {
        {
            key = 'impactEffects',
            name = 'impactEffects_name',
            description = "impactEffects_desc",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'checkMaterial',
            name = 'checkMaterial_name',
            description = "checkMaterial_desc",
            renderer = 'checkbox',
            default = false,
        },
    }
}