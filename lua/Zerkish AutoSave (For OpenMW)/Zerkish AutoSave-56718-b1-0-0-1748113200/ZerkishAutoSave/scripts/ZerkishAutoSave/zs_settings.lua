-- ZerkishAutoSave - zs_settings.lua
-- Author: Zerkish (2025)

local I     = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'ZSavePage',
    name = 'Zerkish AutoSave',
    description = 'Simple AutoSaves for OpenMW',
    l10n = 'ZSave_l10n',
}

I.Settings.registerGroup {
    key = 'Settings_ZSave_AutoSave',
    name = 'AutoSave',
    description = nil,
    page = 'ZSavePage',
    l10n = 'ZSave_l10n',
    permanentStorage = true,

    settings = {
        {
            name = 'Save Slots',
            key = 'autosave_count',
            renderer = 'number',
            default = 5,
            description = nil,
            argument = {
                integer = true,
                min = 1,
            }
        },
        {
            key = 'autosave_enable',
            renderer = 'checkbox',
            name = 'Auto Save',
            default = true,
            description = 'Periodically Save the Game'
        },
        {
            name = 'AutoSave Interval',
            key = 'autosave_interval',
            renderer = 'number',
            default = 15,
            description = 'Autosave Interval in Minutes (Min: 0.1)',
            argument = {
                integer = false,
                min = 0.1
            }
        },
        {
            key = 'autosave_cell_change',
            renderer = 'checkbox',
            name = 'Save on Enter',
            default = true,
            description = 'Save when entering a new area.'
        },
        {
            name = 'Save on Enter Min Delay',
            key = 'autosave_cell_delay',
            renderer = 'number',
            default = 30,
            description = 'Delay until area change can trigger autosave. (Seconds) (Min: 1)',
            argument = {
                integer = true,
                min = 1,
            }
        },
    },
}