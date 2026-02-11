local util = require('openmw.util')
local ui = require('openmw.ui')

local colors = {
        disabled    = util.color.rgba(0.25, 0.25, 0.25, 1),
        selected    = util.color.rgb(76.50 / 255, 89.25 / 255, 191.25 / 255),
        header      = util.color.rgb(223 / 255, 201 / 255, 159 / 255), --- dfc99f
        normal      = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  --- caa560
        hover       = util.color.rgb(255 / 255, 255 / 255, 159 / 255),
        black       = util.color.hex('000000'),
        redTintHex  = 'cc331c',
        blueTintHex = '386a71',
}

local textures = {
        black       = ui.texture { path = 'textures/Loadouts/black.dds' },
        white       = ui.texture { path = 'textures/Loadouts/white.dds' },
        inactiveTab = ui.texture { path = 'textures/Loadouts/inactiveTab.dds' },
        highlight   = ui.texture { path = 'textures/Loadouts/highlight.dds' },
        eqRow       = ui.texture { path = 'textures/Loadouts/eqRow.dds' },
        emptyEq     = ui.texture { path = 'textures/Loadouts/empty.dds' },
        keepPrevEq  = ui.texture { path = 'textures/Loadouts/keepPrev.dds' },
        missing     = ui.texture { path = 'textures/Loadouts/missing.dds' },


        --- OMW Textures
        upArrow         = ui.texture { path = 'textures/omw_menu_scroll_up.dds' },
        downArrow       = ui.texture { path = 'textures/omw_menu_scroll_down.dds' },
        magicIconList   = ui.texture { path = 'textures/menu_icon_magic_mini.dds' },
        menuBG          = ui.texture { path = 'textures/menu_head_block_middle.dds' },
        magicIcon       = ui.texture {
                path = 'textures/menu_icon_magic.dds',
                size = util.vector2(32, 32),
                offset = util.vector2(6, 6)
        },
        menu_icon_equip = ui.texture {
                path = 'textures/menu_icon_equip.dds',
                size = util.vector2(40, 40),
                offset = util.vector2(2, 2)
        },
        blueBar         = ui.texture { path = 'textures/menu_bar_blue.dds' },
        redBar          = ui.texture { path = 'textures/menu_bar_red.dds' },
        greenBar        = ui.texture { path = 'textures/menu_bar_green.dds' },
        yellowBar       = ui.texture { path = 'textures/menu_bar_yellow.dds' },
        grayBar         = ui.texture { path = 'textures/menu_bar_gray.dds' },
}


local TEXT_SIZE = 14
local BOX_SIZE = TEXT_SIZE + 10

local sizes = {
        TEXT_SIZE = TEXT_SIZE,
        CONTAINER_SIZE = TEXT_SIZE,
        BOX_SIZE = BOX_SIZE,
        TOOLTIP_TEXT_SIZE = 18,
        LIST_TEXT_SIZE = 18
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
