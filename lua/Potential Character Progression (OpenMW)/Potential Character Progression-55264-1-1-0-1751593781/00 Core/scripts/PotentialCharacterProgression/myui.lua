-- Helper UI functions that aren't mod-specific
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

-- Templates

templates = {}

-- Container/border templates for text buttons

local sideParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1)
}
local cornerParts = {
    top_left = v2(0, 0),
    top_right = v2(1, 0),
    bottom_left = v2(0, 1),
    bottom_right = v2(1, 1)
}

local borderSidePattern = 'textures/menu_button_frame_%s.dds'
local borderCornerPattern = 'textures/menu_button_frame_%s_corner.dds'

local borderResources = {}
local borderPieces = {}

for k in pairs(sideParts) do
    borderResources[k] = ui.texture{ path = borderSidePattern:format(k) }
end
for k in pairs(cornerParts) do
    borderResources[k] = ui.texture{ path = borderCornerPattern:format(k) }
end

for k in pairs(sideParts) do
    local horizontal = k == 'top' or k == 'bottom'
    borderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = borderResources[k],
            tileH = horizontal,
            tileV = not horizontal
        }
    }
end
for k in pairs(cornerParts) do
    borderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = borderResources[k]
        }
    }
end

local borderSize = 4
local borderV = v2(1, 1) * borderSize
local buttonTemplates = {}
buttonTemplates.horizontalLineButton = {
    type = ui.TYPE.Image,
    props = {
        resource = borderResources.top,
        tileH = true,
        tileV = false,
        size = v2(0, borderSize),
        relativeSize = v2(1, 0)
    }
}

buttonTemplates.verticalLineButton = {
    type = ui.TYPE.Image,
    props = {
        resource = borderResources.left,
        tileH = false,
        tileV = true,
        size = v2(borderSize, 0),
        relativeSize = v2(0, 1)
    }
}

buttonTemplates.bordersButton = {
    content = ui.content {},
}
for k, v in pairs(sideParts) do
    local horizontal = k == 'top' or k == 'bottom'
    local direction = horizontal and v2(1, 0) or v2(0, 1)
    buttonTemplates.bordersButton.content:add {
        template = borderPieces[k],
        props = {
            position = (direction - v) * borderSize,
            relativePosition = v,
            size = (v2(1, 1) - direction * 3) * borderSize,
            relativeSize = direction
        }
    }
end
for k, v in pairs(cornerParts) do
    buttonTemplates.bordersButton.content:add {
        template = borderPieces[k],
        props = {
            position = -v * borderSize,
            relativePosition = v,
            size = borderV
        }
    }
end
buttonTemplates.bordersButton.content:add {
    external = { slot = true },
    props = {
        position = borderV,
        size = borderV * -2,
        relativeSize = v2(1, 1)
    }
}

buttonTemplates.boxButton = {
    type = ui.TYPE.Container,
    content = ui.content{}
}
for k, v in pairs(sideParts) do
    local horizontal = k == 'top' or k == 'bottom'
    local direction = horizontal and v2(1, 0) or v2(0, 1)
    buttonTemplates.boxButton.content:add {
        template = borderPieces[k],
        props = {
            position = (direction + v) * borderSize,
            relativePosition = v,
            size = (v2(1, 1) - direction) * borderSize,
            relativeSize = direction
        }
    }
end
for k, v in pairs(cornerParts) do
    buttonTemplates.boxButton.content:add {
        template = borderPieces[k],
        props = {
            position = v * borderSize,
            relativePosition = v,
            size = borderV
        }
    }
end
buttonTemplates.boxButton.content:add {
    external = { slot = true },
    props = {
        position = borderV,
        relativeSize = v2(1, 1)
    }
}

for k, t in pairs(buttonTemplates) do
    templates[k] = t
end

-- Custom disabled template for settings renderers that look bad with a dark overlay
templates.disabled = {
    type = ui.TYPE.Container,
    props = {
        alpha = 0.4
    },
    content = ui.content {
        {
            props = {
                relativeSize = util.vector2(1, 1)
            },
            external = {
                slot = true
            }
        }
    }
}

-- Create a padding template with adjustable size in both axes
local function padding(sizeH, sizeV)
    local customPadding = {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                props = {
                    size = v2(sizeH, sizeV),
                },
            },
            {
                external = { slot = true },
                props = {
                    position = v2(sizeH, sizeV),
                    relativeSize = v2(1, 1),
                },
            },
            {
                props = {
                    position = v2(sizeH, sizeV),
                    relativePosition = v2(1, 1),
                    size = v2(sizeH, sizeV),
                },
            },
        }
    }
    return customPadding
end

-- Create a blank widget of specified size
local function padWidget(sizeH, sizeV)
    local padLayout = {
        name = 'padWidget',
        props = {size = v2(sizeH, sizeV)}
    }
    return padLayout
end

-- Get a usable color value from a fallback in openmw.cfg
local function configColor(setting)
    local v = core.getGMST('FontColor_color_' .. setting)
    local values = {}
    for i in v:gmatch('([^,]+)') do table.insert(values, tonumber(i)) end
    local color = util.color.rgb(values[1]/255, values[2]/255, values[3]/255)
    return color
end

-- Get all three variations for a font color
local function configFontColors(setting)
    local configValues = {
        default = setting,
        over = setting .. '_over',
        pressed = setting .. '_pressed'
    }
    local colors = {}
    for k,v in pairs(configValues) do
        colors[k] = configColor(v)
    end
    return colors
end

local interactiveTextColors = {
    normal = configFontColors('normal'),
    active = configFontColors('active'),
    disabled = configFontColors('disabled'),
    link = configFontColors('link'),
    journal_link = configFontColors('journal_link'),
    journal_topic = configFontColors('journal_topic'),
    answer = configFontColors('answer'),
    big_normal = configFontColors('big_normal'),
    big_link = configFontColors('big_link'),
    big_answer = configFontColors('big_answer')
}

local textColors = {
    header = configColor('header'),
    notify = configColor('notify'),
    big_header = configColor('big_header'),
    big_notify = configColor('big_notify'),
    background = configColor('background'),
    focus = configColor('focus'),
    health = configColor('health'),
    magic = configColor('magic'),
    fatigue = configColor('fatigue'),
    misc = configColor('misc'),
    weapon_fill = configColor('weapon_fill'),
    magic_fill = configColor('magic_fill'),
    positive = configColor('positive'),
    negative = configColor('negative'),
    count = configColor('count')
}

-- Shared code for making button layouts
-- TODO: Make this unable to be pressed multiple times per frame
local function createButton(parent, layout, updateColor, buttonFunction, args)
    layout.events = { 
        mousePress = async:callback(function(mouseEvent, data)
            if mouseEvent.button == 1 then
                updateColor(layout, 'pressed')
                ambient.playSound('Menu Click')
                parent:update()
            end
        end),
        mouseRelease = async:callback(function(mouseEvent, data)
            if mouseEvent.button == 1 then
                updateColor(layout, 'over')
                buttonFunction(table.unpack(args or {}))
                parent:update()
            end
        end),
        focusGain = async:callback(function()
            updateColor(layout, 'over')
            parent:update()
        end),
        focusLoss = async:callback(function()
            updateColor(layout, 'default')
            parent:update()
        end)
    }
    return layout
end

-- Create an image button to execute a specified function
local function createImageButton(parent, name, properties, buttonFunction, args)
    local buttonColors = {
        default = util.color.rgb(1.0, 1.0, 1.0),
        over = util.color.rgb(0.8, 0.8, 0.8),
        pressed = util.color.rgb(0.6, 0.6, 0.6)
    }
    local buttonLayout = {
        name = name,
        type = ui.TYPE.Image,
        props = properties,
        userData = {}
    }

    local button = createButton(parent, buttonLayout, 
    function(layout, state)
        layout.props.color = buttonColors[state]
    end, 
    buttonFunction, args)

    return button
end

--[[
-- Create a text box button to execute a specified function
local function createTextButton(parent, buttonText, color, name, properties, buttonFunction, args)
    local buttonColors = interactiveTextColors[color]
    local buttonLayout = {
        name = name,
        type = ui.TYPE.Container,
        template = templates.boxButton,
        props = properties,
        userData = {},
        content = ui.content {
            {
                name = 'vFlex',
                type = ui.TYPE.Flex,
                props = {},
                content = ui.content {
                    {
                        name = 'hFlex',
                        type = ui.TYPE.Flex,
                        props = {horizontal = true},
                        content = ui.content {
                            {
                                name = 'padding',
                                props = {size = v2(8,0)}
                            },
                            {
                                name = 'text',
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {text = buttonText, textColor = buttonColors.default}
                            },
                            {
                                name = 'padding',
                                props = {size = v2(8,0)}
                            }
                        }
                    },
                    {
                        name = 'padding',
                        props = {size = v2(0,1)}
                    }
                }
            }
        }
    }

    local button = createButton(parent, buttonLayout, 
    function(layout, state)
        layout.content.vFlex.content.hFlex.content.text.props.textColor = buttonColors[state]
    end, 
    buttonFunction, args)

    return button
end
]]--

-- Dumb nonsense to get around an OpenMW bug
local overlayResource = ui.texture{path = 'icons/default icon.dds', size = v2(0, 0)}

-- Create a text box button to execute a specified function
local function createTextButton(parent, buttonText, color, name, properties, size, buttonFunction, args)
    local buttonColors = interactiveTextColors[color]
    local buttonLayout = {
        name = name,
        type = ui.TYPE.Container,
        template = templates.boxButton,
        props = properties,
        userData = {},
        content = ui.content {
            {
                name = 'vFlex',
                type = ui.TYPE.Flex,
                props = {},
                content = ui.content {
                    {
                        name = 'hFlex',
                        type = ui.TYPE.Flex,
                        props = {horizontal = true},
                        content = ui.content {
                            {
                                name = 'padding',
                                props = {size = v2(8,0)}
                            },
                            {
                                name = 'text',
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {text = buttonText, textColor = buttonColors.default}
                            },
                            {
                                name = 'padding',
                                props = {size = v2(8,0)}
                            }
                        }
                    },
                    {
                        name = 'padding',
                        props = {size = v2(0,1)}
                    }
                }
            },
            {
                name = 'overlay',
                type = ui.TYPE.Image,
                props = {size = size, alpha = 0, resource = overlayResource}
            }
        }
    }

    local button = createButton(parent, buttonLayout, 
    function(layout, state)
        layout.content.vFlex.content.hFlex.content.text.props.textColor = buttonColors[state]
    end, 
    buttonFunction, args)

    return button
end

local function disableWidget(layout)
    if layout.userData == nil then
        return
    end
    if not layout.userData.isDisabled then
        if layout.events.focusLoss ~= nil then
            layout.events.focusLoss()
        end
        layout.userData.isDisabled = true
        layout.userData.disabledEvents = layout.events
        layout.events = nil
        layout.props.alpha = (layout.props.alpha or 1.0) * 0.25
    end
end

local function enableWidget(layout)
    if layout.userData == nil then
        return
    end
    if layout.userData.isDisabled then
        layout.userData.isDisabled = nil
        layout.events = layout.userData.disabledEvents
        layout.userData.disabledEvents = nil
        layout.props.alpha = layout.props.alpha * 4.0
    end
end

return {
    templates = templates,
    padding = padding,
    padWidget = padWidget,
    interactiveTextColors = interactiveTextColors,
    textColors = textColors,
    createTextButton = createTextButton,
    createImageButton = createImageButton,
    disableWidget = disableWidget,
    enableWidget = enableWidget
}