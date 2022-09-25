local I = require('openmw.interfaces')
local core = require('openmw.core')
local types = require('openmw.types')
local bL = require('scripts.pursuit_for_omw.blacklistOptional')
I.Settings.registerGroup {
    key = 'Settings_Pursuit_Options_Key_KINDI',
    page = 'Pursuit_KINDI',
    l10n = 'pursuit_for_omw',
    name = 'setings_modCategory1_name',
    description = "setings_modCategory1_desc",
    permanentStorage = false,
    settings = {{
        key = 'Mod Status',
        renderer = 'checkbox',
        name = 'setings_modCategory1_setting1_name',
        description = 'setings_modCategory1_setting1_desc',
        default = true,
        argument = {
            trueLabel = "On",
            falseLabel = "Off",
        }
    }, {
        key = 'Pursue Time',
        renderer = 'number',
        name = 'setings_modCategory1_setting2_name',
        description = 'setings_modCategory1_setting2_desc',
        default = 15
    },
}
}
I.Settings.registerGroup {
    key = 'Settings_Pursuit_ZBlacklist_Key_KINDI',
    page = 'Pursuit_KINDI',
    l10n = 'pursuit_for_omw',
    name = 'setings_modCategory2_name',
    description = (function() 
        local header = core.l10n("pursuit_for_omw")("setings_modCategory2_desc").."\n------------------\n"
        for actor in pairs(bL) do
            header = header .. string.format("%s", actor) .. "\n"
        end
        
        return header
    end)(),
    permanentStorage = false,
    settings = {}
}
I.Settings.registerGroup {
    key = 'Settings_Pursuit_ZDebug_Key_KINDI',
    page = 'Pursuit_KINDI',
    l10n = 'pursuit_for_omw',
    name = 'setings_modCategory3_name',
    description = '',
    permanentStorage = false,
    settings = {
        {
            key = 'Debug',
            renderer = 'checkbox',
            name = 'setings_modCategory3_setting1_name',
            description = 'setings_modCategory3_setting1_desc',
            default = true,
    }
}
}