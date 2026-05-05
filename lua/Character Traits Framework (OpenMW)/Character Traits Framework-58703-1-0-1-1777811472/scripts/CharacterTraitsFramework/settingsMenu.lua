local I = require("openmw.interfaces")

I.Settings.registerPage {
    key = 'CharacterTraitsFramework',
    l10n = 'CharacterTraitsFramework',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsCharacterTraitsFramework',
    page = 'CharacterTraitsFramework',
    l10n = 'CharacterTraitsFramework',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'displayNilTraits',
            name = 'displayNilTraits_name',
            description = 'displayNilTraits_desc',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'ignoreRequirements',
            name = 'ignoreRequirements_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}
