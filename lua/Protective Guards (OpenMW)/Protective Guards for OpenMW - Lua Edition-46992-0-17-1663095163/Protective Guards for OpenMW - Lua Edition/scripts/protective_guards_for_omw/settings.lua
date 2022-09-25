local bL = require("scripts/protective_guards_for_omw.blacklistedareas")
local I = require('openmw.interfaces')
local core = require('openmw.core')
I.Settings.registerPage {
    key = 'PGFOMW_KINDI',
    l10n = 'protective_guards_for_omw',
    name = 'settings_modName',
    description = 'settings_modDesc'
}

I.Settings.registerGroup {
    key = 'Settings_PGFOMW_Options_Key_KINDI',
    page = 'PGFOMW_KINDI',
    l10n = 'protective_guards_for_omw',
    name = 'setings_modCategory1_name',
    description = "setings_modCategory1_desc",
    permanentStorage = false,
    settings = {
        {
            key = 'Mod Status',
            renderer = 'checkbox',
            trueLabel = "On",
            falseLabel = "Off",
            name = 'setings_modCategory1_setting1_name',
            description = 'setings_modCategory1_setting1_desc',
            default = true,
            argument = {
                trueLabel = "On",
                falseLabel = "Off",
            }
        },
        {
            key = 'Search Guard Distance Exteriors',
            renderer = 'number',
            name = 'setings_modCategory1_setting2_name',
            description = 'setings_modCategory1_setting2_desc',
            default = 1638
        },
        {
            key = 'Search Guard Distance Interiors',
            renderer = 'number',
            name = 'setings_modCategory1_setting3_name',
            description = 'setings_modCategory1_setting3_desc',
            default = 8192
        },
        {
            key = 'Search Guard In Nearby Adjacent Cells',
            renderer = 'checkbox',
            name = 'setings_modCategory1_setting4_name',
            description = 'setings_modCategory1_setting4_desc',
            default = true
        },
        {
            key = 'Search Guard of Class',
            renderer = 'textLine', --textBox is better but not available yet!
            l10n = "protective_guards_for_omw",
            name = 'setings_modCategory1_setting5_name',
            description = 'setings_modCategory1_setting5_desc',
            default = "Guard, Buoyant Armiger, Ordinator, Ordinator Guard",
        },
    }
}

I.Settings.registerGroup {
    key = 'Settings_PGFOMW_ZBlacklist_Key_KINDI',
    page = 'PGFOMW_KINDI',
    l10n = 'protective_guards_for_omw',
    name = 'setings_modCategory2_name',
    description = (function() 
        local bl = core.l10n("protective_guards_for_omw")("setings_modCategory2_desc") .. "\n------------------------\n"
        for k, v in pairs(bL) do
            bl = bl .. k ..'\n'
        end
        return bl
    end)(),
    permanentStorage = false,
    settings = {}
}

I.Settings.registerGroup {
    key = 'Settings_PGFOMW_ZDebug_Key_KINDI',
    page = 'PGFOMW_KINDI',
    l10n = 'protective_guards_for_omw',
    name = 'setings_modCategory3_name',
    description = "",
    permanentStorage = false,
    settings = {
        {
            key = 'Debug',
            renderer = 'checkbox',
            name = 'setings_modCategory3_setting1_name',
            description = 'setings_modCategory3_setting1_desc',
            default = false
        },
    }
}