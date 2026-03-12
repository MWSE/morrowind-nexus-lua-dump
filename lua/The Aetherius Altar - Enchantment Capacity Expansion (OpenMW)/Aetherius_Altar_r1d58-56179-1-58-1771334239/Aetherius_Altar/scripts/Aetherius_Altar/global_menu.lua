local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsAetheriusAltar',
    page = 'AetheriusAltarPage',
    l10n = 'AetheriusAltar',
    name = 'Aetherius Altar Settings',
    description = 'Configuration of the enchantment points gained through the Aetherius Altar.',
    permanentStorage = true,
    settings = {
        {
            key = 'MaxMult',
            renderer = 'number',
            name = 'Max Multiplier',
            description = 'The maximum an items enchantment capacity can increase by, in one altar improvement.',
            default = 13,
			argument = {
                disabled = false,
                integer = false,
                min = 1,
                max = 1000,
            }
        },
        {
            key = 'SoulPointsWeight',
            renderer = 'number',
            name = 'Soul Points Weight',
            description = 'Determines how many soul points are needed per enchantment cap increase. ie. a larger value compared to the default weight means more soul points (and therefore souls) are needed to achieve the same enchantment cap increase',
            default = "640",
			argument = {
                disabled = false,
                integer = true,
                min = 1,
                max = 2000,
            }
        },
        {
            key = 'RemoveImprLimit',
            renderer = 'checkbox',
            name = 'Remove improvement per item Limit',
            description = 'When set to yes allows an item to be repeatedly put into the Altar, default is set to no to avoid extremely overpowered items.',
            default = false,
			argument = {
                disabled = false,
            }
        },

   	},
}