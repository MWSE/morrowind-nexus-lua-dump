local util = require('openmw.util')
local ui = require('openmw.ui')
local core = require('openmw.core')

local colors = {
        disabled = util.color.rgba(0.25, 0.25, 0.25, 1),
        selected = util.color.rgb(76.50 / 255, 89.25 / 255, 191.25 / 255),
        header = util.color.rgb(223 / 255, 201 / 255, 159 / 255), --- dfc99f
        normal = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  --- caa560

        hover = util.color.rgb(255 / 255, 255 / 255, 159 / 255),

        cannot = util.color.hex('ca3760'),
        selectedButCannot = util.color.hex('6b4c9d'),
        saved = util.color.hex('52b96c'),


        black = util.color.hex('000000'),
}

local textures = {
        upArrow = ui.texture { path = 'textures/omw_menu_scroll_up.dds' },
        downArrow = ui.texture { path = 'textures/omw_menu_scroll_down.dds' },
        menuBG = ui.texture { path = 'textures/menu_head_block_middle.dds' },
        black = ui.texture { path = 'textures/black.dds' },
        magicIcon = ui.texture { path = 'textures/menu_icon_magic_mini.dds' },

        activeTab = ui.texture { path = 'textures/black.dds' },
        -- activeTab = ui.texture { path = 'textures/activeTab.dds' },
        inactiveTab = ui.texture { path = 'textures/inactiveTab.dds' },


        bookmarksTab = ui.texture { path = 'textures/bookmarksTab.dds' },

        addOrRemoveTab = ui.texture { path = 'textures/addOrRemoveTab.dds' },

        scroll = ui.texture { path = 'Icons/m/Tx_scroll_open_01.tga' },


        enchItem = ui.texture { path = 'Icons/c/tx_amulet_exquisite1.tga' },

        highlight = ui.texture { path = 'textures/highlight.dds' }

        -- scroll = ui.texture { path = 'textures/Tx_scroll_open_01.dds' },





}



local TEXT_SIZE = 16
local LABEL_SIZE = 16
local TOOLTIP_TEXT_SIZE = 16

local sizes = {
        TEXT_SIZE = TEXT_SIZE,
        CONTAINER_SIZE = TEXT_SIZE,
        ICON_SIZE = TEXT_SIZE,
        TAB_SIZE = 30,
        SCROLL_AMOUNT = 1,
        LABEL_SIZE = LABEL_SIZE,
        TOOLTIP_TEXT_SIZE = TOOLTIP_TEXT_SIZE,

}



local lists = {
        SCROLL_AMOUNT = 7
}


local function getColor(gmst)
        local rgb = {}
        local test = core.getGMST(gmst)
        local a = string.gmatch(test, '%d+')
        for i, v in a do
                table.insert(rgb, tonumber(i) / 255)
        end
        return table.unpack(rgb)
end


return {
        colors = colors,
        textures = textures,
        sizes = sizes,
        lists = lists
}
