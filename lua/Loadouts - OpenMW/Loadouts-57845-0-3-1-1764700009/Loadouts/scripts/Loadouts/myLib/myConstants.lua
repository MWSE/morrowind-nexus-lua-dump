local util = require('openmw.util')
local ui = require('openmw.ui')

local colors = {
        disabled = util.color.rgba(0.25, 0.25, 0.25, 1),
        selected = util.color.rgb(76.50 / 255, 89.25 / 255, 191.25 / 255),
        header = util.color.rgb(223 / 255, 201 / 255, 159 / 255), --- dfc99f
        normal = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  --- caa560
        hover = util.color.rgb(255 / 255, 255 / 255, 159 / 255),
        black = util.color.hex('000000'),
}

local textures = {
        menuBG = ui.texture { path = 'textures/menu_head_block_middle.dds' },
        black = ui.texture { path = 'textures/black.dds' },
        inactiveTab = ui.texture { path = 'textures/inactiveTab.dds' },
        magicIcon = ui.texture {
                path = 'textures/menu_icon_magic.dds',
                size = util.vector2(32, 32),
                offset = util.vector2(6, 6)
        },
        highlight = ui.texture { path = 'textures/highlight.dds' },
        eqRow = ui.texture { path = 'textures/eqRow.dds' },
        emptyEq = ui.texture { path = 'textures/empty.dds' },
        keepPrevEq = ui.texture { path = 'textures/keepPrev.dds' },
        missing = ui.texture { path = 'textures/missing.dds' },
}


local TEXT_SIZE = 14
local BOX_SIZE = TEXT_SIZE + 10

local sizes = {
        TEXT_SIZE = TEXT_SIZE,
        CONTAINER_SIZE = TEXT_SIZE,
        BOX_SIZE = BOX_SIZE
}



local lists = {
        SCROLL_AMOUNT = 7
}



return {
        colors = colors,
        textures = textures,
        sizes = sizes,
        lists = lists
}
