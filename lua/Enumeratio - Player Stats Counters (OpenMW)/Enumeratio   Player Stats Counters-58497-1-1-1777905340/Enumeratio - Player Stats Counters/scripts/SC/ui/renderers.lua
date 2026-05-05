local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require("openmw.interfaces")

local mDef = require('scripts.SC.config.definition')

local growingInterval = { external = { grow = 1 } }

local defaultNumberArgument = {
    disabled = false,
    integer = false,
    min = nil,
    max = nil,
}

local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return argument.min end
    if argument.max and number > argument.max then return argument.max end
    if argument.integer and math.floor(number) ~= number then return math.floor(number) end
    return number
end

local function applyDefaults(argument, defaults)
    if not argument then return defaults end
    local result = {}
    for k, v in pairs(defaults) do result[k] = v end
    for k, v in pairs(argument) do result[k] = v end
    return result
end

local function disable(disabled, layout)
    if not disabled then return layout end
    return {
        template = I.MWUI.templates.disabled,
        content = ui.content { layout },
    }
end

local function paddedBox(layout)
    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            growingInterval,
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.End },
                content = ui.content {
                    {
                        template = I.MWUI.templates.box,
                        content = ui.content {
                            {
                                template = I.MWUI.templates.padding,
                                content = ui.content { layout },
                            }
                        }
                    }
                }
            },
            growingInterval,
        }
    }
end

I.Settings.registerRenderer(mDef.renderers.number, function(value, set, argument)
    argument = applyDefaults(argument, defaultNumberArgument)
    local lastInput
    return disable(argument.disabled, paddedBox {
        template = I.MWUI.templates.textEditLine,
        props = {
            text = tostring(value),
            size = util.vector2(30, 0),
            textAlignH = ui.ALIGNMENT.End,
        },
        events = {
            textChanged = async:callback(function(text)
                lastInput = text
            end),
            focusLoss = async:callback(function()
                if not lastInput then return end
                local number = validateNumber(lastInput, argument)
                set(number and number or value)
            end),
        },
    })
end)

-- Reset button renderer: displays a clickable text button.
-- Value cycle: false → true (clicked) → "done" (processed by player.lua).
-- Renderer shows "Done!" when value is "done", label otherwise.
I.Settings.registerRenderer(mDef.renderers.resetButton, function(value, set, argument)
    local label = (argument and argument.label) or "Reset"
    local isDone = value == "done"
    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            growingInterval,
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.End },
                content = ui.content {
                    {
                        template = I.MWUI.templates.box,
                        content = ui.content {
                            {
                                template = I.MWUI.templates.padding,
                                content = ui.content {
                                    {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                            text = isDone and "Done!" or label,
                                            textAlignH = ui.ALIGNMENT.Center,
                                        },
                                        events = {
                                            mouseClick = async:callback(function()
                                                if not isDone then
                                                    set(true)
                                                else
                                                    set(false)
                                                end
                                            end),
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            growingInterval,
        },
    }
end)
