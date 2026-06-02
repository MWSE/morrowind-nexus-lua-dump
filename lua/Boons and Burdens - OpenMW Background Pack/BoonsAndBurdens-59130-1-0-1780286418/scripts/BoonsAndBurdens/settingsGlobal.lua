---@omw-context global
---@diagnostic disable: missing-fields
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsBoonsAndBurdens_insecureConjurer',
    page = 'BoonsAndBurdens',
    l10n = 'BoonsAndBurdens',
    name = 'insecureConjurer_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'disobeyChance',
            name = 'disobeyChance_name',
            renderer = 'number',
            integer = false,
            default = 20,
        },
    }
}
