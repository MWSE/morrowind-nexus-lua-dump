local core = require('openmw.core')
local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local v2 = require("openmw.util").vector2

local mDef = require("scripts.fresh-loot.config.definition")

local L = core.l10n(mDef.MOD_NAME)

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

local function paddedBox(layout, thick)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            { external = { grow = 1 } },
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.End },
                content = ui.content {
                    {
                        template = thick and I.MWUI.templates.boxThick or I.MWUI.templates.box,
                        content = ui.content {
                            {
                                template = I.MWUI.templates.padding,
                                content = ui.content { layout },
                            },
                        }
                    }
                },
            }
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

local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return end
    if argument.max and number > argument.max then return end
    if argument.integer and math.floor(number) ~= number then return end
    return number
end

local defaultArgument = {
    disabled = false,
    integer = false,
    min = nil,
    max = nil,
}

I.Settings.registerRenderer(mDef.renderers.hotkeyKeyboard, function(value, set, argument)
    return disable(argument.disabled, paddedBox({
        template = I.MWUI.templates.textEditLine,
        props = {
            text = value and input.getKeyName(value) or '',
            size = v2(100, 0),
            textAlignH = ui.ALIGNMENT.End,
        },
        events = {
            keyPress = async:callback(function(e)
                set(e.code)
            end)
        }
    }, not value))
end)

I.Settings.registerRenderer(mDef.renderers.number, function(value, set, argument)
    argument = applyDefaults(argument, defaultArgument)
    local lastInput
    local inputBody = {
        {
            template = I.MWUI.templates.textEditLine,
            props = {
                text = tostring(value),
                size = v2(30, 0),
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
        }
    }
    if argument.isPercent then
        table.insert(inputBody, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = { text = "%" },
        })
    end
    local body = {
        paddedBox {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content(inputBody),
        },
    }
    if argument.locked then
        table.insert(body, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = { text = L("lockedByAPreset") },
        })
    end
    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        props = { arrange = ui.ALIGNMENT.End },
        content = ui.content(body)
    })
end)

I.Settings.registerRenderer(mDef.renderers.multilines, function(value, _, _)
    return paddedBox {
        template = I.MWUI.templates.textParagraph,
        props = {
            text = tostring(value),
            size = v2(250, 0),
            textAlignH = ui.ALIGNMENT.End,
        },
    }
end)
