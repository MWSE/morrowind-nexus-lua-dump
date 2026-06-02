local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')

local l10n = core.l10n('ItemBrowser')

I.Settings.registerRenderer('ItemBrowser/keyBinding', function(value, set)
    local name = type(value) == 'number' and input.getKeyName(value) or l10n('NoKeySet')
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
                                if e.code ~= input.KEY.Escape then
                                    set(e.code)
                                end
                            end),
                        },
                    },
                },
            },
        },
    }
end)

I.Settings.registerPage {
    key = 'ItemBrowser',
    l10n = 'ItemBrowser',
    name = 'settings_page_name',
    description = 'settings_page_desc',
}

I.Settings.registerGroup {
    key = 'Settings/ItemBrowser/1_General',
    page = 'ItemBrowser',
    l10n = 'ItemBrowser',
    name = 'settings_group_general',
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'Enabled',
            renderer = 'checkbox',
            name = 'setting_enabled',
            description = 'setting_enabled_desc',
            default = true,
        },
        {
            key = 'OpenKey',
            renderer = 'ItemBrowser/keyBinding',
            name = 'setting_open_key',
            description = 'setting_open_key_desc',
            default = input.KEY.I,
        },
        {
            key = 'AllowAddToInventory',
            renderer = 'checkbox',
            name = 'setting_allow_add',
            description = 'setting_allow_add_desc',
            default = true,
        },
        {
            key = 'ShowDebugInfo',
            renderer = 'checkbox',
            name = 'setting_show_debug',
            description = 'setting_show_debug_desc',
            default = false,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/ItemBrowser/2_Display',
    page = 'ItemBrowser',
    l10n = 'ItemBrowser',
    name = 'settings_group_display',
    permanentStorage = true,
    order = 20,
    settings = {
        {
            key = 'HideSpecialSymbolItems',
            renderer = 'checkbox',
            name = 'setting_hide_special_symbol_items',
            description = 'setting_hide_special_symbol_items_desc',
            default = true,
        },
    },
}
