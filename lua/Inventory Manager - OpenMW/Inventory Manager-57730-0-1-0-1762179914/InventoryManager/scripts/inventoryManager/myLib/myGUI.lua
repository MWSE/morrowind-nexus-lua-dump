local util = require('openmw.util')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')
local ui = require('openmw.ui')
-- local g = require('scripts.inventoryManager.myLib')
local textures = require('scripts.inventoryManager.myLib.myConstants').textures


local titleFlex = auxUi.deepLayoutCopy(I.MWUI.templates.padding)
titleFlex.type = ui.TYPE.Flex
titleFlex.props = {
        relativeSize = util.vector2(1, 1),
        -- align = ui.ALIGNMENT.Center,
        -- arrange = ui.ALIGNMENT.Center,
}

table.insert(titleFlex.content, 1, {
        type = ui.TYPE.Image,
        props = {
                resource = textures.black,
                relativeSize = util.vector2(0.5, 1),
                relativePosition = util.vector2(0.5, 0),
                anchor = util.vector2(0.5, 0),
                alpha = 1,
        },
})


-- local flexBg = auxUi.deepLayoutCopy(I.MWUI.templates.bordersThick)
local flexBg = {
        type = ui.TYPE.Image,
        content = ui.content {

                {
                        props = {
                                align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center,
                        },

                        content = ui.content {
                                {
                                        external = { slot = true }
                                }
                        }
                }
        }

}



local flexTBg = auxUi.deepLayoutCopy(I.MWUI.templates.bordersThick)
flexTBg.type = ui.TYPE.Flex
table.insert(flexTBg.content, 1, {
        type = ui.TYPE.Image,
        props = {
                resource = textures.black,
                -- color = util.color.rgb(0, 0, 0),
                relativeSize = util.vector2(1, 1),
                alpha = 0.7
        },
})

local toolTipTemplate = auxUi.deepLayoutCopy(I.MWUI.templates.borders)
toolTipTemplate.type = ui.TYPE.Flex
table.insert(toolTipTemplate.content, 1, {
        type = ui.TYPE.Image,
        props = {
                resource = textures.black,
                -- color = util.color.rgb(0, 0, 0),
                relativeSize = util.vector2(1, 1),
                alpha = 0.8
        },
})



---@return ui.Layout
local function makeInt(w, h, grow, strech)
        return {
                template = I.MWUI.templates.interval,
                props = { size = util.vector2(w, h) },
                external = { grow = grow or 0, stretch = strech or 0 }
        }
end


return {
        makeInt = makeInt,
        flexBg = flexBg,
        flexTBg = flexTBg,
        toolTipTemplate = toolTipTemplate,
        titleFlex = titleFlex,
}
