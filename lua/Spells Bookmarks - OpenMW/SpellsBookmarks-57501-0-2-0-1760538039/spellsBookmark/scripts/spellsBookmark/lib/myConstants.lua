local util = require('openmw.util')
local ui = require('openmw.ui')
local core = require('openmw.core')
local constants = require('scripts.omw.mwui.constants')

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
        black = ui.texture { path = 'textures/black.png' },

        activeTab = ui.texture { path = 'textures/activeTab.png' },
        inactiveTab = ui.texture { path = 'textures/inactiveTab.png' }

}


local function getColor(gmst)
        local rgb = {}
        local test = core.getGMST(gmst)
        local a = string.gmatch(test, '%d+')
        for i, v in a do
                -- print(i)
                table.insert(rgb, tonumber(i) / 255)
        end
        print(table.unpack(rgb))
        return table.unpack(rgb)
end


return {
        colors = colors,
        textures = textures
}
