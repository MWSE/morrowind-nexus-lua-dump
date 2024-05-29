local async = require("openmw.async")
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require("openmw.core")

local normalTextColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255)

-- part from openmw code
local function applyDefaults(argument, defaults)
    if not argument then return defaults end
    if pairs(defaults) and pairs(argument) then
        local result = {}
        for k, v in pairs(defaults) do
            result[k] = v
        end
        for k, v in pairs(argument) do
            result[k] = v
        end
        return result
    end
    return argument
end

local function paddedBox(layout)
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content { layout },
            },
        }
    }
end

local function disable(disabled, layout)
    if disabled then
        return {
            template = I.MWUI.templates.disabled,
            content = ui.content {
                layout,
            },
        }
    else
        return layout
    end
end

I.Settings.registerRenderer('mwrbd_text', function(value, set, argument)
    argument = applyDefaults(argument, {
        l10n = "morrowind_world_randomizer",
        disabled = false,
        text = nil,
    })
    local l10n = core.l10n(argument.l10n)
    local data = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT.End,
            size = util.vector2(400, 0),
        },
        content = ui.content{
            {
                type = ui.TYPE.Text,
                props = {
                    text = argument.text and l10n(argument.text) or "",
                    textSize = 16,
                    textAlignH = ui.ALIGNMENT.Start,
                    textColor = normalTextColor,
                    multiline = true,
                    wordWrap = true,
                },
            },
        },
    }
    return disable(argument.disabled, data)
end)