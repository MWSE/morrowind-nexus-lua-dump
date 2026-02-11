local input = require('openmw.input')
local util = require('openmw.util')

local MOD_NAME = 'Loadouts'
local MOD_ID = 'Loadouts'
local SECTION_KEY = 'SettingsPlayer' .. MOD_ID
local core = require('openmw.core')
local l10n = core.l10n(MOD_ID)


local renderers = {
        checkbox = 'checkbox',
        number = 'number',
        select = 'select',
        color = 'color',
        inputBinding = 'inputBinding',
        textLine = 'textLine',
        inputRenderer = 'inputRenderer'
}



local o = {
        bgAlpha = {
                key = 'bgAlpha',
                name = l10n('Main_alpha'),
                description = '(0 - 1)',
                value = 1,
                default = 1,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },
        },
        bgAlpha_eqSelect = {
                key = 'bgAlpha_eqSelect',
                name = l10n('Items_select_alpha'),

                description = '(0 - 1)',
                value = 1,
                default = 1,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },
        },
        bgAlpha_tooltip = {
                key = 'bgAlpha_tooltip',
                name = l10n('Tooltip_alpha'),

                description = '(0 - 1)',
                value = 1,
                default = 1,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },
        },

        showCondition = {
                key = 'showCondition',
                name = l10n('Show_bar'),
                description = l10n('Show_bar_des'),
                value = true,
                default = true,
                renderer = renderers.checkbox,
        },

        highlightColor = {
                key = 'highlightColor',
                name = l10n('Highlight_color'),

                default = util.color.hex('342e23'),
                value = util.color.hex('342e23'),
                renderer = renderers.color,
        },


        toolTipDelay = {
                key = 'toolTipDelay',
                name = l10n('Tooltip_delay'),
                description = 'default = 0.4',
                value = 0.4,
                default = 0.4,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },


        },

        toolTipPosX = {
                key = 'toolTipPosX',
                name = l10n('Tooltip_X_pos'),

                description = '(0 - 1)',
                value = 0.5,
                default = 0.5,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },


        },
        toolTipPosY = {
                key = 'toolTipPosY',
                name = l10n('Tooltip_Y_pos'),
                description = '(0 - 1)',
                value = 0.5,
                default = 0.5,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },


        },
        toolTipAnchorX = {
                key = 'toolTipAnchorX',
                name = l10n('Tooltip_X_anchor'),
                description = '(0 - 1)',
                value = 0.5,
                default = 0.5,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },


        },
        toolTipAnchorY = {
                key = 'toolTipAnchorY',
                name = l10n('Tooltip_Y_anchor'),
                description = '(0 - 1)',
                value = 0.5,
                default = 0.5,
                renderer = renderers.number,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },


        },

        showLoadoutsWindow = {
                key = 'showLoadoutsWindow',
                name = l10n('Open_window_fixed'),
                default = MOD_ID,
                value = MOD_ID,
                renderer = renderers.inputBinding,
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

        showLoadoutsWindowRes = {
                key = 'showLoadoutsWindowRes',
                name = l10n('Open_window'),
                default = MOD_ID .. 'showLoadoutsWindowRes',
                value = MOD_ID .. 'showLoadoutsWindowRes',
                renderer = renderers.inputBinding,
                argument = {
                        key = 'showLoadoutsWindowResArgKey',
                        type = 'trigger',
                },
                resetBind = nil
        },



        switchToNextLoadout = {
                key = 'switchToNextLoadout',
                name = l10n('switch_next'),
                default = MOD_ID .. '3',
                value = MOD_ID .. '3',
                renderer = renderers.inputBinding,
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
                name = l10n('switch_previous'),
                default = MOD_ID .. '4',
                value = MOD_ID .. '4',
                renderer = renderers.inputBinding,
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
                name = l10n('Open_window_fixed'),
                default = MOD_ID .. '5',
                value = MOD_ID .. '5',
                renderer = renderers.inputBinding,
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

        GP_switchToNextLoadout = {
                key = 'GP_switchToNextLoadout',
                name = l10n('switch_next'),
                default = MOD_ID .. '7',
                value = MOD_ID .. '7',
                renderer = renderers.inputBinding,
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
                name = l10n('switch_previous'),
                default = MOD_ID .. '8',
                value = MOD_ID .. '8',
                renderer = renderers.inputBinding,
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
