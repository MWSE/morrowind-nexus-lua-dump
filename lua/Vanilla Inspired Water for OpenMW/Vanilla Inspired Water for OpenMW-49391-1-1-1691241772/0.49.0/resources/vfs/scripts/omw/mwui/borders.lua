local ui = require('openmw.ui')
local util = require('openmw.util')

local auxUi = require('openmw_aux.ui')

local constants = require('scripts.omw.mwui.constants')

local v2 = util.vector2
local whiteTexture = constants.whiteTexture
local menuTransparency = ui._getMenuTransparency()

local sideParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1),
}
local cornerParts = {
    top_left = v2(0, 0),
    top_right = v2(1, 0),
    bottom_left = v2(0, 1),
    bottom_right = v2(1, 1),
}

local borderSidePattern = 'textures/menu_thin_border_%s.dds'
local borderCornerPattern = 'textures/menu_thin_border_%s_corner.dds'

local borderResources = {}
do
    for k in pairs(sideParts) do
        borderResources[k] = ui.texture{ path = borderSidePattern:format(k) }
    end
    for k in pairs(cornerParts) do
        borderResources[k] = ui.texture{ path = borderCornerPattern:format(k) }
    end
end

local borderPieces = {}
for k in pairs(sideParts) do
    local horizontal = k == 'top' or k == 'bottom'
    borderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = borderResources[k],
            tileH = horizontal,
            tileV = not horizontal,
        },
    }
end
for k in pairs(cornerParts) do
    borderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = borderResources[k],
        },
    }
end



local function borderTemplates(borderSize)
    local borderV = v2(1, 1) * borderSize
    local result = {}
    result.horizontalLine = {
        type = ui.TYPE.Image,
        props = {
            resource = borderResources.top,
            tileH = true,
            tileV = false,
            size = v2(0, borderSize),
            relativeSize = v2(1, 0),
        },
    }

    result.verticalLine = {
        type = ui.TYPE.Image,
        props = {
            resource = borderResources.left,
            tileH = false,
            tileV = true,
            size = v2(borderSize, 0),
            relativeSize = v2(0, 1),
        },
    }

    result.borders = {
        content = ui.content {},
    }
    for k, v in pairs(sideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        result.borders.content:add {
            template = borderPieces[k],
            props = {
                position = (direction - v) * borderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * borderSize,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(cornerParts) do
        result.borders.content:add {
            template = borderPieces[k],
            props = {
                position = -v * borderSize,
                relativePosition = v,
                size = borderV,
            },
        }
    end
    result.borders.content:add {
        external = { slot = true },
        props = {
            position = borderV,
            size = borderV * -2,
            relativeSize = v2(1, 1),
        }
    }

    result.box = {
        type = ui.TYPE.Container,
        content = ui.content{},
    }
    for k, v in pairs(sideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        result.box.content:add {
            template = borderPieces[k],
            props = {
                position = (direction + v) * borderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction) * borderSize,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(cornerParts) do
        result.box.content:add {
            template = borderPieces[k],
            props = {
                position = v * borderSize,
                relativePosition = v,
                size = borderV,
            },
        }
    end
    result.box.content:add {
        external = { slot = true },
        props = {
            position = borderV,
            relativeSize = v2(1, 1),
        }
    }

    local backgroundTransparent = {
        type = ui.TYPE.Image,
        props = {
            resource = whiteTexture,
            color = util.color.rgb(0, 0, 0),
            alpha = menuTransparency,
        },
    }
    local backgroundSolid = {
        type = ui.TYPE.Image,
        props = {
            resource = whiteTexture,
            color = util.color.rgb(0, 0, 0),
        },
    }

    result.boxTransparent = auxUi.deepLayoutCopy(result.box)
    result.boxTransparent.content:insert(1, {
        template = backgroundTransparent,
        props = {
            relativeSize = v2(1, 1),
            size = borderV * 2,
        },
    })

    result.boxSolid = auxUi.deepLayoutCopy(result.box)
    result.boxSolid.content:insert(1, {
        template = backgroundSolid,
        props = {
            relativeSize = v2(1, 1),
            size = borderV * 2,
        },
    })

    return result
end

local thinBorders = borderTemplates(constants.border)
local thickBorders = borderTemplates(constants.thickBorder)

return function(templates)
    for k, t in pairs(thinBorders) do
        templates[k] = t
    end
    for k, t in pairs(thickBorders) do
        templates[k .. 'Thick'] = t
    end
end