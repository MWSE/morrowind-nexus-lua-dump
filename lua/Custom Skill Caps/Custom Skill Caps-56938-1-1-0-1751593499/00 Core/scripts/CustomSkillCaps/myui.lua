-- Helper UI functions that aren't mod-specific
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

-- Templates

templates = {}

-- Custom disabled template for settings renderers that look bad with a dark overlay
templates.disabled = {
    type = ui.TYPE.Container,
    props = {
        alpha = 0.4
    },
    content = ui.content {
        {
            props = {
                relativeSize = v2(1, 1)
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

return {
    templates = templates,
    padding = padding,
    padWidget = padWidget,
    interactiveTextColors = interactiveTextColors,
    textColors = textColors
}