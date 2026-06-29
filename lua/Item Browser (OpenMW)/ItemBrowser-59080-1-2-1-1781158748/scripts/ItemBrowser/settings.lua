local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local storage = require('openmw.storage')

local l10n = core.l10n('ItemBrowser')
local FAVORITES_SETTINGS_SECTION = 'Settings/ItemBrowser/3_Favorites'
local FAVORITES_DATA_SECTION = 'ItemBrowser/Favorites'

local function favoritesData()
    return storage.playerSection(FAVORITES_DATA_SECTION)
end

local function textBox(text, onClick)
    local box = {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = { text = text },
                    },
                },
            },
        },
    }
    if onClick then
        box.events = {
            mouseClick = async:callback(onClick),
        }
    end
    return box
end

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

I.Settings.registerRenderer('ItemBrowser/clearFavorites', function(value, set)
    return textBox(l10n('button_clear_favorites'), function()
        favoritesData():set('Favorites', {})
        favoritesData():set('FavoritesRevision', (favoritesData():get('FavoritesRevision') or 0) + 1)
        set((tonumber(value) or 0) + 1)
    end)
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
    key = FAVORITES_SETTINGS_SECTION,
    page = 'ItemBrowser',
    l10n = 'ItemBrowser',
    name = 'settings_group_favorites',
    permanentStorage = true,
    order = 30,
    settings = {
        {
            key = 'ClearFavorites',
            renderer = 'ItemBrowser/clearFavorites',
            name = 'setting_clear_favorites',
            description = 'setting_clear_favorites_desc',
            default = 0,
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
