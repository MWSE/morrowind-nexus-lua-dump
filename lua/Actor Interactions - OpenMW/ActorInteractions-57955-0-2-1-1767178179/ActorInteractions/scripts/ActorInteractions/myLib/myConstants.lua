local util = require('openmw.util')
local ui = require('openmw.ui')

---@type table<string, Color>
local colors = {
        disabled = util.color.rgba(0.25, 0.25, 0.25, 1),
        disabled2 = util.color.rgba(0.14, 0.14, 0.14, 1),
        selected = util.color.rgb(76.50 / 255, 89.25 / 255, 191.25 / 255),
        header = util.color.rgb(223 / 255, 201 / 255, 159 / 255), --- dfc99f
        normal = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  --- caa560
        hover = util.color.rgb(255 / 255, 255 / 255, 159 / 255),
        black = util.color.hex('000000'),

        --- bars colors
        red = util.color.hex('ff4444'),
        blue = util.color.hex('3333aa'),
        green = util.color.hex('44aa44'),
        yellow = util.color.hex('aaaa00'),
}

---@type table<string, string>
local soundFiles = {
        levelUp = 'Sound/Fx/inter/levelUP.wav',
        potion = 'Sound/Fx/item/potion.wav',
        repair = 'Sound/Fx/item/repair.wav',
        enchant = 'Sound/Fx/magic/enchant.wav',
        spellCreate = 'Sound/Fx/magic/mystH.wav',
}


---@type table<string, TextureResource>
local textures = {
        upArrow = ui.texture { path = 'textures/omw_menu_scroll_up.dds' },
        downArrow = ui.texture { path = 'textures/omw_menu_scroll_down.dds' },
        menuBG = ui.texture { path = 'textures/menu_head_block_middle.dds' },
        black = ui.texture { path = 'textures/black.dds' },
        white = ui.texture { path = 'textures/white.dds' },
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

        --- bars
        blueBar = ui.texture { path = 'textures/menu_bar_blue.dds' },
        redBar = ui.texture { path = 'textures/menu_bar_red.dds' },
        greenBar = ui.texture { path = 'textures/menu_bar_green.dds' },
        yellowBar = ui.texture { path = 'textures/menu_bar_yellow.dds' },
        grayBar = ui.texture { path = 'textures/menu_bar_gray.dds' },
}


local TEXT_SIZE = 20
local BOX_SIZE = TEXT_SIZE + 10

---@type table<string, number>
local sizes = {
        TEXT_SIZE = TEXT_SIZE,
        STATS_SIZE = TEXT_SIZE - 4,
        CONTAINER_SIZE = TEXT_SIZE,
        BOX_SIZE = BOX_SIZE,
        TOOLTIP_TEXT_SIZE = TEXT_SIZE,
        LIST_TEXT_SIZE = 20,
        GRID_ITEM_SIZE = 64,
        H5 = 16,
        H4 = 17,
        H3 = 18,
        H2 = 19,
        H1 = 20
}


---@enum TabNames
local tabName = {
        actorStats = 'Stats',
        giveaway = 'Actions',
}


return {
        colors = colors,
        textures = textures,
        sizes = sizes,
        tabName = tabName,
        soundFiles = soundFiles,
}
