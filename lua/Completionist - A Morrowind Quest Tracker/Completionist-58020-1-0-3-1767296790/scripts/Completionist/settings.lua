local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

-- Load the 'Completionist' localization context
local l10n = core.l10n('Completionist')

-- 1. Register Page
I.Settings.registerPage {
    key = 'CompletionistOptions',
    l10n = 'Completionist',
    name = l10n("settings_page_title"),
    description = l10n("settings_page_desc"),
}

-- 2. Register Renderer (Custom Key Binder)
I.Settings.registerRenderer('CompletionistOptions/inputKeySelection', function(value, set)
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

-- 3. Register Settings Group: General Options
I.Settings.registerGroup {
    key = 'Settings/Completionist/Options',
    page = 'CompletionistOptions',
    l10n = 'Completionist',
    name = l10n("settings_group_options"),
    permanentStorage = true,
    settings = {
        {
            renderer = 'CompletionistOptions/inputKeySelection',
            key = 'Hotkey',
            name = l10n("settings_hotkey_name"),
            description = l10n("settings_hotkey_desc"),
            default = input.KEY.K
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

-- 4. Register Settings Group: Appearance
I.Settings.registerGroup {
    key = 'Settings/Completionist/Appearance',
    page = 'CompletionistOptions',
    l10n = 'Completionist',
    name = l10n("settings_group_appearance"),
    permanentStorage = true,
    settings = {
        {
            key = 'MaxWidth',
            renderer = 'number',
            name = l10n("settings_width_name"),
            default = 950,
            min = 600, max = 2000, integer = true
        },
        {
            key = 'MaxHeight',
            renderer = 'number',
            name = l10n("settings_height_name"),
            default = 1000,
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
            description = l10n("settings_font_header_desc"),
            default = 19,
            min = 12, max = 40, integer = true
        },
        {
            key = 'FontItem',
            renderer = 'number',
            name = l10n("settings_font_item_name"),
            description = l10n("settings_font_item_desc"),
            default = 16,
            min = 10, max = 30, integer = true
        },
        {
            key = 'FontDesc',
            renderer = 'number',
            name = l10n("settings_font_desc_name"),
            description = l10n("settings_font_desc_desc"),
            default = 14,
            min = 10, max = 30, integer = true
        },
    },
}

return