local MOD_NAME = 'Loadouts'
local MOD_ID = 'Loadouts'
local SECTION_KEY = 'SettingsPlayer' .. MOD_ID



local o = {
        showLoadoutsWindow = {
                key = 'showLoadoutsWindow',
                name = 'Show loadouts window',
                default = MOD_ID,
                value = MOD_ID,
                renderer = 'inputBinding',
                argument = {
                        key = 'showLoadoutsWindowArgKey',
                        type = 'trigger',
                }

        },
        equipLoadoutKey = {
                key = 'equipLoadoutKey',
                name = 'Equip selected loadout',
                default = MOD_ID .. '2',
                value = MOD_ID .. '2',
                actualValue = 'E',
                renderer = 'inputBinding',
                argument = {
                        key = 'equipLoadoutKeyArgKey',
                        type = 'trigger',
                }

        },

        switchToNextLoadout = {
                key = 'switchToNextLoadout',
                name = 'Quick switch to next loadout',
                default = MOD_ID .. '3',
                value = MOD_ID .. '3',
                renderer = 'inputBinding',
                argument = {
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
                }

        },


}

return {
        o = o,
        MOD_NAME = MOD_NAME,
        MOD_ID = MOD_ID,
        SECTION_KEY = SECTION_KEY
}
