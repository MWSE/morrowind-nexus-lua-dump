-- Zerkish Hotkeys Improved - zhi_settings.lua
-- defines settings for the in-game menu

local I     = require('openmw.interfaces')
local util  = require('openmw.util')

local constants = require('scripts.omw.mwui.constants')

I.Settings.registerPage {
    key = 'ZHIPage',
    name = 'Zerkish Hotkeys Improved',
    description = 'Improved Hotkeys for OpenMW',
    l10n = 'ZHI_l10n',
}

local modifierKeys = {
    'None', 'Left Shift', 'Left Alt', 'Mouse 3', 'Mouse 4', 'Mouse 5', 'Left Ctrl',
}

local MAX_HOTBARS = 6

I.Settings.registerGroup {
    key = 'SettingsZHIAAMain',
    name = 'Main',
    description = 'Main Settings',
    page = 'ZHIPage',
    l10n = 'ZHI_l10n',
    permanentStorage = true,

    settings = {
        {
            key = 'force_standard_ui',
            renderer = 'checkbox',
            name = 'Show Default QuickMenu Once',
            default = false,
            description = 'This will automatically be turned off once the QuickKey menu has been shown once, and is meant to be used to clear the default QuickKeys.\nDisabled with UI Overhaul Compatibility Mode On.',
        },
        {
            key = 'auto_stance_change',
            renderer = 'checkbox',
            name = 'Auto Stance Change',
            default = true,
            description = 'Automatically switch stance when hotkey is pressed (vanilla).'
        },
        {
            key = 'enable_stance_queue',
            renderer = 'checkbox',
            name = 'Stance Queue (Experimental)',
            default = false,
            description = 'Gives a small grace period to press a hotkey before current animation is completed.\nApplies to ToggleWeapon/ToggleSpell as well. (Default: Off)'
        },
        {
            name = 'Stance Queue Grace Period',
            key = 'stance_queue_grace',
            renderer = 'number',
            default = 0.60,
            description = 'Time in Seconds that stance changes are allowed to be queued.\nMin: 0.0, Max: 4.0, Default: 0.45',
            argument = {
                integer = false,
                min = 0.0,
                max = 3.0,
            }
        },
        {
            name = 'Inventory Columns',
            key = 'inventory_num_rows',
            renderer = 'number',
            default = 8,
            description = 'Min: 6, Max: 16',
            argument = {
                integer = true,
                min = 6,
                max = 16,
            }
        },
        {
            name = 'Inventory Rows',
            key = 'inventory_num_cols',
            renderer = 'number',
            default = 8,
            description = 'Min: 4, Max: 8',
            argument = {
                integer = true,
                min = 4,
                max = 8,
            }
        },
        {
            name = 'Window Anchor X',
            key = 'window_anchor_x',
            renderer = 'number',
            default = 0.5,
            description = 'Min: 0.0, Max: 1.0, Default: 0.5',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Window Anchor Y',
            key = 'window_anchor_y',
            renderer = 'number',
            default = 0.5,
            description = 'Min: 0.0, Max: 1.0, Default: 0.5',
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
    name = 'Main Hotbar',
    description = 'Main Hotbar Settings',
    page = 'ZHIPage',
    l10n = 'ZHI_l10n',
    permanentStorage = true,
    settings = {
        {
            key = 'hotbar1_enabled',
            renderer = 'checkbox',
            name = 'Enable',
            disabled = true,
            default = true,
            description = "Main hotbar is always enabled.",
            argument = {
                disabled = true,
            }
        },
        {
            key = 'hotbar1_modifier',
            renderer = 'select',
            name = 'Modifier Key',
            default = modifierKeys[1],
            argument = {
                disabled = true,
                items = modifierKeys,
                l10n = 'ZHI_l10n',
            },
        },
    }
}

for i=2, MAX_HOTBARS do
    I.Settings.registerGroup {
        key = string.format('SettingsZHIHotbar%d', i),
        name = string.format('Extra Hotbar %d', i - 1),
        description = string.format('Hotbar %d Settings', i - 1),
        page = 'ZHIPage',
        l10n = 'ZHI_l10n',
        permanentStorage = true,
        settings = {
            {
                key = string.format('hotbar%d_enabled', i),
                --key = 'hotbar2_enabled',
                renderer = 'checkbox',
                name = 'Enable',
                default = true,
                description = "",
                argument = {
                    disabled = false,
                }
            },
            {
                key = string.format('hotbar%d_modifier', i), 
                --key = 'hotbar2_modifier',
                renderer = 'select',
                name = 'Modifier Key',
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
    name = 'Miscellaneous',
    description = 'Miscellaneous Settings',
    page = 'ZHIPage',
    l10n = 'ZHI_l10n',
    permanentStorage = true,
    settings = {
        {
            key = 'disable_firsttime_notifcation',
            renderer = 'checkbox',
            name = 'Disable First Time Notification',
            default = false,
            description = "Disable the first time message when loading a game that hasn't opened the QuickKeys Menu since install. WARNING Applies to all saves."
        },
        {
            key = 'extended_tooltips',
            renderer = 'checkbox',
            name = 'Show Extra Tooltip Info',
            default = false,
            description = "This will show additional information in tooltips. Mainly for mod developers.\nWarning this will contain spoilers."
        },
        {
            key = 'enable_ui_compat',
            renderer = 'checkbox',
            name = 'Compatibility Mode',
            default = false,
            description = 'This will disable the ability to toggle the original QuickKeys Menu.\nNOTE: Takes effect after reloading/restarting.'
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
    name = 'Zerkish Hotkeys Improved HUD',
    description = 'Hotbar HUD for ZHI',
    l10n = 'ZHI_l10n',
}

I.Settings.registerGroup {
    key = 'SettingsZHIHotbarAAMain',
    name = 'General',
    description = nil,
    page = 'ZHIPageHotbar',
    l10n = 'ZHI_l10n',
    permanentStorage = true,
    settings = {
        {
            key = 'enable_hotbar_hud',
            renderer = 'checkbox',
            name = 'Enable Hotbar',
            default = false,
            description = nil,
        },
        {
            name = 'HotbarHUD Scale',
            key = 'hotbar_hud_scale',
            renderer = 'number',
            default = 1.0,
            description = 'Min: 0.25, Max 2.0, Default: 1.0',
            argument = {
                integer = false,
                min = 0.25,
                max = 2.0,
            }
        },
        {
            name = 'Position X',
            key = 'position_x',
            renderer = 'number',
            default = 0.5,
            description = 'Position on X axis. Min: 0.0, Max 1.0, Default: 0.5',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Position Y',
            key = 'position_y',
            renderer = 'number',
            default = 0.995,
            description = 'Position on Y axis. Min: 0.0, Max 1.0, Default: 0.995',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Anchor X',
            key = 'anchor_x',
            renderer = 'number',
            default = 0.5,
            description = 'Anchor on X axis. Min: 0.0, Max 1.0, Default: 0.5',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Anchor Y',
            key = 'anchor_y',
            renderer = 'number',
            default = 1.0,
            description = 'Anchor on Y axis. Min: 0.0, Max 1.0, Default: 1.0',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Update Interval (Advanced)',
            key = 'update_interval',
            renderer = 'number',
            default = 0.2,
            description = 'How often to update the hotbar, in seconds.\nMin: 0.0, Max: 1.0, Default: 0.2\nLower values cost more performance.',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            key = 'remove_empty_hotkeys',
            renderer = 'checkbox',
            name = 'Remove Empty Hotkeys',
            default = false,
            description = 'Pack hotbar and don\'t show empty keys.',
        },        
    }
}

I.Settings.registerGroup {
    key = 'SettingsZHIHotbarAZFeatures',
    name = 'Features',
    description = 'Main',
    page = 'ZHIPageHotbar',
    l10n = 'ZHI_l10n',
    permanentStorage = true,
    settings = {
        {
            key = 'display_condition',
            renderer = 'checkbox',
            name = 'Show Item Condition',
            default = true,
            description = 'Show the item Condition as a red bar below the icon.'
        },
        {
            key = 'display_charge',
            renderer = 'checkbox',
            name = 'Show Item Enchantment Charge',
            default = true,
            description = 'Show the enchantment charge as a blue bar below the icon.'
        },
        {
            key = 'display_count',
            renderer = 'checkbox',
            name = 'Show Item Count',
            default = true,
            description = 'Show the item stack size in the bottom left corner of the icon.'
        },
        {
            key = 'display_spell_castchance',
            renderer = 'checkbox',
            name = 'Show Cast Chance',
            default = true,
            description = 'Show spell cast chance as a red bar below the icon.'
        },
        {
            key = 'display_key',
            renderer = 'checkbox',
            name = 'Show Key Num',
            default = true,
            description = 'Show the Key Number in the top right corner of the icon.'
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsZHIHotbarBAAppearance',
    name = 'Appearance',
    description = 'Advanced Appearance Settings.\nUse at your own risk.',
    page = 'ZHIPageHotbar',
    l10n = 'ZHI_l10n',
    permanentStorage = true,
    settings = {
        {
            name = 'Icon Size',
            key = 'icon_size',
            renderer = 'number',
            default = 32,
            description = 'Min: 8, Max: 128, Default: 32',
            argument = {
                integer = true,
                min = 8,
                max = 64,
            }
        },
        {
            key = 'icon_border_enable',
            renderer = 'checkbox',
            name = 'Enable Icon Border',
            default = true,
            description = 'Enable inner border based on type.'
        },
        {
            key = 'icon_magic_enable',
            renderer = 'checkbox',
            name = 'Enable Magic Item Background',
            default = true,
            description = 'Only effective when icon border is disabled.'
        }, 
        {
            name = 'Icon Border Size',
            key = 'icon_border_size',
            renderer = 'number',
            default = 40,
            description = 'Min: 8, Max: 128, Default: 40',
            argument = {
                integer = true,
                min = 8,
                max = 64,
            }
        },
        {
            name = 'Hotkey Size',
            key = 'hotkey_size',
            renderer = 'number',
            default = 50,
            description = 'Min: 8, Max: 128, Default: 50',
            argument = {
                integer = true,
                min = 8,
                max = 94,
            }
        },
        {
            name = 'Hotkey Padding',
            key = 'hotkey_padding',
            renderer = 'number',
            default = 4,
            description = 'Spacing between Hotkeys.\nMin: 0, Max: 64, Default: 4',
            argument = {
                integer = true,
                min = 0,
                max = 64,
            }
        },
        {
            name = 'Hotkey Border',
            key = 'hotkey_border',
            renderer = 'checkbox',
            default = true,
            description = 'Outer Hotkey Border.',
        },
        {
            name = 'Item Count Text Size',
            key = 'itemcount_text_size',
            renderer = 'number',
            default = 14,
            description = 'Min: 8, Max: 32, Default: 14',
            argument = {
                integer = true,
                min = 0,
                max = 64,
            }
        },
        {
            name = 'Item Count Text Color',
            key = 'itemcount_text_color',
            renderer = 'color',
            default = constants.normalColor,
            description = 'Default: ' .. tostring(constants.normalColor:asHex()),
        },
        {
            name = 'Item Count Anchor X',
            key = 'itemcount_anchorx',
            renderer = 'number',
            default = 0.875,
            description = 'Min: 0.0, Max: 1.0, Default: 0.875',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Item Count Anchor Y',
            key = 'itemcount_anchory',
            renderer = 'number',
            default = 0.9,
            description = 'Min: 0.0, Max: 1.0, Default: 0.9',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Key Num Text Size',
            key = 'keynum_text_size',
            renderer = 'number',
            default = 14,
            description = 'Min: 8, Max: 32, Default: 14',
            argument = {
                integer = true,
                min = 0,
                max = 64,
            }
        },
        {
            name = 'Key Num Text Color',
            key = 'keynum_text_color',
            renderer = 'color',
            default = util.color.rgb(0.65, 0.67, 0.70),
            description = 'Default: ' .. tostring(util.color.rgb(0.65, 0.67, 0.70):asHex()),
        },
        {
            name = 'Key Num Anchor X',
            key = 'keynum_anchorx',
            renderer = 'number',
            default = 0.875,
            description = 'Min: 0.0, Max: 1.0, Default: 0.875',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Key Num Anchor Y',
            key = 'keynum_anchory',
            renderer = 'number',
            default = 0.1,
            description = 'Min: 0.0, Max: 1.0, Default: 0.1',
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Info Bars Padding',
            key = 'infobar_padding',
            renderer = 'number',
            default = 1,
            description = 'Min: 0, Max: 32, Default: 1',
            argument = {
                integer = true,
                min = 0,
                max = 32,
            }
        },
        {
            name = 'Info Bar Cond/Cast Color',
            key = 'infobar_cond_color',
            renderer = 'color',
            default = util.color.rgb(0.90, 0.20, 0.15),
            description = 'Default: ' .. tostring(util.color.rgb(0.90, 0.20, 0.15):asHex()),
        },
        {
            name = 'Info Bar Charge Color',
            key = 'infobar_charge_color',
            renderer = 'color',
            default = util.color.rgb(0.50, 0.60, 0.90),
            description = 'Default: ' .. tostring(util.color.rgb(0.50, 0.60, 0.90):asHex()),
        },
    }
}

return {
    
}