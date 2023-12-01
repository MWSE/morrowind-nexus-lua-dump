local I = require('openmw.interfaces')
local core = require('openmw.core')
local l10n = core.l10n("auto_ammo_equip_omw")


local modInfo = require("scripts.auto_ammo_equip_omw.modInfo")


I.Settings.registerPage {
    key = 'AAEOMW_KINDI',
    l10n = 'auto_ammo_equip_omw',
    name = 'settings_modName',
    description = l10n('settings_modDesc'):format(modInfo.MOD_VERSION)
}

I.Settings.registerGroup {
    key = 'Settings_AAEOMW_Options_Key_KINDI',
    page = 'AAEOMW_KINDI',
    l10n = 'auto_ammo_equip_omw',
    name = 'setings_modCategory1_name',
    description = "",
    permanentStorage = false,
    order = 1,
    settings = {
        {
            key = 'Mod Status',
            renderer = 'checkbox',
            name = 'setings_modCategory1_setting1_name',
            description = 'setings_modCategory1_setting1_desc',
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo"),
            }
        },
        {
            key = 'Notification',
            renderer = 'checkbox',
            name = 'setings_modCategory1_setting2_name',
            description = 'setings_modCategory1_setting2_desc',
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo"),
            }
        },
        {
            key = 'Attack Stance',
            renderer = 'checkbox',
            name = 'setings_modCategory1_setting3_name',
            description = 'setings_modCategory1_setting3_desc',
            default = false,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo"),
            }
        },
        {
            key = 'Equip Priority',
            renderer = 'textLine',
            name = 'setings_modCategory1_setting4_name',
            description = "setings_modCategory1_setting4_desc",
            default = "1,2,3",
            argument = {
            }
        },
    }
}
