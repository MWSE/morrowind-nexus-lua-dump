---@diagnostic disable: missing-fields
---@omw-context menu
local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'RockInTheShoe',
    l10n = 'RockInTheShoe',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsRockInTheShoe_settings',
    page = 'RockInTheShoe',
    l10n = 'RockInTheShoe',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'rockChance',
            name = 'rockChance_name',
            description = "rockChance_desc",
            renderer = 'number',
            default = 500,
        },
        {
            key = 'rockDamage',
            name = 'rockDamage_name',
            renderer = 'number',
            default = 1,
        },
        {
            key = 'rockDamageInterval',
            name = 'rockDamageInterval_name',
            description = "rockDamageInterval_desc",
            renderer = 'number',
            default = 4,
        },
    }
}