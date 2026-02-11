local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local textures = require('scripts.Loadouts.myLib.myConstants').textures
local o = require('scripts.Loadouts.settingsData').o
local myConstants = require('scripts.Loadouts.myLib.myConstants')

local borders = {
        thick = {
                top = ui.texture { path = 'textures/menu_thick_border_top.dds' },
                bottom = ui.texture { path = 'textures/menu_thick_border_bottom.dds' },
                left = ui.texture { path = 'textures/menu_thick_border_left.dds' },
                right = ui.texture { path = 'textures/menu_thick_border_right.dds' },
        },
        thin = {
                top = ui.texture { path = 'textures/menu_thin_border_top.dds' },
                bottom = ui.texture { path = 'textures/menu_thin_border_bottom.dds' },
                left = ui.texture { path = 'textures/menu_thin_border_left.dds' },
                right = ui.texture { path = 'textures/menu_thin_border_right.dds' },
        },
        none = {

        }
}


---@param template MWUITemplate
---@param thickness 'thick'|'thin'|'none'
local function addBorders(template, thickness)
        if thickness ~= 'none' then
                local borderSize = thickness == 'thick' and 4 or thickness == 'thin' and 2 or 0

                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[thickness].top,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, borderSize),
                                tileH = true,

                        }
                })

                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[thickness].bottom,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, borderSize),
                                relativePosition = util.vector2(0, 1),
                                anchor = util.vector2(0, 1),
                                tileH = true,

                        }
                })
                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[thickness].left,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(borderSize, 0),
                                tileV = true,

                        }
                })
                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[thickness].right,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(borderSize, 0),
                                relativePosition = util.vector2(1, 0),
                                anchor = util.vector2(1, 0),
                                tileV = true,

                        }
                })
        end
end

---@param bgTex TextureResource?
---@param thickness 'thick'|'thin'|'none'
---@param tileV? boolean
---@param tileH? boolean
---@param alpha? number
---@param padding {}
---@return table
local function getTemplate(thickness, padding, bgTex, tileV, tileH, alpha)
        local pad_top = padding[1] or 4
        local pad_right = padding[2] or 4
        local pad_bottom = padding[3] or 4
        local pad_left = padding[4] or 4

        local template = {
                content = ui.content {
                        {
                                external = { slot = true },
                                type = ui.TYPE.Flex,
                                props = {

                                        position = util.vector2(pad_left, pad_top),
                                        size = util.vector2(-pad_left - pad_right, -pad_top - pad_bottom),
                                        relativeSize = util.vector2(1, 1),
                                }
                        }
                }
        }

        addBorders(template, thickness)

        if bgTex then
                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = bgTex,
                                relativeSize = util.vector2(1, 1),
                                tileH = tileH,
                                tileV = tileV,
                                alpha = alpha
                                -- color = util.color.hex('000000')
                        }
                })
        end



        return template
end

---@class MY_TEMPLATE_DATE
---@field border 'thick'|'thin'|'none'
---@field bg? TextureResource
---@field alpha? number
---@field tileH? boolean
---@field tileV? boolean

---@param data MY_TEMPLATE_DATE
---@return table
local function getTemplate_2(data)
        local template = {
                content = ui.content {
                        {
                                external = { slot = true },
                                -- type = ui.TYPE.Flex,
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                }
                        }
                }
        }

        if data.border ~= 'none' then
                local borderSize = data.border == 'thick' and 4 or data.border == 'thin' and 2 or 0

                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[data.border].top,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, borderSize),
                                tileH = true,

                        }
                })

                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[data.border].bottom,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, borderSize),
                                relativePosition = util.vector2(0, 1),
                                anchor = util.vector2(0, 1),
                                tileH = true,

                        }
                })
                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[data.border].left,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(borderSize, 0),
                                tileV = true,

                        }
                })
                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders[data.border].right,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(borderSize, 0),
                                relativePosition = util.vector2(1, 0),
                                anchor = util.vector2(1, 0),
                                tileV = true,

                        }
                })
        end


        if data.bg then
                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                resource = data.bg,
                                relativeSize = util.vector2(1, 1),
                                tileH = data.tileH,
                                tileV = data.tileV,
                                alpha = data.alpha
                        }
                })
        end

        return template
end


---@param data MY_TEMPLATE_DATE
---@return MWUITemplate
local function getTemplate_3(data)
        local template = {
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                external = { slot = true },
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                }
                        }
                }
        }

        addBorders(template, data.border)

        if data.bg then
                template.content:insert(1, {
                        type = ui.TYPE.Image,
                        props = {
                                relativeSize = util.vector2(1, 1),
                                resource = data.bg,
                                tileH = data.tileH,
                                tileV = data.tileV,
                                alpha = data.alpha
                        }
                })
        end

        return template
end


local iconFrameSize = 2
local iconFrame = {
        content = ui.content {
                {
                        external = { slot = true },
                        type = ui.TYPE.Flex,
                        props = {

                                size = util.vector2(0, -2),
                                relativeSize = util.vector2(1, 1),
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {

                                resource = borders.thin.top,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, iconFrameSize),
                                tileH = true,
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders.thin.bottom,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, iconFrameSize),
                                tileH = true,

                                relativePosition = util.vector2(0, 1),
                                anchor = util.vector2(0, 1),
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders.thin.left,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(iconFrameSize, 0),
                                tileV = true,
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders.thin.right,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(iconFrameSize, 0),
                                tileV = true,

                                relativePosition = util.vector2(1, 0),
                                anchor = util.vector2(1, 0),

                        }
                },
        }
}

local iconFrameSize_1 = 1
local iconFrame_1 = {
        content = ui.content {
                {
                        external = { slot = true },
                        type = ui.TYPE.Flex,
                        props = {

                                size = util.vector2(0, -2),
                                relativeSize = util.vector2(1, 1),
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {

                                resource = borders.thin.top,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, iconFrameSize_1),
                                tileH = true,
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders.thin.bottom,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, iconFrameSize_1),
                                tileH = true,

                                relativePosition = util.vector2(0, 1),
                                anchor = util.vector2(0, 1),
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders.thin.left,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(iconFrameSize_1, 0),
                                tileV = true,
                        }
                },
                {
                        type = ui.TYPE.Image,
                        props = {
                                resource = borders.thin.right,
                                relativeSize = util.vector2(0, 1),
                                size = util.vector2(iconFrameSize_1, 0),
                                tileV = true,

                                relativePosition = util.vector2(1, 0),
                                anchor = util.vector2(1, 0),

                        }
                },
        }
}


local InactiveTab = {
        content = ui.content {
                {
                        template = getTemplate('none', { 1, 0, 0, 0 }, textures.inactiveTab, false, true),
                        props = {
                                relativeSize = util.vector2(1, 1),
                                -- alpha = 0.5,

                        },
                        external = { slot = true },
                },
        }
}
local activeTab = {
        content = ui.content {
                {
                        template = getTemplate('none', { 1, 0, 0, 0 }),
                        props = {
                                relativeSize = util.vector2(1, 1),

                        },
                        external = { slot = true },
                },
        }
}

local highlight = {
        content = ui.content {
                {
                        -- template = getTemplate('none', { 0, 0, 0, 0 }, textures.highlight),
                        -- template = getTemplate('none', { 0, 0, 0, 0 }, textures.white),
                        type = ui.TYPE.Image,
                        props = {
                                resource = textures.white,
                                relativeSize = util.vector2(1, 1),
                                -- color = myConstants.colors.normal
                                -- color = util.color.hex('FF0000')
                                color = util.color.hex('342e23')

                        },
                        external = { slot = true },
                },
        }
}


local highlight_white = {
        content = ui.content {
                {
                        template = getTemplate('none', { 0, 0, 0, 0 }, textures.white),
                        props = {
                                relativeSize = util.vector2(1, 1),
                                alpha = 0.6,

                        },
                        external = { slot = true },
                },
        }
}


local textButtonBorder = {
        template = getTemplate('thin', { 0, 0, 0, 0 }, textures.inactiveTab),
        props = {
                relativeSize = util.vector2(1, 1),
                size = util.vector2(100, 20),

        },
        content = ui.content {
                {
                        template = I.MWUI.templates.textNormal,
                        text = '123123123',
                }
        }
}



local function makeFlexBG(alpha)
        return {
                type = ui.TYPE.Flex,
                external = { grow = 1, stretch = 1 },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = textures.black,
                                        relativeSize = util.vector2(1, 1),
                                        alpha = alpha,
                                        -- relativePosition = util.vector2(0.5, 0.5),
                                        -- anchor = util.vector2(0.5, 0.5),
                                }
                        },
                        {
                                external = { slot = true },
                        }
                }
        }
end


local myTemplates = {
        activeTab = activeTab,
        InactiveTab = InactiveTab,
        highlight = highlight,
        -- entryHighlight = entryHighlight,
        -- entryNormal = entryNormal,
        highlight_white = highlight_white,
        getTemplate = getTemplate,
        getTemplate_2 = getTemplate_2,
        getTemplate_3 = getTemplate_3,
        textButtonBorder = textButtonBorder,
        iconFrame = iconFrame,
        iconFrame_1 = iconFrame_1,
        makeFlexBG = makeFlexBG
}

return myTemplates
