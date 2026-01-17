local input = require('openmw.input')

local MOD_NAME = 'Actor Interactions'
local MOD_ID = 'ActorInteractions'
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
        openGivawayWindow = {
                key = 'openGivawayWindow',
                name = 'Open window',
                default = MOD_ID .. '2',
                value = MOD_ID .. '2',
                renderer = 'inputBinding',
                argument = {
                        key = 'openGivawayWindowArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.KEY.X,
                        device = 'keyboard',
                        key = 'openGivawayWindowArgKey',
                        type = 'trigger',
                }

        },
        GP_openGivawayWindow = {
                key = 'GP_openGivawayWindow',
                name = 'Open window',
                default = MOD_ID .. '3',
                value = MOD_ID .. '3',
                renderer = 'inputBinding',
                argument = {
                        key = 'GP_openGivawayWindowArgKey',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.CONTROLLER_BUTTON.LeftStick,
                        device = 'controller',
                        key = 'GP_openGivawayWindowArgKey',
                        type = 'trigger',
                }

        },

        requirementMult = {
                key = 'requirementMult',
                name = 'Actions requirements multiplier',
                description = 'Adjust actions requirements by this ratio (0 - 1)',
                value = 1,
                default = 1,
                renderer = 'number',
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },
        },
}

return {
        o = o,
        MOD_NAME = MOD_NAME,
        MOD_ID = MOD_ID,
        SECTION_KEY = SECTION_KEY
}
