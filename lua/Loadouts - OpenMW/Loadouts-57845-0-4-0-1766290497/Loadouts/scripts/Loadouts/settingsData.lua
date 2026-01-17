local input = require('openmw.input')


local MOD_NAME = 'Loadouts'
local MOD_ID = 'Loadouts'
local SECTION_KEY = 'SettingsPlayer' .. MOD_ID



local o = {
        selectWindowView = {
                key = 'selectWindowView',
                name = 'View style for items lists',
                default = 'List View',
                value = 'List View',
                renderer = 'select',
                argument = {
                        l10n = MOD_ID,
                        items = { 'Icon View', 'List View' },
                },
        },
        showLoadoutsWindow = {
                key = 'showLoadoutsWindow',
                name = 'Open loadouts window',
                default = MOD_ID,
                value = MOD_ID,
                renderer = 'inputBinding',
                argument = {
                        key = 'showLoadoutsWindowArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.KEY.V,
                        device = 'keyboard',
                        key = 'showLoadoutsWindowArgKey',
                        type = 'trigger',
                }

        },
        -- equipLoadoutKey = {
        --         key = 'equipLoadoutKey',
        --         name = 'Select',
        --         default = MOD_ID .. '2',
        --         value = MOD_ID .. '2',
        --         actualValue = 'E',
        --         renderer = 'inputBinding',
        --         argument = {
        --                 key = 'equipLoadoutKeyArgKey',
        --                 type = 'trigger',
        --         },
        --         resetBind = {
        --                 button = input.KEY.E,
        --                 device = 'keyboard',
        --                 key = 'equipLoadoutKeyArgKey',
        --                 type = 'trigger',
        --         }

        -- },
        switchToNextLoadout = {
                key = 'switchToNextLoadout',
                name = 'Quick switch to next loadout',
                default = MOD_ID .. '3',
                value = MOD_ID .. '3',
                renderer = 'inputBinding',
                argument = {
                        key = 'switchToNextLoadoutArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.KEY.Period,
                        device = 'keyboard',
                        key = 'switchToNextLoadoutArgKey',
                        type = 'trigger',
                }

        },
        switchToPrevLoadout = {
                key = 'switchToPrevLoadout',
                name = 'Quick switch to previous loadout',
                default = MOD_ID .. '4',
                value = MOD_ID .. '4',
                renderer = 'inputBinding',
                argument = {
                        key = 'switchToPrevLoadoutArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.KEY.Comma,
                        device = 'keyboard',
                        key = 'switchToPrevLoadoutArgKey',
                        type = 'trigger',
                }

        },

        GP_showLoadoutsWindow = {
                key = 'GP_showLoadoutsWindow',
                name = 'Open loadouts window maximized',
                default = MOD_ID .. '5',
                value = MOD_ID .. '5',
                renderer = 'inputBinding',
                argument = {
                        key = 'GP_showLoadoutsWindowArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.CONTROLLER_BUTTON.LeftStick,
                        device = 'controller',
                        key = 'GP_showLoadoutsWindowArgKey',
                        type = 'trigger',
                }

        },
        -- GP_equipLoadoutKey = {
        --         key = 'GP_equipLoadoutKey',
        --         name = 'Select',
        --         default = MOD_ID .. '6',
        --         value = MOD_ID .. '6',
        --         actualValue = 'A',
        --         renderer = 'inputBinding',
        --         argument = {
        --                 key = 'GP_equipLoadoutKeyArgKey',
        --                 type = 'trigger',
        --         },
        --         resetBind = {
        --                 button = input.CONTROLLER_BUTTON.A,
        --                 device = 'controller',
        --                 key = 'GP_equipLoadoutKeyArgKey',
        --                 type = 'trigger',
        --         }
        -- },

        GP_switchToNextLoadout = {
                key = 'GP_switchToNextLoadout',
                name = 'Quick switch to next loadout',
                default = MOD_ID .. '7',
                value = MOD_ID .. '7',
                renderer = 'inputBinding',
                argument = {
                        key = 'GP_switchToNextLoadoutArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.CONTROLLER_BUTTON.LeftShoulder,
                        device = 'controller',
                        key = 'GP_switchToNextLoadoutArgKey',
                        type = 'trigger',
                },

        },

        GP_switchToPrevLoadout = {
                key = 'GP_switchToPrevLoadout',
                name = 'Quick switch to previous loadout',
                default = MOD_ID .. '8',
                value = MOD_ID .. '8',
                renderer = 'inputBinding',
                argument = {
                        key = 'GP_switchToPrevLoadoutArgKey',
                        type = 'trigger',
                },
                resetBind = nil,

        },


}

return {
        o = o,
        MOD_NAME = MOD_NAME,
        MOD_ID = MOD_ID,
        SECTION_KEY = SECTION_KEY
}
