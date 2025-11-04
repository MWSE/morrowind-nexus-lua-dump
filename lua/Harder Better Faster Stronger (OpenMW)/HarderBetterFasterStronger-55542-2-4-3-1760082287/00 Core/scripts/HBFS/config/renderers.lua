local core = require('openmw.core')
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')

local mDef = require('scripts.HBFS.config.definition')

local headerPercentColor = util.color.rgb(0.863, 0.78, 0.616)
local actualPercentColor = util.color.rgb(0.376, 0.439, 0.792)

local textNormalSize = 16
local normalColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255)

local textEditLine = {
    type = ui.TYPE.TextEdit,
    props = {
        autoSize = true,
        textAlignH = ui.ALIGNMENT.End,
        textSize = textNormalSize,
        textColor = normalColor,
        multiline = false,
    },
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

local function paddedBox(layout, title, isPercent)
    local text = {
        layout
    }
    if isPercent then
        table.insert(text, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = { text = "%" },
        })
    end
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
                            content = ui.content(text),
                        }
                    }
                },
            },
        }
    }
    table.insert(content, 1, {
        template = I.MWUI.templates.padding,
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = title or "",
                    textColor = headerPercentColor,
                },
            },
        },
    })
    return {
        type = ui.TYPE.Flex,
        props = { size = util.vector2(50, 0), arrange = ui.ALIGNMENT.End },
        content = ui.content(content)
    }
end

local function disable(disabled, layout)
    if disabled then
        return {
            template = I.MWUI.templates.disabled,
            content = ui.content { layout },
        }
    else
        return layout
    end
end

local hGap = { type = ui.TYPE.Flex, props = { size = util.vector2(10, 0) } }

local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return end
    if argument.max and number > argument.max then return end
    number = math.floor(number * 10) / 10
    return number
end

local defaultPercentArgument = {
    disabled = false,
    withIncrease = false,
    allowHeaders = true,
    base = {
        min = nil,
        max = nil,
    },
    increase = {
        min = nil,
        max = nil,
    },
}

I.Settings.registerRenderer(mDef.renderers.percentAndIncrease, function(values, set, argument)
    local l10n = core.l10n(argument.l10n)
    if argument.requiresOMW50 then
        return {
            template = I.MWUI.templates.textNormal,
            props = { text = l10n("requiresOpenmw50") },
        }
    end

    argument = applyDefaults(argument, defaultPercentArgument)
    if not argument.l10n then
        error(string.format("\"%s\" renderer requires a \"l10n\" argument", mDef.renderers.percentAndIncrease))
    end
    local lastBaseInput
    local lastIncreaseInput
    local hasHeader = argument.allowHeaders and argument.withIncrease

    local valuesContent = {}

    table.insert(valuesContent, disable(argument.disabled, paddedBox({
        template = textEditLine,
        props = {
            text = tostring(values.base),
            size = util.vector2(40, 0),
        },
        events = {
            textChanged = async:callback(function(text)
                lastBaseInput = text
            end),
            focusLoss = async:callback(function()
                if not lastBaseInput then return end
                local number = validateNumber(lastBaseInput, argument.base)
                set(number and {
                    base = number,
                    increase = values.increase,
                    actual = values.actual,
                } or values)
            end),
        },
    }, hasHeader and l10n("basePercentValue") or nil, true)))

    if argument.withIncrease then
        table.insert(valuesContent, hGap)
        table.insert(valuesContent, disable(argument.disabled, paddedBox({
            template = textEditLine,
            props = {
                text = tostring(values.increase),
                size = util.vector2(40, 0),
            },
            events = {
                textChanged = async:callback(function(text)
                    lastIncreaseInput = text
                end),
                focusLoss = async:callback(function()
                    if not lastIncreaseInput then return end
                    local number = validateNumber(lastIncreaseInput, argument.increase)
                    set(number and {
                        base = values.base,
                        increase = number,
                        actual = values.actual
                    } or values)
                end),
            },
        }, hasHeader and l10n("increasePercentValue") or nil, true)))

        if not argument.perActor then
            table.insert(valuesContent, hGap)
            table.insert(valuesContent, paddedBox({
                template = I.MWUI.templates.textNormal,
                props = {
                    text = tostring(values.actual),
                    size = util.vector2(40, 0),
                    textColor = actualPercentColor,
                },
            }, argument.allowHeaders and l10n("actualPercentValue") or nil, true))
        end
    end

    local body = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content(valuesContent),
        }
    }

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = util.vector2(250, 0),
        },
        content = ui.content {
            { external = { grow = 1 } },
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.End },
                content = ui.content(body),
            }
        }
    }
end)
