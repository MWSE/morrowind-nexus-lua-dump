local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local v2 = util.vector2

-- Creates a bordered box with consistent styling
local function createBox(width, height, content)
    return {
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
                    horizontal = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Start
                },
                content = content
            }
        }
    }
end

-- Simple empty widget for spacing
local function createPadding(width, height)
    return {
        type = ui.TYPE.Widget,
        props = { size = v2(width, height) }
    }
end

return {
    createBox = createBox,
    createPadding = createPadding
}