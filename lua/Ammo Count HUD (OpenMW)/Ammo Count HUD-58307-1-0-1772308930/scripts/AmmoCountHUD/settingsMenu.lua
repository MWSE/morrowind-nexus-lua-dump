local I = require('openmw.interfaces')
local util = require("openmw.util")

local presetColors = {
    "d4edfc", -- thirst
    "bfd4bc", -- hunger
    "cfbddb", -- sleep
    "81cded", -- fav color of blue
    "caa560", -- fontColor_color_normal
    "d4b77f", -- goldenMix
    "dfc99f", -- FontColor_color_normal_over
    "eee2c9", -- lightText
    "253170", -- fontColor_color_journal_link
    "3a4daf", -- fontColor_color_journal_link_over
    "707ecf", -- fontColor_color_journal_link_pressed
}

I.Settings.registerPage {
    key = 'AmmoCountHUD',
    l10n = 'AmmoCountHUD',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsAmmoCountHUD_behavior',
    page = 'AmmoCountHUD',
    l10n = 'AmmoCountHUD',
    name = 'behavior_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'cooldown',
            name = 'cooldown_name',
            description = "cooldown_desc",
            renderer = 'number',
            default = .2,
            min = 0,
        },
        {
            key = 'hudMode',
            name = 'hudMode_name',
            renderer = 'select',
            argument = {
                l10n = "AmmoCountHUD",
                items = {
                    "Equipped",
                    "Total",
                    "Eqipped/Total",
                },
            },
            default = "Equipped",
        },
    }
}


I.Settings.registerGroup {
    key = 'SettingsAmmoCountHUD_looks',
    page = 'AmmoCountHUD',
    l10n = 'AmmoCountHUD',
    name = 'looks_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'enabled',
            name = 'enabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'positionLocked',
            name = 'positionLocked_name',
            description = "positionLocked_desc",
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'posX',
            name = 'posX_name',
            renderer = 'number',
            default = 116,
            min = 0,
        },
        {
            key = 'posY',
            name = 'posY_name',
            renderer = 'number',
            default = 1045,
            min = 0,
        },
        {
            key = 'fontSize',
            name = 'fontSize_name',
            renderer = 'number',
            default = 16,
            min = 0,
        },
        {
            key = 'fontColor',
            name = 'fontColor_name',
            renderer = "SuperColorPicker2",
            default = util.color.hex("caa560"),
            argument = {
                presetColors = presetColors,
            },
        },
        {
            key = 'textAlignment',
            name = 'textAlignment_name',
            renderer = 'select',
            argument = {
                l10n = "AmmoCountHUD",
                items = {
                    "Left",
                    "Center",
                    "Right",
                },
            },
            default = "Right",
        },
    }
}
