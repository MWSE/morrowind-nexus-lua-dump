local util        = require('openmw.util')
local async       = require('openmw.async')
local I           = require('openmw.interfaces')
local auxUi       = require('openmw_aux.ui')
local ui          = require('openmw.ui')
local myTemplates = require('scripts.Loadouts.myLib.myTemplates')
local textures    = require('scripts.Loadouts.myLib.myConstants').textures
local sizes       = require('scripts.Loadouts.myLib.myConstants').sizes
local colors      = require('scripts.Loadouts.myLib.myConstants').colors
local myVars      = require('scripts.Loadouts.myLib.myVars')

local titleFlex   = auxUi.deepLayoutCopy(I.MWUI.templates.padding)
titleFlex.type    = ui.TYPE.Flex
table.insert(titleFlex.content, 1, {
        type = ui.TYPE.Image,
        props = {
                resource = textures.black,
                relativeSize = util.vector2(1, 1),
                relativePosition = util.vector2(0.5, 0.5),
                anchor = util.vector2(0.5, 0.5),
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

---@return ui.Layout
local function makeGap(w, h)
        return {
                props = { size = util.vector2(w, h) },
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

local emptyLO = {
        type = ui.TYPE.Image,
        -- template = I.MWUI.templates.borders,
        props = {
                size = util.vector2(42, 42),
        }
}

local emptyThinLO = {
        type = ui.TYPE.Image,
        props = {
                size = util.vector2(21, 42),
        }
}

local emptyThin2LO = {
        type = ui.TYPE.Image,
        props = {
                size = util.vector2(21, 21),
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




---@param l ui.Layout
---@param parent ui.Element
local focusGainCall = function(l, parent)
        l.props.textColor = colors.hover
        table.insert(myVars.myDelayedActions, parent)
end


---@param l ui.Layout
---@param parent ui.Element
local focusLossCall = function(l, parent)
        l.props.textColor = colors.normal
        table.insert(myVars.myDelayedActions, parent)
end


---@param text string
---@param action fun()
---@param parent ui.Element
---@return ui.Layout
local function makeButton(text, action, parent)
        return {
                type = ui.TYPE.Flex,
                template = myTemplates.getTemplate('thin', { 0, 0, 0, 0 }),
                props = {
                        size = util.vector2(1, sizes.BOX_SIZE),
                        align = ui.ALIGNMENT.Center,

                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = string.format(' %s ', text),
                                        textSize = sizes.TEXT_SIZE,
                                        textShadow = true,


                                },
                                events = {
                                        focusGain = async:callback(function(_, l)
                                                focusGainCall(l, parent)
                                        end),
                                        focusLoss = async:callback(function(_, l)
                                                focusLossCall(l, parent)
                                        end),
                                }
                        }
                },
                events = {
                        mousePress = async:callback(function(e)
                                if e.button ~= 1 then return end
                                action()
                        end)
                }
        }
end


---@param value number
---@param max number
---@param barLen number
---@param barHeight number
---@param color string
---@return ui.Layout
local function makeGUIBar(value, max, barLen, barHeight, color, textSize)
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
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = string.format('%d/%d', value, max),
                                        relativePosition = util.vector2(0.5, 0.5),
                                        anchor = util.vector2(0.5, 0.5),
                                        textSize = textSize or (barHeight - 4),
                                }
                        }
                }


        }
end

---@param value number
---@param max number
---@param barLen number
---@param barHeight number
---@param color string
---@return ui.Layout
local function makeGUIBar_2(value, max, barLen, barHeight, color, textSize)
        value = value or 0
        return {
                type = ui.TYPE.Widget,
                template = myTemplates.iconFrame,
                -- template = myTemplates.getTemplate_2({border = 'thin'}),
                -- template = I.MWUI.templates.borders,
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
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = string.format('%d/%d', value, max),
                                        relativePosition = util.vector2(0.5, 0.5),
                                        anchor = util.vector2(0.5, 0.5),
                                        textSize = textSize or (barHeight - 4),
                                }
                        }
                }


        }
end

return {
        makeInt = makeInt,
        makeGap = makeGap,
        titleFlex = titleFlex,
        flexH = flexH,
        flexV = flexV,
        centerflex = centerflex,
        emptyLO = emptyLO,
        emptyThinLO = emptyThinLO,
        emptyThin2LO = emptyThin2LO,
        makeTextBar = makeTextBar,
        makeButton = makeButton,
        makeGUIBar = makeGUIBar,
        makeGUIBar_2 = makeGUIBar_2
}
