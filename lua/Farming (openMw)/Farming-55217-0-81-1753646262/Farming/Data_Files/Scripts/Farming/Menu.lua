local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'FarmingSettingsPage',
    l10n = 'FarmingSettings',
    name = 'Farming Settings',
    description = 'Farming Settings.',
}


I.Settings.registerGroup {
    key = 'FarmingSettings1',
    page = 'FarmingSettingsPage',
    l10n = 'FarmingSettings',
    name = 'Edit Farming settings',
    description = 'Settings',
    permanentStorage = true,
    settings = {
        {
            key = 'Pick',
            renderer = 'select',
            name = 'Pick',
            description = 'The Pick (Axe 2H) used to turn the soil. (Config in game)',
            default = "Miner's Pick",
			argument={disabled = false, l10n = 'LocalizationContext', items={"NoDatas"}},
        },
        {
            key = 'DifficultyMode',
            renderer = 'select',
            name = 'Difficulty Mode',
            description = "How hard do you think it is to grow plant?",
            default = "Gardening is my hobby.",
			argument={disabled = false, l10n = 'LocalizationContext', items={"Don't it grow all by itself?","I have a pot of mint in my kitchen.","Gardening is my hobby."}},
        },
	}
}
