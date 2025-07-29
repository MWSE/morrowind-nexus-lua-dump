local input = require 'openmw.input'

local I = require 'openmw.interfaces'

local MOD_NAME = 'Hawk3ye'

input.registerTrigger {
    key = MOD_NAME .. 'ToggleTrigger',
    l10n = MOD_NAME,
    name = MOD_NAME .. 'ToggleSetting',
    description = MOD_NAME .. 'ToggleSettingDesc',
}

input.registerAction {
    key = MOD_NAME .. 'HoldAction',
    type = input.ACTION_TYPE.Boolean,
    l10n = MOD_NAME,
    name = MOD_NAME .. 'HoldSetting',
    description = MOD_NAME .. 'HoldSettingDesc',
    defaultValue = false,
}

I.Settings.registerPage {
    --- Key referring to the name of the player/global storage group
    --- and also the page itself
    key = MOD_NAME,
    --- l10n referring to l10n context name (translations subdir name)
    l10n = MOD_NAME,
    --- name referring to the actual displayed name
    name = MOD_NAME .. 'NAME',
    description = MOD_NAME .. "PageDesc"
}

I.Settings.registerGroup {
    key = "Settings" .. MOD_NAME,
    page = MOD_NAME,
    l10n = MOD_NAME,
    name = MOD_NAME .. "Configuration",
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            name = MOD_NAME .. 'Enable',
            description = MOD_NAME .. 'EnableDescription',
            renderer = 'checkbox',
            default = true
        },
        {
            key = 'zoom_fov_degrees',
            name = MOD_NAME .. 'ZoomFOV',
            description = MOD_NAME .. 'FOVDescription',
            renderer = 'number',
            argument = {
                min = 5,
                max = 120,
                step = 1,
                integer = true,
            },
            default = 42,
        },
        {
            key = 'zoom_time',
            name = MOD_NAME .. 'ZoomSpeed',
            description = MOD_NAME .. 'ZoomDescription',
            renderer = 'number',
            argument = {
                min = 0.1,
                max = 2.5,
                step = 0.1,
            },
            default = 0.75
        },
        {
            key = MOD_NAME .. 'Toggle',
            renderer = "inputBinding",
            argument = { key = MOD_NAME .. 'ToggleTrigger', type = "trigger" },
            name = MOD_NAME .. 'Toggle',
            description = MOD_NAME .. 'ToggleDesc',
            default = 'z',
        },
        {
            key = MOD_NAME .. 'Hold',
            renderer = "inputBinding",
            argument = { key = MOD_NAME .. 'HoldAction', type = "action" },
            name = MOD_NAME .. 'Hold',
            description = MOD_NAME .. 'HoldDesc',
            default = 'm2',
        },
    }
}
