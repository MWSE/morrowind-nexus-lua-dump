-- Zerkish Hotkeys Improved - zhi_settings.lua
-- defines settings for the in-game menu

local core = require('openmw.core')
local I     = require('openmw.interfaces')
local util  = require('openmw.util')

local constants = require('scripts.omw.mwui.constants')

ZHIL10n = core.l10n('ZerkishHotkeysImproved')

I.Settings.registerPage {
    key = 'ZHIPage',
    name = 'mod_page_name',
    description = 'mod_page_desc',
    l10n = 'ZerkishHotkeysImproved',
}

local modifierKeys = {
    --'None', 'Left Shift', 'Left Alt', 'Mouse 3', 'Mouse 4', 'Mouse 5', 'Left Ctrl',
    ZHIL10n('setting_hotbar_modifier_none'),
    ZHIL10n('setting_hotbar_modifier_lshift'),
    ZHIL10n('setting_hotbar_modifier_lalt'),
    ZHIL10n('setting_hotbar_modifier_mouse3'),
    ZHIL10n('setting_hotbar_modifier_mouse4'),
    ZHIL10n('setting_hotbar_modifier_mouse5'),
    ZHIL10n('setting_hotbar_modifier_lctrl'),
}

local MAX_HOTBARS = 6

I.Settings.registerGroup {
    key = 'SettingsZHIAAMain',
    name = 'main_group_name',
    description = 'main_group_desc',
    page = 'ZHIPage',
    l10n = 'ZerkishHotkeysImproved',
    permanentStorage = true,

    settings = {
        {
            key = 'force_standard_ui',
            renderer = 'checkbox',
            name = 'setting_force_standard_ui',
            default = false,
            description = 'setting_force_standard_ui_desc',
        },
        {
            key = 'auto_stance_change',
            renderer = 'checkbox',
            name = 'setting_auto_stance_change',
            default = true,
            description = 'setting_auto_stance_change_desc'
        },
        {
            key = 'enable_stance_queue',
            renderer = 'checkbox',
            name = 'setting_stance_queue',
            default = false,
            description = 'setting_stance_queue_desc'
        },
        {
            name = 'setting_stance_queue_grace',
            key = 'stance_queue_grace',
            renderer = 'number',
            default = 0.60,
            description = ZHIL10n('setting_stance_queue_grace_desc', {min = 0.0, max = 3.0, default = 0.6}),
            argument = {
                integer = false,
                min = 0.0,
                max = 3.0,
            }
        },
        {
            -- Rows/Cols are switched on purpose and it's to do with implementation.
            name = 'setting_inventory_cols',
            key = 'inventory_num_cols',
            renderer = 'number',
            default = 8,
            description = ZHIL10n('setting_inventory_desc', {min=4, max=8}),
            argument = {
                integer = true,
                min = 4,
                max = 8,
            }
        },
        {
            name = 'setting_inventory_rows',
            key = 'inventory_num_rows',
            renderer = 'number',
            default = 8,
            description = ZHIL10n('setting_inventory_desc', {min=6, max=16}),
            argument = {
                integer = true,
                min = 6,
                max = 16,
            }
        },
        {
            name = 'setting_window_position_x',
            key = 'window_anchor_x',
            renderer = 'number',
            default = 0.5,
            description = ZHIL10n('setting_window_position_desc', {min=0.0, max=1.0, default=0.5}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_window_position_y',
            key = 'window_anchor_y',
            renderer = 'number',
            default = 0.5,
            description = ZHIL10n('setting_window_position_desc', {min=0.0, max=1.0, default=0.5}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
    },
}

I.Settings.registerGroup {
    key = 'SettingsZHIHotbar1',
    name = 'setting_hotbar_main_group_name',
    description = 'setting_hotbar_main_group_desc',
    page = 'ZHIPage',
    l10n = 'ZerkishHotkeysImproved',
    permanentStorage = true,
    settings = {
        {
            key = 'hotbar1_enabled',
            renderer = 'checkbox',
            name = 'setting_hotbar_main_enable',
            disabled = true,
            default = true,
            description = 'setting_hotbar_main_enable_desc',
            argument = {
                disabled = true,
            }
        },
        {
            key = 'hotbar1_modifier',
            renderer = 'select',
            name = 'setting_hotbar_modifier',
            default = modifierKeys[1],
            argument = {
                disabled = true,
                items = modifierKeys,
                l10n = 'ZerkishHotkeysImproved',
            },
        },
    }
}

for i=2, MAX_HOTBARS do
    I.Settings.registerGroup {
        key = string.format('SettingsZHIHotbar%d', i),
        name = ZHIL10n('setting_hotbar_group_name', {num=i-1}),
        description = ZHIL10n('setting_hotbar_group_desc', {num=i-1}),
        page = 'ZHIPage',
        l10n = 'ZerkishHotkeysImproved',
        permanentStorage = true,
        settings = {
            {
                key = string.format('hotbar%d_enabled', i),
                --key = 'hotbar2_enabled',
                renderer = 'checkbox',
                name = 'setting_hotbar_enable',
                default = true,
                description = nil,
                argument = {
                    disabled = false,
                }
            },
            {
                key = string.format('hotbar%d_modifier', i),
                --key = 'hotbar2_modifier',
                renderer = 'select',
                name = 'setting_hotbar_modifier',
                default = modifierKeys[i],
                argument = {
                    disabled = false,
                    items = modifierKeys,
                    l10n = 'ZHI_l10n',
                },
            },
        }
    }
end

I.Settings.registerGroup {
    key = 'SettingsZHIAAMisc',
    name = 'setting_misc_group_name',
    description = 'setting_misc_group_desc',
    page = 'ZHIPage',
    l10n = 'ZerkishHotkeysImproved',
    permanentStorage = true,
    settings = {
        {
            key = 'disable_firsttime_notifcation',
            renderer = 'checkbox',
            name = 'setting_misc_disable_firsttime_notification',
            default = false,
            description = "setting_misc_disable_firsttime_notification_desc"
        },
        {
            key = 'extended_tooltips',
            renderer = 'checkbox',
            name = 'setting_misc_extended_tooltips',
            default = false,
            description = "setting_misc_extended_tooltips_desc"
        },
        {
            key = 'enable_ui_compat',
            renderer = 'checkbox',
            name = 'setting_misc_ui_compat',
            default = false,
            description = 'setting_misc_ui_compat_desc'
        },
        {
            key = 'enable_item_cond_check',
            renderer = 'checkbox',
            name = 'setting_misc_item_cond_check',
            default = false,
            description = 'setting_misc_item_cond_check_desc'
        },
    }
}

-- I.Settings.registerGroup({
--     key = 'SettingsZHIAZHotbarHUD',
--     name = 'Hotbar HUD',
--     description = 'Show Hotbar on HUD',
--     page = 'ZHIPage',
--     l10n = 'ZHI_l10n',
--     permanentStorage = true,
--     settings = {
--         {
--             key = 'enable_hotbar_hud',
--             renderer = 'checkbox',
--             name = 'Enable',
--             default = false,
--             description = nil,
--         },
--         {
--             name = 'HotbarHUD Scale',
--             key = 'hotbar_hud_scale',
--             renderer = 'number',
--             default = 1.0,
--             description = 'Min: 0.25, Max 2.0, Default: 1.0',
--             argument = {
--                 integer = false,
--                 min = 0.25,
--                 max = 2.0,
--             }
--         },
--         {
--             key = 'display_condition',
--             renderer = 'checkbox',
--             name = 'Show Item Condition',
--             default = false,
--             description = 'Show the item Condition as a red bar below the icon.'
--         },
--         {
--             key = 'display_charge',
--             renderer = 'checkbox',
--             name = 'Show Item Enchantment Charge',
--             default = false,
--             description = 'Show the enchantment charge as a blue bar below the icon.'
--         },
--         {
--             key = 'display_count',
--             renderer = 'checkbox',
--             name = 'Show Item Count',
--             default = true,
--             description = 'Show the item stack size in the bottom left corner of the icon.'
--         },
--         {
--             key = 'display_spell_castchance',
--             renderer = 'checkbox',
--             name = 'Show Cast Chance',
--             default = false,
--             description = 'Show spell cast chance as a red bar below the icon.'
--         },
--         {
--             key = 'display_key',
--             renderer = 'checkbox',
--             name = 'Show Key Num',
--             default = false,
--             description = 'Show the Key Number in the top right corner of the icon.'
--         },
--         {
--             name = 'Anchor Y',
--             key = 'anchor_y',
--             renderer = 'number',
--             default = 0.975,
--             description = 'Anchor on Y axis. Min: 0.0, Max 1.0, Default: 0.975',
--             argument = {
--                 integer = false,
--                 min = 0.0,
--                 max = 1.0,
--             }
--         },
--         {
--             name = 'Anchor X',
--             key = 'anchor_x',
--             renderer = 'number',
--             default = 0.5,
--             description = 'Anchor on X axis. Min: 0.0, Max 1.0, Default: 0.5',
--             argument = {
--                 integer = false,
--                 min = 0.0,
--                 max = 1.0,
--             }
--         },     
--     }
-- })

I.Settings.registerPage {
    key = 'ZHIPageHotbar',
    name = 'setting_hotbar_hud_page_name',
    description = 'setting_hotbar_hud_page_desc',
    l10n = 'ZerkishHotkeysImproved',
}

I.Settings.registerGroup {
    key = 'SettingsZHIHotbarAAMain',
    name = 'General',
    description = nil,
    page = 'ZHIPageHotbar',
    l10n = 'ZerkishHotkeysImproved',
    permanentStorage = true,
    settings = {
        {
            key = 'enable_hotbar_hud',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_enable',
            default = false,
            description = nil,
        },
        {
            name = 'setting_hotbar_hud_scale',
            key = 'hotbar_hud_scale',
            renderer = 'number',
            default = 1.0,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.25, max=2.0, default=1.0}),
            argument = {
                integer = false,
                min = 0.25,
                max = 2.0,
            }
        },
        {
            name = 'setting_hotbar_hud_position_x',
            key = 'position_x',
            renderer = 'number',
            default = 0.5,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=0.5}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_position_y',
            key = 'position_y',
            renderer = 'number',
            default = 0.995,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=0.995}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_anchor_x',
            key = 'anchor_x',
            renderer = 'number',
            default = 0.5,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=0.5}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_anchor_y',
            key = 'anchor_y',
            renderer = 'number',
            default = 1.0,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=1.0}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_update_interval',
            key = 'update_interval',
            renderer = 'number',
            default = 0.2,
            description = ZHIL10n('setting_hotbar_hud_update_interval_desc', {min=0.0, max=1.0, default=0.2}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            key = 'remove_empty_hotkeys',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_remove_empty_hotkeys',
            default = false,
            description = 'setting_hotbar_hud_remove_empty_hotkeys_desc',
        },        
    }
}

I.Settings.registerGroup {
    key = 'SettingsZHIHotbarAZFeatures',
    name = 'Features',
    description = nil,
    page = 'ZHIPageHotbar',
    l10n = 'ZerkishHotkeysImproved',
    permanentStorage = true,
    settings = {
        {
            key = 'display_condition',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_features_display_cond',
            default = true,
            description = 'setting_hotbar_hud_features_display_cond_desc'
        },
        {
            key = 'display_charge',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_features_display_charge',
            default = true,
            description = 'setting_hotbar_hud_features_display_charge_desc'
        },
        {
            key = 'display_count',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_features_display_count',
            default = true,
            description = 'setting_hotbar_hud_features_display_count_desc'
        },
        {
            key = 'display_spell_castchance',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_features_display_castchance',
            default = true,
            description = 'setting_hotbar_hud_features_display_castchance_desc'
        },
        {
            key = 'display_key',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_features_display_key',
            default = true,
            description = 'setting_hotbar_hud_features_display_key_desc'
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsZHIHotbarBAAppearance',
    name = 'setting_hotbar_hud_appearance_group_name',
    description = 'setting_hotbar_hud_appearance_group_desc',
    page = 'ZHIPageHotbar',
    l10n = 'ZerkishHotkeysImproved',
    permanentStorage = true,
    settings = {
        {
            name = 'setting_hotbar_hud_appearance_icon_size',
            key = 'icon_size',
            renderer = 'number',
            default = 32,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef_int', {min=8, max=64, default=32}),
            argument = {
                integer = true,
                min = 8,
                max = 64,
            }
        },
        {
            key = 'icon_border_enable',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_appearance_icon_border',
            default = true,
            description = 'setting_hotbar_hud_appearance_icon_border_desc'
        },
        {
            key = 'icon_magic_enable',
            renderer = 'checkbox',
            name = 'setting_hotbar_hud_appearance_icon_magic_bg',
            default = true,
            description = 'setting_hotbar_hud_appearance_icon_magic_bg_desc'
        }, 
        {
            name = 'setting_hotbar_hud_appearance_icon_border_size',
            key = 'icon_border_size',
            renderer = 'number',
            default = 40,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef_int', {min=8,max=64,default=40}),
            argument = {
                integer = true,
                min = 8,
                max = 64,
            }
        },
        {
            name = 'setting_hotbar_hud_appearance_hotkey_size',
            key = 'hotkey_size',
            renderer = 'number',
            default = 50,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef_int', {min=8,max=94,default=50}),
            argument = {
                integer = true,
                min = 8,
                max = 94,
            }
        },
        {
            name = 'setting_hotbar_hud_appearance_hotkey_padding',
            key = 'hotkey_padding',
            renderer = 'number',
            default = 4,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef_int', {min=0,max=64,default=4}),
            argument = {
                integer = true,
                min = 0,
                max = 64,
            }
        },
        {
            name = 'setting_hotbar_hud_appearance_hotkey_border',
            key = 'hotkey_border',
            renderer = 'checkbox',
            default = true,
            description = 'setting_hotbar_hud_appearance_hotkey_border_desc',
        },
        {
            name = 'setting_hotbar_hud_appearance_item_count_size',
            key = 'itemcount_text_size',
            renderer = 'number',
            default = 14,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef_int', {min=0,max=64,default=14}),
            argument = {
                integer = true,
                min = 0,
                max = 64,
            }
        },
        {
            name = 'setting_hotbar_hud_appearance_item_count_color',
            key = 'itemcount_text_color',
            renderer = 'color',
            default = constants.normalColor,
            description = ZHIL10n('setting_hotbar_hud_appearance_color_desc', {hex=tostring(constants.normalColor:asHex())}),
        },
        {
            name = 'setting_hotbar_hud_appearance_item_count_anchor_x',
            key = 'itemcount_anchorx',
            renderer = 'number',
            default = 0.875,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=0.875}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_appearance_item_count_anchor_y',
            key = 'itemcount_anchory',
            renderer = 'number',
            default = 0.9,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=0.9}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_apperance_keynum_text_size',
            key = 'keynum_text_size',
            renderer = 'number',
            default = 14,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef_int', {min=0,max=64,default=14}),
            argument = {
                integer = true,
                min = 0,
                max = 64,
            }
        },
        {
            name = 'setting_hotbar_hud_apperance_keynum_text_color',
            key = 'keynum_text_color',
            renderer = 'color',
            default = util.color.rgb(0.65, 0.67, 0.70),
            description = ZHIL10n('setting_hotbar_hud_appearance_color_desc', {hex=tostring(util.color.rgb(0.65, 0.67, 0.70):asHex())}),
        },
        {
            name = 'setting_hotbar_hud_apperance_keynum_anchor_x',
            key = 'keynum_anchorx',
            renderer = 'number',
            default = 0.875,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=0.875}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_apperance_keynum_anchor_y',
            key = 'keynum_anchory',
            renderer = 'number',
            default = 0.1,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef', {min=0.0, max=1.0, default=0.1}),
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'setting_hotbar_hud_appearance_infobar_padding',
            key = 'infobar_padding',
            renderer = 'number',
            default = 1,
            description = ZHIL10n('setting_hotbar_hud_minmaxdef_int', {min=0,max=32,default=1}),
            argument = {
                integer = true,
                min = 0,
                max = 32,
            }
        },
        {
            name = 'setting_hotbar_hud_appearance_infobar_cond_color',
            key = 'infobar_cond_color',
            renderer = 'color',
            default = util.color.rgb(0.90, 0.20, 0.15),
            description = ZHIL10n('setting_hotbar_hud_appearance_color_desc', {hex=tostring(util.color.rgb(0.90, 0.20, 0.15):asHex())}),
        },
        {
            name = 'setting_hotbar_hud_appearance_infobar_charge_color',
            key = 'infobar_charge_color',
            renderer = 'color',
            default = util.color.rgb(0.50, 0.60, 0.90),
            description = ZHIL10n('setting_hotbar_hud_appearance_color_desc', {hex=tostring(util.color.rgb(0.50, 0.60, 0.90):asHex())}),
        },
    }
}

return {
    
}