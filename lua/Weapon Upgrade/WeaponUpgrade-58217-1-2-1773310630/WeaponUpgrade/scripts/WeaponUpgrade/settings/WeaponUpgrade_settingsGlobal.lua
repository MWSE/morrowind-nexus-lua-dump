local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerGroup ({
    key = 'SettingsWeaponUpgrade',
    page = 'WeaponUpgrade',
    l10n = 'WeaponUpgrade',
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
            default = 1,
        },
        
        {
            key = 'MaterialMatching',
            renderer = 'checkbox',
            name = 'Same type material',
            description = 'Requires the weapon to be made out of the same as the upgrade material.',
            default = false,
        },
        
    },
})

I.Settings.registerGroup ({
    key = 'SettingsWeaponUpgradeCap',
    page = 'WeaponUpgrade',
    l10n = 'WeaponUpgrade',
    name = 'Weapon cap settings',
    permanentStorage = false,
    settings = {
        {
            key = 'GlobalCap',
            renderer = 'checkbox',
            name = 'Global armor cap',
            description = 'All weapons have the same max damage cap. If false, each weapon cap can be set separately.\n\nMax damage of a weapon seems to be 255, on 256 it returns to 0.',
            default = false,
        },
        
        {
            key = 'GlobalArmorCap',
            renderer = 'number',
            argument = {max=255},
            name = 'Global Armor Cap Value',
            description = 'All weapons will not exceed this value when upgrading. (For all damage types)',
            default = 80,
        },
        
        {
            key = 'Arrow',
            renderer = 'number',
            name = 'Arrow damage cap',
            argument = {max=255},
            description = 'Maximum damage of arrows after upgrade.',
            default = 15,
        },
        
        {
            key = 'One-Handed Axe',
            renderer = 'number',
            argument = {max=255},
            name = 'One-Handed Axe damage cap',
            description = 'Maximum damage of one-handed axes after upgrade.',
            default = 44,
        },
        
        {
            key = 'Two-Handed Axe',
            renderer = 'number',
            argument = {max=255},
            name = 'Two-Handed Axe damage cap',
            description = 'Maximum damage of two-handed axes after upgrade.',
            default = 80,
        },
        
        {
            key = 'One-Handed Blunt',
            renderer = 'number',
            argument = {max=255},
            name = 'One-Handed Blunt damage cap',
            description = 'Maximum damage of one-handed blunt weapons after upgrade.',
            default = 30,
        },
        
        {
            key = 'Two-Handed Blunt (Close)',
            renderer = 'number',
            argument = {max=255},
            name = 'Two-Handed Blunt (Close) damage cap',
            description = 'Maximum damage of close two-handed blunt weapons (warhammers) after upgrade.',
            default = 70,
        },
        
        {
            key = 'Two-Handed Blunt (Wide)',
            renderer = 'number',
            argument = {max=255},
            name = 'Two-Handed Blunt (Wide) damage cap',
            description = 'Maximum damage of wide two-handed blunt weapons (staves) after upgrade.',
            default = 16,
        },
        
        {
            key = 'Bolt',
            renderer = 'number',
            argument = {max=255},
            name = 'Bolt damage cap',
            description = 'Maximum damage of crossbow bolts after upgrade.',
            default = 6,
        },
        
        {
            key = 'One-Handed Long Blade',
            renderer = 'number',
            argument = {max=255},
            name = 'One-Handed Long Blade damage cap',
            description = 'Maximum damage of one-handed long blades after upgrade.',
            default = 44,
        },
        
        {
            key = 'Two-Handed Long Blade',
            renderer = 'number',
            argument = {max=255},
            name = 'Two-Handed Long Blade damage cap',
            description = 'Maximum damage of two-handed long blades after upgrade.',
            default = 60,
        },
        
        {
            key = 'Bow',
            renderer = 'number',
            argument = {max=255},
            name = 'Bow damage cap',
            description = 'Maximum damage of bows after upgrade.',
            default = 50,
        },
        
        {
            key = 'Crossbow',
            renderer = 'number',
            argument = {max=255},
            name = 'Crossbow damage cap',
            description = 'Maximum damage of crossbows after upgrade.',
            default = 30,
        },
        
        {
            key = 'Thrown Weapon',
            renderer = 'number',
            argument = {max=255},
            name = 'Thrown Weapon damage cap',
            description = 'Maximum damage of thrown weapons after upgrade.',
            default = 12,
        },
        
        {
            key = 'One-Handed Short Blade',
            renderer = 'number',
            argument = {max=255},
            name = 'One-Handed Short Blade damage cap',
            description = 'Maximum damage of one-handed short blades after upgrade.',
            default = 30,
        },
        
        {
            key = 'Two-Handed Spear',
            renderer = 'number',
            argument = {max=255},
            name = 'Two-Handed Spear damage cap',
            description = 'Maximum damage of two-handed spears after upgrade.',
            default = 40,
        },

    },
})