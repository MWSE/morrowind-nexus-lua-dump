local input = require('openmw.input')
local MOD_NAME = 'One Key Actions List'
local MOD_ID = 'oneKeyActionsList'
local SECTION_KEY = 'SettingsPlayer' .. MOD_ID

local o = {

        windowAlpha = {
                key = 'windowAlpha',
                name = 'Window background transparency',
                default = 0.5,
                value = 0.5,
                renderer = 'number',
                argument = {
                        min = 0,
                        max = 1,
                },
        },

        showoneOneKeyActionsListWindow = {
                key = 'showoneOneKeyActionsListWindow',
                name = 'Show list',
                default = MOD_ID .. '1',
                value = MOD_ID .. '1',
                renderer = 'inputBinding',
                argument = {
                        key = 'showoneOneKeyActionsListWindowArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.KEY.X,
                        device = 'keyboard',
                        key = 'showoneOneKeyActionsListWindowArgKey',
                        type = 'trigger',
                }
        },

        GP_showoneOneKeyActionsListWindow = {
                key = 'GP_showoneOneKeyActionsListWindow',
                name = 'Show list',
                default = MOD_ID .. '2',
                value = MOD_ID .. '2',
                renderer = 'inputBinding',
                argument = {
                        key = 'GP_showoneOneKeyActionsListWindowArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.CONTROLLER_BUTTON.LeftShoulder,
                        device = 'controller',
                        key = 'GP_showoneOneKeyActionsListWindowArgKey',
                        type = 'trigger',
                }

        },
}

return {
        o = o,
        MOD_NAME = MOD_NAME,
        MOD_ID = MOD_ID,
        SECTION_KEY = SECTION_KEY
}
