local core = require("openmw.core")
local I = require("openmw.interfaces")
local l10n = core.l10n('OpenMWQuestMenu')

I.Settings.registerPage {
    key = 'OpenMWQuestMenuPage',
    l10n = 'OpenMWQuestMenu',
    name = l10n("settings_page_title"),
    description = l10n("settings_page_desc"),
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestMenuControls',
    page = 'OpenMWQuestMenuPage',
    l10n = 'OpenMWQuestMenu',
    name = l10n("settings_group_options"),
    permanentStorage = true,
    settings = {
        {
            key = 'OpenMenu',
            renderer = 'textLine',
            name = l10n("settings_open_menu_name"),
            description = l10n("settings_open_menu_desc"),
            default = 'x',
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
    key = 'SettingsPlayerOpenMWQuestMenuCustomization',
    page = 'OpenMWQuestMenuPage',
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
