local util = require('openmw.util')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')
local ui = require('openmw.ui')
local textures = require('scripts.ActorInteractions.myLib.myConstants').textures
local colors = require('scripts.ActorInteractions.myLib.myConstants').colors
local sizes = require('scripts.ActorInteractions.myLib.myConstants').sizes


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
        },
})


---@return ui.Layout
local function makeInt(w, h, grow, stretch)
        return {
                template = I.MWUI.templates.interval,
                props = { size = util.vector2(w, h) },
                external = { grow = grow or 0, stretch = stretch or 0 }
        }
end


local function flexV(content)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ##################
                content = ui.content(content)
        }
end

local function flexH(content)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ##################
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

local function centerText(text)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ############
                props = {
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        relativeSize = util.vector2(1, 1),

                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = text,
                                                }
                                        },
                                }
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



---@param value number
---@param max number
---@param BAR_LEN number
---@param reversed boolean
---@return string
local function makeTextBar(value, max, BAR_LEN, reversed)
        local per = math.min(value / max, 1)

        local prog
        if per >= 0.1 then
                prog = math.floor(BAR_LEN * per)
        else
                prog = math.ceil(BAR_LEN * per)
        end

        local empty = BAR_LEN - prog
        local color

        if reversed then
                if per < 0.5 then
                        color = '#73bd80'
                elseif per < 0.7 then
                        color = '#bdbd73'
                else
                        color = '#FF7373'
                end
        else
                if per < 0.3 then
                        color = '#FF7373'
                elseif per < 0.7 then
                        color = '#bdbd73'
                else
                        color = '#73bd80'
                end
        end

        return string.format('%s%s#%s%s#%s',
                color,
                string.rep('|', prog),
                colors.disabled:asHex(),
                string.rep('|', empty),
                colors.normal:asHex()
        )
end

---@param value number
---@param max number
---@param barLen number
---@param barHeight number
---@param color string
---@return ui.Layout
local function makeGUIBar(value, max, barLen, barHeight, color)
        value = value or 0
        return {
                type = ui.TYPE.Widget,
                template = I.MWUI.templates.borders,
                props = {
                        size = util.vector2(barLen, barHeight)
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = textures.grayBar,
                                        size = util.vector2(barLen * value / max, barHeight),
                                        color = util.color.hex(color)
                                }
                        },
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                        arrange = ui.ALIGNMENT.Center,
                                        align = ui.ALIGNMENT.Center

                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = string.format('%d/%d', value, max),
                                                        textSize = barHeight - 4,
                                                }
                                        }

                                }
                        }
                }


        }
end





---@param name string
---@param bar any
---@return table
local function makeLabelWithBar(name, bar)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                external = { stretch = 1 },
                props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = name,
                                        textSize = sizes.H5,
                                }
                        },
                        makeInt(10, 0, 1),
                        bar
                }

        }
end


---@param text string
---@param size? number
---@return ui.Layout
local function makeText(text, size)
        return {
                template = I.MWUI.templates.textNormal,
                props = {
                        text = text,
                        textSize = size or sizes.H5,
                }
        }
end

return {
        titleFlex = titleFlex,
        flexH = flexH,
        flexV = flexV,
        centerflex = centerflex,
        emptyLO = emptyLO,
        emptyThinLO = emptyThinLO,
        makeInt = makeInt,
        makeTextBar = makeTextBar,
        centerText = centerText,
        makeGUIBar = makeGUIBar,
        makeLabelWithBar = makeLabelWithBar,
        makeText = makeText,
}
