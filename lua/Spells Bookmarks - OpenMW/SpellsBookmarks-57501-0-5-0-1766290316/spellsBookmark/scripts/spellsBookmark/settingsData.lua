local input = require('openmw.input')
local MOD_NAME = 'Spells Bookmarks'
local MOD_ID = 'spellsBookmark'
local SECTION_KEY = 'SettingsPlayer' .. MOD_ID


local o = {
        showMagicWindow = {
                key = 'showMagicWindow',
                name = 'Open window',
                default = MOD_ID .. '1',
                value = MOD_ID .. '1',
                renderer = "inputBinding",
                argument = {
                        key = 'showMagicWindowArg',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.KEY.V,
                        device = 'keyboard',
                        key = 'showMagicWindowArg',
                        type = 'trigger',
                }
        },

        showMagicWindowMax = {
                key = 'showMagicWindowMax',
                name = 'Open window maximized',
                default = MOD_ID .. '2',
                value = MOD_ID .. '2',
                renderer = "inputBinding",
                argument = {
                        key = 'showMagicWindowMaxArg',
                        type = 'trigger',
                },
                resetBind = {
                        button = input.CONTROLLER_BUTTON.LeftShoulder,
                        device = 'controller',
                        key = 'showMagicWindowMaxArg',
                        type = 'trigger',
                }
        },

        showWindowOnInterface = {
                key = 'showWindowOnInterface',
                name = 'Show window when opening inventory',
                default = true,
                value = true,
                renderer = "checkbox",
        },
}

return {
        o = o,
        MOD_NAME = MOD_NAME,
        MOD_ID = MOD_ID,
        SECTION_KEY = SECTION_KEY
}
