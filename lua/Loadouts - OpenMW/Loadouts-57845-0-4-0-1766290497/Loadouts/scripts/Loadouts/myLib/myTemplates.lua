local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local textures = require('scripts.Loadouts.myLib.myConstants').textures

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

---@param bgTex TextureResource?
---@param thickness 'thick'|'thin'|'none'
---@param bg boolean
---@param tileV? boolean
---@param tileH? boolean
-- -@param padding [number, number, number, number]
---@param padding {}
---@return table
local function getTemplate(thickness, padding, bg, bgTex, tileV, tileH)
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




        if bg then
                if bgTex then
                        template.content:insert(1, {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = bgTex,
                                        relativeSize = util.vector2(1, 1),
                                        tileH = tileH,
                                        tileV = tileV,
                                        -- color = util.color.hex('000000')
                                }
                        })
                else
                        template.content:insert(1, {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = textures.black,
                                        relativeSize = util.vector2(1, 1),
                                        -- color = util.color.hex('000000')
                                }
                        })
                end
        end


        return template
end





local iconFrameSize = 1
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


local InactiveTab = {
        content = ui.content {
                {
                        template = getTemplate('none', { 1, 0, 0, 0 }, true, textures.inactiveTab, false, true),
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
                        template = getTemplate('none', { 1, 0, 0, 0 }, false),
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
                        template = getTemplate('none', { 0, 0, 0, 0 }, true, textures.highlight),
                        props = {
                                relativeSize = util.vector2(1, 1),

                        },
                        external = { slot = true },
                },
        }
}


local highlight_white = {
        content = ui.content {
                {
                        template = getTemplate('none', { 0, 0, 0, 0 }, true, textures.white),
                        props = {
                                relativeSize = util.vector2(1, 1),
                                alpha = 0.6,

                        },
                        external = { slot = true },
                },
        }
}


local textButtonBorder = {
        template = getTemplate('thin', { 0, 0, 0, 0 }, true, textures.inactiveTab),
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


local myTemplates = {
        activeTab = activeTab,
        InactiveTab = InactiveTab,
        highlight = highlight,
        -- entryHighlight = entryHighlight,
        -- entryNormal = entryNormal,
        highlight_white = highlight_white,
        getTemplate = getTemplate,
        textButtonBorder = textButtonBorder,
        iconFrame = iconFrame,
}

return myTemplates
