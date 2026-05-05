local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerGroup ({
    key = 'SettingsSkyrimLockpicking',
    page = 'SkyrimLockpicking',
    l10n = 'SkyrimLockpicking',
    name = 'Settings',
    permanentStorage = false,
    settings = {
        {
            key = 'DifficultyMultiplier',
            renderer = 'number',
            name = 'Difficulty multiplier',
            description = 'Affets lock and trap difficulty, higher values make lockpicking harder, lower ones make it easier.',
            default = 1,
        },
        
        {
            key = 'SweetspotMultiplier',
            renderer = 'number',
            name = 'Sweetspot angle multiplier',
            description = 'Affects the angle at which you can open the lock.',
            default = 1,
        },
        
        {
            key = 'PartialSpotMultiplier',
            renderer = 'number',
            name = 'Partial spot angle multiplier',
            description = 'Affects the angle at which you can partially open the lock.',
            default = 1,
        },
        
        {
            key = 'ttbMultiplier',
            renderer = 'number',
            name = 'Time to break multiplier',
            description = 'Affets time to break, higher values cause lockpicks to last longer before getting damaged, lower values cause faster damaging.',
            default = 1,
        },
        
        {
            key = 'lockTooComplex',
            renderer = 'checkbox',
            name = 'Lock too complex',
            description = 'Toggles vanilla behavior where locks can be too complex to pick.',
            default = false,
        },
        
        {
            key = 'damageAmount',
            renderer = 'number',
            name = 'Lockpick damage per failed attempt',
            description = "Affects amount of durability is removed when lockpick is damaged.",
            default = 1,
        },
        
        {
            key = 'autopicking',
            renderer = 'checkbox',
            name = 'Automatic lockpicking',
            description = 'If on, activating locked/trapped doors or containers will automatically get the best lockpick/probe and start lockpicking.\nIf turned off, you will need to equip the tools and then activate the door/container to start lockpicking.',
            default = true,
        },
        
        {
            key = 'autopickingOverrideButton',
            renderer = 'inputBinding',
            name = 'Override automatic lockpicking',
            description = 'If on, activating locked/trapped doors or containers will automatically get the best lockpick/probe and start lockpicking.\nIf turned off, you will need to equip the tools and then activate the door/container to start lockpicking.',
            default = 'SkyrimLockpickingOverrideButton',
            argument = {key = 'SkyrimLockpickingOverrideButton', type = 'action'},
        },

        {
            key = 'toggleLockpick',
            renderer = 'checkbox',
            name = 'Enable lockpicking',
            description = 'If turned off disables lockpicking with this mod.',
            default = true,
        },
        {
            key = 'toggleProbe',
            renderer = 'checkbox',
            name = 'Enable disarming',
            description = 'If turned off disables disarming with this mod.',
            default = true,
        },
        {
            key = 'scaledXpGain',
            renderer = 'checkbox',
            name = 'Additional skill gain',
            description = 'Unlocking harder locks/traps gives more skill gain.',
            default = true,
        },
        {
            key = 'scaledXpGainMult',
            renderer = 'number',
            name = 'Additional skill gain multiplier',
            description = 'Multiplies additional skill gain by this value.\n(Does nothing if additional skill gain is off.)',
            default = 1,
        },
    }
})