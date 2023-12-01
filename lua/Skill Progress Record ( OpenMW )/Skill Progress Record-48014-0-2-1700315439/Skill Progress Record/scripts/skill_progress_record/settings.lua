local I = require("openmw.interfaces")
local modInfo = require("scripts.skill_progress_record.modInfo")
local core = require("openmw.core")
I.Settings.registerPage {
    key = 'SkillProgressRecord_eqnx',
    l10n = 'skill_progress_record',
    name = 'settings_modName',
    description = core.l10n("skill_progress_record")('settings_modDesc'):format(modInfo.MOD_VERSION)
}

I.Settings.registerGroup {
    key = 'Settings_SkillProgressRecord_CONTROLS',
    page = 'SkillProgressRecord_eqnx',
    l10n = 'skill_progress_record',
    name = 'setings_modCategory1_name',
    description = 'setings_modCategory1_desc',
    permanentStorage = true,
    settings = { {
        key = 'Open Record',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting1_name',
        description = 'setings_modCategory1_setting1_desc',
        default = 'z'
    }, {
        key = 'Open Reset',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting6_name',
        description = 'setings_modCategory1_setting6_desc',
        default = 'r'
    }, {
        key = 'Yes',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting7_name',
        description = 'setings_modCategory1_setting7_desc',
        default = 'y'
    }, {
        key = 'No',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting8_name',
        description = 'setings_modCategory1_setting8_desc',
        default = 'n'
    }, {
        key = 'textSize',
        renderer = 'number',
        name = 'setings_modCategory1_setting9_name',
        description = 'setings_modCategory1_setting9_desc',
        default = 16
    } }
}
