local core = require('openmw.core')
local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local v2 = util.vector2

local mDef = require("scripts.SBMR.config.definition")

local L = core.l10n(mDef.MOD_NAME)
local hGap = { props = { size = v2(5, 0) } }
local vGap = { props = { size = v2(0, 5) } }

local defaultArgument = {
    disabled = false,
    integer = false,
}

local defaultRangeArgument = {
    disabled = false,
}

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

local function paddedBox(layout, title)
    local content = {
        {
            template = I.MWUI.templates.box,
            content = ui.content {
                {
                    template = I.MWUI.templates.padding,
                    content = ui.content {
                        {
                            type = ui.TYPE.Flex,
                            props = { horizontal = true },
                            content = ui.content { layout },
                        }
                    }
                },
            },
        }
    }
    if title then
        table.insert(content, 1, hGap)
        table.insert(content, 1, {
            template = I.MWUI.templates.padding,
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = { text = title },
                },
            },
        })
    end
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true, arrange = ui.ALIGNMENT.End },
        content = ui.content(content)
    }
end

local function disable(disabled, layout)
    if not disabled then return layout end
    return {
        template = I.MWUI.templates.disabled,
        content = ui.content { layout },
    }
end

local function percent(isPercent, layout)
    if not isPercent then return layout end
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true, arrange = ui.ALIGNMENT.End },
        content = ui.content({
            layout,
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = { text = "%" },
            }
        }),
    }
end

local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return argument.min end
    if argument.max and number > argument.max then return argument.max end
    if argument.integer then return math.floor(number) end
    return number
end

local function addArgumentNotes(argument, body)
    if not argument.notes then return end
    for _, note in ipairs(argument.notes) do
        table.insert(body, vGap)
        table.insert(body, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = { text = note },
        })
    end
end

I.Settings.registerRenderer(mDef.renderers.number, function(value, set, argument)
    argument = applyDefaults(argument, defaultArgument)
    local lastInput
    local body = {
        paddedBox(percent(argument.isPercent, {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content({
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
            }),
        }))
    }

    addArgumentNotes(argument, body)

    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        props = { arrange = ui.ALIGNMENT.End },
        content = ui.content(body),
    })
end)

I.Settings.registerRenderer(mDef.renderers.range, function(values, set, argument)
    argument = applyDefaults(argument, defaultRangeArgument)
    local lastFromInput
    local lastToInput

    local valuesContent = {
        { external = { grow = 1 } },
        paddedBox(percent(argument.isPercent, {
            template = I.MWUI.templates.textEditLine,
            props = {
                text = tostring(values.from),
                size = v2(30, 0),
                textAlignH = ui.ALIGNMENT.End,
            },
            events = {
                textChanged = async:callback(function(text)
                    lastFromInput = text
                end),
                focusLoss = async:callback(function()
                    if not lastFromInput then return end
                    local number = validateNumber(lastFromInput, { min = argument.min, max = values.to, integer = true })
                    set(number and {
                        from = number,
                        to = values.to,
                        actual = values.actual,
                    } or values)
                end),
            },
        }), L("fromRange")),
        hGap,
        paddedBox(percent(argument.isPercent, {
            template = I.MWUI.templates.textEditLine,
            props = {
                text = tostring(values.to),
                size = v2(30, 0),
                textAlignH = ui.ALIGNMENT.End,
            },
            events = {
                textChanged = async:callback(function(text)
                    lastToInput = text
                end),
                focusLoss = async:callback(function()
                    if not lastToInput then return end
                    local number = validateNumber(lastToInput, { min = values.from, max = argument.max, integer = true })
                    set(number and {
                        from = values.from,
                        to = number,
                        actual = values.actual
                    } or values)
                end),
            },
        }), L("toRange")),
    }
    local body = {
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.End,
            },
            content = ui.content(disable(argument.disabled, valuesContent)),
        }
    }
    addArgumentNotes(argument, body)
    return {
        type = ui.TYPE.Flex,
        props = {
            size = v2(200, 0),
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content(body),
    }
end)
