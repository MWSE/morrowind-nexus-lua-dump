local core = require("openmw.core")
local I = require("openmw.interfaces")
local l10n = core.l10n('OpenMWQuestMenu')
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

I.Settings.registerPage {
    key = 'OpenMWQuestMenu',
    l10n = 'OpenMWQuestMenu',
    name = l10n("settings_page_title"),
    description = l10n("settings_page_desc"),
}

-- inputKeySelection by Pharis (taken from PerfectPlacement)
I.Settings.registerRenderer('OpenMWQuestMenu/inputKeySelection', function(value, set)
    local name = 'No Key Set'
    if value then
        name = input.getKeyName(value)
    end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = name,
                        },
                        events = {
                            keyPress = async:callback(function(e)
                                if e.code == input.KEY.Escape then return end
                                set(e.code)
                            end),
                        },
                    },
                },
            },
        },
    }
end)

local directions = { 'up', 'right', 'down', 'left', 'none' }

I.Settings.registerGroup {
    key = 'Settings/OpenMWQuestMenu/1_Options',
    page = 'OpenMWQuestMenu',
    l10n = 'OpenMWQuestMenu',
    name = l10n("settings_group_options"),
    permanentStorage = true,
    settings = {
        {
            renderer = 'OpenMWQuestMenu/inputKeySelection',
            key = 'OpenMenu',
            name = l10n("settings_open_menu_name"),
            description = l10n("settings_open_menu_desc"),
            default = input.KEY.X
        },
        {
            key = 'OpenMenuController',
            renderer = 'select',
            name = l10n("settings_open_menu_controller_name"),
            description = l10n("settings_open_menu_controller_desc"),
            default = "none",
            argument = {
                l10n = 'OpenMWQuestMenu',
                items = directions
            }
        },
        {
            key = 'PlaySound',
            renderer = "checkbox",
            name = l10n("settings_play_sound_name"),
            description = l10n("settings_play_sound_desc"),
            default = true,
        },
        {
            key = 'Debugging',
            renderer = "checkbox",
            name = l10n("settings_debugging_name"),
            description = l10n("settings_debugging_desc"),
            default = false,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/OpenMWQuestMenu/2_Customization',
    page = 'OpenMWQuestMenu',
    l10n = 'OpenMWQuestMenu',
    name = l10n("settings_group_customization_name"),
    description = l10n("settings_group_customization_desc"),
    permanentStorage = true,
    settings = {
        {
            key = 'MaxWidth',
            renderer = 'number',
            name = l10n("settings_max_width_name"),
            description = l10n("settings_max_width_desc"),
            default = 850,
        },
        {
            key = 'MaxHeight',
            renderer = 'number',
            name = l10n("settings_max_height_name"),
            description = l10n("settings_max_height_desc"),
            default = 1000,
        },
        {
            key = 'ShowLessQuests',
            renderer = "checkbox",
            name = l10n("settings_less_quests_name"),
            description = l10n("settings_less_quests_desc"),
            default = false,
        },
        {
            key = 'MaxIconSize',
            renderer = 'number',
            name = l10n("settings_max_icon_size_name"),
            description = l10n("settings_max_icon_size_desc"),
            default = 100,
        },
        {
            key = 'TextSize',
            renderer = 'number',
            name = l10n("settings_text_size_name"),
            description = l10n("settings_text_size_desc"),
            default = 15,
        },
        {
            key = 'FWidth',
            renderer = 'number',
            name = l10n("settings_f_width_name"),
            description = l10n("settings_f_width_desc"),
            default = 300,
        },
        {
            key = 'FIconSize',
            renderer = 'number',
            name = l10n("settings_f_icon_size_name"),
            description = l10n("settings_f_icon_size_desc"),
            default = 30,
        },
        {
            key = 'FHeadlineSize',
            renderer = 'number',
            name = l10n("settings_f_headline_size_name"),
            description = l10n("settings_f_headline_size_desc"),
            default = 14,
        },
        {
            key = 'FTextSize',
            renderer = 'number',
            name = l10n("settings_f_text_size_name"),
            description = l10n("settings_f_text_size_desc"),
            default = 12,
        },
        {
            key = 'FPosX',
            renderer = 'number',
            name = l10n("settings_f_pos_x_name"),
            description = l10n("settings_f_pos_x_desc"),
            default = 10,
        },
        {
            key = 'FPosY',
            renderer = 'number',
            name = l10n("settings_f_pos_y_name"),
            description = l10n("settings_f_pos_y_desc"),
            default = 10,
        },
    },
}

return
