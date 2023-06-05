
local I = require('openmw.interfaces')
I.Settings.registerPage {
    key = 'SkillProgressRecord_KINDI',
    l10n = 'skill_progress_record',
    name = 'settings_modName',
    description = 'settings_modDesc'
}
I.Settings.registerGroup {
    key = 'Settings_SkillProgressRecord_ASWITCH_GAME_KINDI',
    page = 'SkillProgressRecord_KINDI',
    l10n = 'skill_progress_record',
    name = 'setings_choose_game_name',
    description = 'setings_choose_game_desc',
    permanentStorage = true,
    settings = {{
        key = 'Game',
        renderer = 'select',
        name = 'setings_choose_game_setting1_name',
        description = 'setings_choose_game_setting1_desc',
        default = "Morrowind",
        argument = {
            l10n = 'skill_progress_record',
            items = {
                "Morrowind", "Starwind"
            }
        }

    },
}
}
I.Settings.registerGroup {
    key = 'Settings_SkillProgressRecord_CONTROLS_KINDI',
    page = 'SkillProgressRecord_KINDI',
    l10n = 'skill_progress_record',
    name = 'setings_modCategory1_name',
    description = 'setings_modCategory1_desc',
    permanentStorage = false,
    settings = {{
        key = 'Open Record',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting1_name',
        description = 'setings_modCategory1_setting1_desc',
        default = 'Z'
    }, {
        key = 'Close Record',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting2_name',
        description = 'setings_modCategory1_setting2_desc',
        default = 'Inventory'
    }, {
        key = 'Navigate Left',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting3_name',
        description = 'setings_modCategory1_setting3_desc',
        default = 'MoveLeft'
    }, {
        key = 'Navigate Right',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting4_name',
        description = 'setings_modCategory1_setting4_desc',
        default = 'MoveRight'
    }, {
        key = 'Open Info',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting5_name',
        description = 'setings_modCategory1_setting5_desc',
        default = 'ToggleWeapon'
    }, {
        key = 'Open Reset',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting6_name',
        description = 'setings_modCategory1_setting6_desc',
        default = 'ToggleSpell'
    }, {
        key = 'Yes',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting7_name',
        description = 'setings_modCategory1_setting7_desc',
        default = 'Y'
    }, {
        key = 'No',
        renderer = 'textLine',
        name = 'setings_modCategory1_setting8_name',
        description = 'setings_modCategory1_setting8_desc',
        default = 'N'
    }}
}

I.Settings.registerGroup {
    key = 'Settings_SkillProgressRecord_Reference_Action_KINDI',
    page = 'SkillProgressRecord_KINDI',
    l10n = 'skill_progress_record',
    name = 'setings_modCategory2_name',
    description = (function()
        local input = require 'openmw.input'
        local refcode = ""
        local actions = {}
        for action in pairs(input.ACTION) do 
            table.insert(actions, action)
        end
        table.sort(actions)
        for code, action in pairs(actions) do
            refcode = refcode .. string.format("%s\n", action, code)
        end
        return refcode
    end)(),
    permanentStorage = false,
    settings = {}
}

I.Settings.registerGroup {
    key = 'Settings_SkillProgressRecord_Reference_Key_KINDI',
    page = 'SkillProgressRecord_KINDI',
    l10n = 'skill_progress_record',
    name = 'setings_modCategory3_name',
    description = (function()
        local input = require 'openmw.input'
        local refcode = ""
        local keys = {}
        for key, code in pairs(input.KEY) do 
            keys[code] =  key
        end
        for code, key in pairs(keys) do
            refcode = refcode .. string.format("%s\n", key, code)
        end
        return refcode
    end)(),
    permanentStorage = false,
    settings = {}
}
