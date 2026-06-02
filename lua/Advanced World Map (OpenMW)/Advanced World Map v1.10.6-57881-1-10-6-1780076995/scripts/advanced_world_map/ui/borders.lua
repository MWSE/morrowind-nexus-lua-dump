local ui = require("openmw.ui")
local util = require("openmw.util")

local borderTextures = {
    ui.texture{ path = "textures/menu_thin_border_left.dds" },
    ui.texture{ path = "textures/menu_thin_border_right.dds" },
    ui.texture{ path = "textures/menu_thin_border_top.dds" },
    ui.texture{ path = "textures/menu_thin_border_bottom.dds" },
    ui.texture{ path = "textures/menu_thin_border_top_left_corner.dds" },
    ui.texture{ path = "textures/menu_thin_border_top_right_corner.dds" },
    ui.texture{ path = "textures/menu_thin_border_bottom_left_corner.dds" },
    ui.texture{ path = "textures/menu_thin_border_bottom_right_corner.dds" }
}

return function ()
    return {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[1],
                tileH = false,
                tileV = true,
                size = util.vector2(2, 0),
                relativeSize = util.vector2(0, 1),
                anchor = util.vector2(0, 0),
                relativePosition = util.vector2(0, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[2],
                tileH = false,
                tileV = true,
                size = util.vector2(2, 0),
                relativeSize = util.vector2(0, 1),
                anchor = util.vector2(1, 0),
                relativePosition = util.vector2(1, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[3],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 2),
                relativeSize = util.vector2(1, 0),
                anchor = util.vector2(0, 0),
                relativePosition = util.vector2(0, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[4],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 2),
                relativeSize = util.vector2(1, 0),
                anchor = util.vector2(0, 1),
                relativePosition = util.vector2(0, 1),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[5],
                size = util.vector2(2, 2),
                anchor = util.vector2(0, 0),
                relativePosition = util.vector2(0, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[6],
                size = util.vector2(2, 2),
                anchor = util.vector2(1, 0),
                relativePosition = util.vector2(1, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[7],
                size = util.vector2(2, 2),
                anchor = util.vector2(0, 1),
                relativePosition = util.vector2(0, 1),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[8],
                size = util.vector2(2, 2),
                anchor = util.vector2(1, 1),
                relativePosition = util.vector2(1, 1),
            },
        }
end