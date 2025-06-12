local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local v2 = util.vector2

local function createBox(width, height, content)
    return {
        name = "mainWindowWidget",
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            size = v2(width, height)
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    anchor = v2(.5, 0),
                    relativePosition = v2(.5, 0),
                    name = "pluginBoxFlex",
                    horizontal = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Center
                },
                content = content
            }
        }
    }
end

local function createButton(text, textSize, width, height, relativePosition, anchor, callback, highlight)
    local defaultWidth = 100
    local defaultHeight = 25

    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            size = v2(width or defaultWidth, height or defaultHeight),
            anchor = anchor,
            relativePosition = relativePosition,
            visible = true,
            propagateEvents = false
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = text,
                    textSize = textSize,
                    textColor = highlight and util.color.rgb(255, 255, 255) or nil
                }
            }
        },
        events = {
            mousePress = async:callback(callback)
        }
    }
end

local function createButtonGroup(width, content)
    return {
        type = ui.TYPE.Widget,
        props = {
            name = "buttonGroup",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(width, 30)
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                },
                content = content
            }
        }
    }
end

local function createHorizontalLine(width, height)
    local defaultHeight = 2

    return {
        type = ui.TYPE.Image,
        template = I.MWUI.templates.horizontalLine,
        props = {
            size = v2(width, height or defaultHeight)
        }
    }
end

return {
    createBox = createBox,
    createButton = createButton,
    createButtonGroup = createButtonGroup,
    createHorizontalLine = createHorizontalLine
}
