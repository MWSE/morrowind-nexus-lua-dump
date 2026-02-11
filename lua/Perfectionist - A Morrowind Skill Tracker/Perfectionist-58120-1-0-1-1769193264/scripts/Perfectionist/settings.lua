local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

local l10n = core.l10n('Perfectionist')

I.Settings.registerPage {
    key = 'PerfectionistOptions',
    l10n = 'Perfectionist',
    name = l10n("settings_page_title"),
    description = l10n("settings_page_desc"),
}

I.Settings.registerRenderer('PerfectionistOptions/inputKeySelection', function(value, set)
    local name = 'No Key Set'
    if value then name = input.getKeyName(value) end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = { text = name },
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

I.Settings.registerGroup {
    key = 'Settings/Perfectionist/Options',
    page = 'PerfectionistOptions',
    l10n = 'Perfectionist',
    name = l10n("settings_group_options"),
    permanentStorage = true,
    settings = {
        {
            renderer = 'PerfectionistOptions/inputKeySelection',
            key = 'Hotkey',
            name = l10n("settings_hotkey_name"),
            description = l10n("settings_hotkey_desc"),
            default = input.KEY.L
        },
        {
            key = 'PlaySound',
            renderer = "checkbox",
            name = l10n("settings_sound_name"),
            description = l10n("settings_sound_desc"),
            default = true,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/Perfectionist/Appearance',
    page = 'PerfectionistOptions',
    l10n = 'Perfectionist',
    name = l10n("settings_group_appearance"),
    permanentStorage = true,
    settings = {
        {
            key = 'MaxWidth',
            renderer = 'number',
            name = l10n("settings_width_name"),
            default = 800,
            min = 600, max = 2000, integer = true
        },
        {
            key = 'MaxHeight',
            renderer = 'number',
            name = l10n("settings_height_name"),
            default = 600,
            min = 400, max = 2000, integer = true
        },
        {
            key = 'FontModTitle',
            renderer = 'number',
            name = l10n("settings_font_mod_title"), 
            description = "Size of mod title.",
            default = 17,
            min = 12, max = 35, integer = true
        },
        {
            key = 'FontHeader',
            renderer = 'number',
            name = l10n("settings_font_header_name"),
            default = 19,
            min = 12, max = 40, integer = true
        },
        {
            key = 'FontItem',
            renderer = 'number',
            name = l10n("settings_font_item_name"),
            default = 16,
            min = 10, max = 30, integer = true
        },
    },
}

return