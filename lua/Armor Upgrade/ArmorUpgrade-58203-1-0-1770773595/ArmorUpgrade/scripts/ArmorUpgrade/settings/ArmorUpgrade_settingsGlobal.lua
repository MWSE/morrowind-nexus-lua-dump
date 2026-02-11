local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerGroup ({
    key = 'SettingsArmorUpgrade',
    page = 'ArmorUpgrade',
    l10n = 'ArmorUpgrade',
    name = 'Main settings',
    permanentStorage = false,
    settings = {
        {
            key = 'InfiniteUpgrades',
            renderer = 'checkbox',
            name = 'Infinite upgrades',
            description = 'Allows upgrading armor indefinetly. By default armor can be upgraded only once. Turning this on may contribute to save bloat and watch out not to turn your light armor into heavy armor.',
            default = false,
        },
        
        {
            key = 'IgnoreWeight',
            renderer = 'checkbox',
            name = 'Ignore weight',
            description = 'Ignores material weight penalty, armor weight will not change after upgrade. Useful with Infinite Upgrades, so your light armor will not turn to medium armor if it gets too heavy.',
            default = false,
        },
        
        {
            key = 'IgnoreDifficulty',
            renderer = 'checkbox',
            name = 'Ignore material difficulty',
            description = 'Ignores minimum armorer skill required to work with materials.',
            default = false,
        },
        
        {
            key = 'AlwaysSucceed',
            renderer = 'checkbox',
            name = 'Always Succeed',
            description = 'Upgrading armor always succeeds.',
            default = false,
        },
        
        {
            key = 'MaxMaterials',
            renderer = 'number',
            name = 'Maximum materials per upgrade',
            description = 'Limits maximum amount of materials you can use when upgrading armor.',
            default = 4,
        },
        
        {
            key = 'LightCap',
            renderer = 'number',
            name = 'Light armor AR cap',
            description = 'Maximum armor rating you can reach while upgrading armor piece.',
            default = 50,
        },
        
        {
            key = 'MediumCap',
            renderer = 'number',
            name = 'Medium armor AR cap',
            description = 'Maximum armor rating you can reach while upgrading armor piece.',
            default = 60,
        },
        
        {
            key = 'HeavyCap',
            renderer = 'number',
            name = 'Heavy armor AR cap',
            description = 'Maximum armor rating you can reach while upgrading armor piece.',
            default = 70,
        },
    },
})