local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local core = require('openmw.core')
local input = require('openmw.input')

local l10n = core.l10n('OmwAchievements')
local v2 = util.vector2

local warning = {}

function warning.createWindow()

    local screenSize = ui.screenSize()
    local width_ratio = 0.35
    local height_ratio = 0.18
    local widget_width = screenSize.x * width_ratio
    local widget_height = screenSize.y * height_ratio

    local warningDescriptionText = {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = l10n('warning_description_text'),
            anchor = v2(0, 0),
            relativePosition = v2(0, 0),
            textAlignV = ui.ALIGNMENT.Center,
            textAlignH = ui.ALIGNMENT.Center,
            size = v2(widget_width*0.6, widget_height*0.8*0.3),
            autoSize = false,
            wordWrap = true,
            multiline = true,
            textSize = screenSize.y * 0.018
        }
    }

    local warningDescriptionTextBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(widget_width*0.6, widget_height*0.8*0.3),
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5)
        },
        content = ui.content { 
            warningDescriptionText
        }
    }
    
    local warningDescription = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(widget_width, widget_height*0.8*0.5),
            anchor = v2(0, 0),
            relativePosition = v2(0, 0)
        },
        content = ui.content { 
            warningDescriptionTextBox
        }
    }
    
    local warningYesButton = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            anchor = v2(1, .5),
            relativePosition = v2(1, .5),
            size = v2(100, 23),
            propagateEvents = false
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n('warning_button_yes'),
                    textSize = 14,
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
                core.sendGlobalEvent('clearStorage')
                warningWindow:destroy()
            end)
        }
    }

    local warningNoButton = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            anchor = v2(1, .5),
            relativePosition = v2(1, .5),
            size = v2(100, 23),
            propagateEvents = false
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = l10n('warning_button_no'),
                    textSize = 14,
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
                warningWindow:destroy()
            end)
        }
    }

    local emptyButton = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(1, .5),
            relativePosition = v2(1, .5),
            size = v2(100, 23),
            propagateEvents = false
        }
    }

    local warningButtons = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(widget_width, widget_height*0.2),
            anchor = v2(0, 0),
            relativePosition = v2(0, 0)
        },
        content = ui.content { {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                size = v2(widget_width, widget_height*0.2),
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center
            },
            content = ui.content {
                warningYesButton,
                emptyButton,
                warningNoButton
            }
        } }
    }

    local warningWindowFlex = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(widget_width, widget_height),
            anchor = v2(0, 0),
            relativePosition = v2(0, 0)
        },
        content = ui.content { {
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                autoSize = false,
                size = v2(widget_width, widget_height),
                anchor = v2(0, 0),
                relativePosition = v2(0, 0),
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Start
            },
            content = ui.content {
                warningDescription,
                warningButtons
            }
        } }
    }

    local warningWindowLayout = {
        type = ui.TYPE.Container,
        layer = "Settings",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            name = "warningWindowContainer",
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content {
            warningWindowFlex
        }
    }

    warningWindow = ui.create(warningWindowLayout)

    return warningWindow

end

return warning