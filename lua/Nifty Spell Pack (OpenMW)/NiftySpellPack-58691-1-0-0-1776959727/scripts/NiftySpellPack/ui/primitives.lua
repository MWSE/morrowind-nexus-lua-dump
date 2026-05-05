--[[
    primitives.lua
    Low-level reusable UI building blocks: padding, click feedback, header sections,
    button border templates, and the basic tab button widget.
]]

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local C = require('scripts.niftyspellpack.ui.constants')

local Primitives = {}

function Primitives.createPaddingTemplate(size)
    size = util.vector2(1, 1) * size
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                props = {
                    size = size,
                },
            },
            {
                external = { slot = true },
                props = {
                    position = size,
                    relativeSize = util.vector2(1, 1),
                },
            },
            {
                props = {
                    position = size,
                    relativePosition = util.vector2(1, 1),
                    size = size,
                },
            },
        }
    }
end

function Primitives.playClickFx()
    ambient.playSound('menu click')
end

local v2 = util.vector2
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

local buttonBorderResources = {}
local buttonBorderPieces = {}

for k in pairs(borderSideParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderPattern:format(k) }
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
    buttonBorderResources[k] = ui.texture { path = buttonBorderPattern:format(k) }
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
        }
    }
end

local function bordersTemplate(size, pieces)
    local template = {
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == 'top' or k == 'bottom')
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = pieces[k],
            props = {
                position = (direction - v) * size,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * size,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = pieces[k],
            props = {
                position = -v * size,
                relativePosition = v,
                size = v2(size, size),
            }
        }
    end
    template.content:add {
        external = { slot = true },
        props = {
            position = v2(size, size),
            size = v2(size * -2, size * -2),
            relativeSize = v2(1, 1),
        }
    }
    return template
end

Primitives.buttonBordersTemplate = bordersTemplate(buttonBorderSize, buttonBorderPieces)

Primitives.paddedLayout = function(layout, up, right, down, left)
    up = up or 0
    right = right or up or 0
    down = down or up or 0
    left = left or right or 0
    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            {
                props = {
                    size = util.vector2(0, up),
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                },
                content = ui.content {
                    {
                        props = {
                            size = util.vector2(left, 0),
                        },
                    },
                    layout,
                    {
                        props = {
                            size = util.vector2(right, 0),
                        },
                    },
                },
            },
            {
                props = {
                    size = util.vector2(0, down),
                },
            },
        }
    }
end

Primitives.intervalH = function(size)
    return {
        props = {
            size = util.vector2(size, 0),
        },
    }
end

Primitives.intervalV = function(size)
    return {
        props = {
            size = util.vector2(0, size),
        },
    }
end

return Primitives
