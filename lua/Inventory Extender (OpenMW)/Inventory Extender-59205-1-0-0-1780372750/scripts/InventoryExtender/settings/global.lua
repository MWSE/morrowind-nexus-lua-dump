local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'Settings/InventoryExtender/6_Gameplay',
    page = 'InventoryExtender',
    l10n = 'InventoryExtender',
    name = 'ConfigCategoryGameplay',
    permanentStorage = true,
    settings = {
        {
            key = 'b_SoulGemValueRebalance',
            renderer = 'checkbox',
            name = 'SoulGemValueRebalance',
            description = 'SoulGemValueRebalanceDesc',
            default = true,
        },
    },
}