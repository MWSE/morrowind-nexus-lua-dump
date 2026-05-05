local I = require("openmw.interfaces")
local util = require("openmw.util")
local v2 = util.vector2
local async = require("openmw.async")
local ambient = require("openmw.ambient")
local ui = require("openmw.ui")
local auxUi = require("openmw_aux.ui")

local C = require(... .. ".consts")

local buttonBorderSize = 4
local borderSideParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1),
}
local borderCornerParts = {
    top_left_corner = v2(0, 0),
    top_right_corner = v2(1, 0),
    bottom_left_corner = v2(0, 1),
    bottom_right_corner = v2(1, 1),
}
local buttonBorderPattern = 'textures/menu_button_frame_%s.dds'

local Templates = {}
local buttonBorderResources = {}
local buttonBorderPieces = {}
Templates.TEXTURES = {}

Templates.createTexture = function(path)
    if Templates.TEXTURES[path] then
        return Templates.TEXTURES[path]
    else
        local tex = ui.texture { path = path }
        Templates.TEXTURES[path] = tex
        return tex
    end
end

Templates.intervalH = function(size)
    return {
        props = {
            size = util.vector2(size, 0),
        },
    }
end

-- Templates.intervalV = function(size)
--     return {
--         props = {
--             size = util.vector2(0, size),
--         },
--     }
-- end

for k in pairs(borderSideParts) do
    buttonBorderResources[k] = Templates.createTexture(buttonBorderPattern:format(k))
    local horizontal = (k == 'top' or k == 'bottom')
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
            tileH = horizontal,
            tileV = not horizontal,
        }
    }
end

for k in pairs(borderCornerParts) do
    buttonBorderResources[k] = Templates.createTexture(buttonBorderPattern:format(k))
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
        }
    }
end

Templates.buttonBorders = function(borderSize)
    buttonBorderSize = borderSize or buttonBorderSize
    local template = {
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == 'top' or k == 'bottom')
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction - v) * buttonBorderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * buttonBorderSize,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = -v * buttonBorderSize,
                relativePosition = v,
                size = v2(buttonBorderSize, buttonBorderSize),
            }
        }
    end
    template.content:add {
        ---@diagnostic disable-next-line: missing-fields
        external = { slot = true },
        props = {
            position = v2(buttonBorderSize, buttonBorderSize),
            size = v2(buttonBorderSize * -2, buttonBorderSize * -2),
            relativeSize = v2(1, 1),
        }
    }
    return template
end

Templates.buttonBox = function()
    local template = {
        type = ui.TYPE.Container,
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == 'top' or k == 'bottom')
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction + v) * buttonBorderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction) * buttonBorderSize,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = v * buttonBorderSize,
                relativePosition = v,
                size = v2(buttonBorderSize, buttonBorderSize),
            }
        }
    end
    template.content:add {
        ---@diagnostic disable-next-line: missing-fields
        external = { slot = true },
        props = {
            position = v2(buttonBorderSize, buttonBorderSize),
            relativeSize = v2(1, 1),
        }
    }
    return template
end

Templates.buttonBoxBgr = function(bgrAlpha)
    local template = auxUi.deepLayoutCopy(Templates.buttonBox())
    template.content:insert(1, {
        type = ui.TYPE.Image,
        props = {
            resource = Templates.createTexture('white'),
            color = C.Colors.BLACK,
            alpha = bgrAlpha or 0,
            relativeSize = v2(1, 1),
            size = v2(buttonBorderSize * 2, buttonBorderSize * 2),
        }
    })
    return template
end

Templates.button = function(text, textSize, onClick, name, bgrAlpha)
    ---@diagnostic disable-next-line: missing-fields
    local element = ui.create {
        name = name,
        template = Templates.buttonBoxBgr(bgrAlpha),
        props = {},
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    Templates.intervalH(8),
                    {
                        name = "btnText",
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textSize = textSize,
                            textColor = C.Colors.DEFAULT,
                        },
                        userData = { colorable = true },
                    },
                    Templates.intervalH(8),
                }
            }
        },
        events = {},
        userData = {
            inFocus = false
        },
    }
    local btnText = element.layout.content[1].content[2]
    element.layout.events.focusLoss = async:callback(function()
        btnText.props.textColor = C.Colors.DEFAULT
        element:update()
    end)
    element.layout.events.focusGain = async:callback(function()
        btnText.props.textColor = C.Colors.DEFAULT_LIGHT
        element:update()
    end)
    element.layout.events.mousePress = async:callback(function()
        ambient.playSound('menu click')
        btnText.props.textColor = C.Colors.DEFAULT_PRESSED
        element:update()
    end)
    element.layout.events.mouseRelease = async:callback(function()
        if onClick then
            onClick()
        end
        btnText.props.textColor = C.Colors.DEFAULT_LIGHT
        element:update()
    end)
    return element
end

return Templates