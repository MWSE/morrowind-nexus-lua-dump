local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

local blackBG = {
    skin = "BlackBG",
    props = {
        relativeSize = v2(1, 1),
    },
}

local borderSize = 4

local borderTop = {
    props = {
        path = "textures/menu_thin_border_top.dds",
        size = v2(-2 * borderSize, borderSize),
        relativeSize = v2(1, 0),
        position = v2(borderSize, 0),
        relativePosition = v2(0, 0),
        anchor = v2(0, 0),
        tileH = true,
    },
}

local borderBottom = {
    props = {
        path = "textures/menu_thin_border_bottom.dds",
        size = v2(-2 * borderSize, borderSize),
        relativeSize = v2(1, 0),
        position = v2(borderSize, 0),
        relativePosition = v2(0, 1),
        anchor = v2(0, 1),
        tileH = true,
    },
}

local borderLeft = {
    props = {
        path = "textures/menu_thin_border_left.dds",
        size = v2(borderSize, -2 * borderSize),
        relativeSize = v2(0, 1),
        position = v2(0, borderSize),
        relativePosition = v2(0, 0),
        anchor = v2(0, 0),
        tileV = true,
    },
}

local borderRight = {
    props = {
        path = "textures/menu_thin_border_right.dds",
        size = v2(borderSize, -2 * borderSize),
        relativeSize = v2(0, 1),
        position = v2(0, borderSize),
        relativePosition = v2(1, 0),
        anchor = v2(1, 0),
        tileV = true,
    },
}

local borderCornerTopLeft = {
    props = {
        path = "textures/menu_thin_border_top_left_corner.dds",
        size = v2(borderSize, borderSize),
        relativeSize = v2(0, 0),
        position = v2(0, 0),
        relativePosition = v2(0, 0),
        anchor = v2(0, 0),
    },
}

local borderCornerTopRight = {
    props = {
        path = "textures/menu_thin_border_top_right_corner.dds",
        size = v2(borderSize, borderSize),
        relativeSize = v2(0, 0),
        position = v2(0, 0),
        relativePosition = v2(1, 0),
        anchor = v2(1, 0),
    },
}

local borderCornerBottomLeft = {
    props = {
        path = "textures/menu_thin_border_bottom_left_corner.dds",
        size = v2(borderSize, borderSize),
        relativeSize = v2(0, 0),
        position = v2(0, 0),
        relativePosition = v2(0, 1),
        anchor = v2(0, 1),
    },
}

local borderCornerBottomRight = {
    props = {
        path = "textures/menu_thin_border_bottom_right_corner.dds",
        size = v2(borderSize, borderSize),
        relativeSize = v2(0, 0),
        position = v2(0, 0),
        relativePosition = v2(1, 1),
        anchor = v2(1, 1),
    },
}

local borders = {
    props = {
        relativeSize = v2(1, 1),
    },
    content = ui.content {
        {
            type = ui.TYPE.Image,
            template = borderTop,
        },
        {
            type = ui.TYPE.Image,
            template = borderBottom,
        },
        {
            type = ui.TYPE.Image,
            template = borderLeft,
        },
        {
            type = ui.TYPE.Image,
            template = borderRight,
        },
        {
            type = ui.TYPE.Image,
            template = borderCornerTopLeft,
        },
        {
            type = ui.TYPE.Image,
            template = borderCornerTopRight,
        },
        {
            type = ui.TYPE.Image,
            template = borderCornerBottomLeft,
        },
        {
            type = ui.TYPE.Image,
            template = borderCornerBottomRight,
        },
        {
            external = {
                slot = true,
            },
            props = {
                position = v2(borderSize, borderSize),
                size = v2(-2 * borderSize, -2 * borderSize),
                relativeSize = v2(1, 1),
            },
        },
    }
}

local box = {
    content = ui.content {
        { template = blackBG },
        {
            template = borders,
            content = ui.content {
                {
                    extenal = {
                        slot = true,
                    },
                    props = {
                        relativeSize = v2(1, 1),
                    },
                },
            }
        },
    },
}

local clockWindow = {
    content = ui.content {
        {
            template = box,
            external = {
                slot = true,
            },
            props = {
                relativeSize = v2(1, 1),
            },
        },
        {
            props = {
                relativeSize = v2(1, 1),
            },
            external = {
                action = true,
                move = v2(1, 1),
                resize = v2(0, 0),
            },
        },
    },
}

local clockText = {
    props = {
        textSize = 16,
        textColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255),
    },
}

return {
    clockWindow = clockWindow,
    clockText = clockText,
}