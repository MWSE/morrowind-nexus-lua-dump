local util = require('openmw.util')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')
local ui = require('openmw.ui')
local textures = require('scripts.Loadouts.myLib.myConstants').textures


local titleFlex = auxUi.deepLayoutCopy(I.MWUI.templates.padding)
titleFlex.type = ui.TYPE.Flex
titleFlex.props = {
        relativeSize = util.vector2(1, 1),
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


---@return ui.Layout
local function makeInt(w, h, grow, strech)
        return {
                template = I.MWUI.templates.interval,
                props = { size = util.vector2(w, h) },
                external = { grow = grow or 0, stretch = strech or 0 }
        }
end


local function flexV(content)
        return {
                type = ui.TYPE.Flex,
                content = ui.content(content)
        }
end

local function flexH(content)
        return {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content(content)
        }
end


---@param content ui.Layout[]
---@param horizontal? boolean
---@return ui.Layout
local function centerflex(content, horizontal)
        return {
                type = ui.TYPE.Flex,
                props = {
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        horizontal = horizontal or false
                                },
                                content = ui.content(content)
                        }
                }

        }
end

local emptyLO = {
        type = ui.TYPE.Image,
        -- template = I.MWUI.templates.borders,
        props = {
                size = util.vector2(32, 32),
        }
}

local emptyThinLO = {
        type = ui.TYPE.Image,
        props = {
                size = util.vector2(16, 32),
        }
}


return {
        makeInt = makeInt,
        titleFlex = titleFlex,
        flexH = flexH,
        flexV = flexV,
        centerflex = centerflex,
        emptyLO = emptyLO,
        emptyThinLO = emptyThinLO
}
