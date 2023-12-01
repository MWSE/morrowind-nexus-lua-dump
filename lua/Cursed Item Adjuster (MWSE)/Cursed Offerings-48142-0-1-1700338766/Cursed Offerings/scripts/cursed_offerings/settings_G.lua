local I = require('openmw.interfaces')
local core = require('openmw.core')

I.Settings.registerGroup {
    key = 'Settings_cursed_offerings_Options_Key_KINDI',
    page = 'cursed_offerings_KINDI',
    l10n = 'cursed_offerings',
    name = 'setings_modCategory1_name',
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = 'Mod Status',
            renderer = 'checkbox',
            name = 'setings_modCategory1_setting1_name',
            description = 'setings_modCategory1_setting1_desc',
            default = true,
            argument = {
                trueLabel = core.getGMST('sYes'),
                falseLabel = core.getGMST('sNo'),
            }
        }, {
        key = 'Summon Type',
        renderer = 'select',
        name = 'setings_modCategory1_setting2_name',
        description = 'setings_modCategory1_setting2_desc',
        l10n = "cursed_offerings",
        default = "settings_name_matching",
        argument = {
            l10n = "cursed_offerings",
            items = {
                "settings_name_matching", "settings_name_randomised", "settings_name_itemvalue", "settings_name_nothing",
                "settings_name_default"
            }
        }

    },
    }
}
