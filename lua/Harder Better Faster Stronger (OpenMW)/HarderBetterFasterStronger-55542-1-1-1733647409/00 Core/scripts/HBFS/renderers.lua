local core = require('openmw.core')
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')

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

local function paddedBox(layout, title)
    local content = {
        {
            template = I.MWUI.templates.box,
            content = ui.content {
                {
                    template = I.MWUI.templates.padding,
                    content = ui.content { layout },
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
        props = { size = util.vector2(40, 0), arrange = ui.ALIGNMENT.End },
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
    if math.floor(number) ~= number then return end
    return number
end

local defaultPercentArgument = {
    disabled = false,
    trueLabel = 'Yes',
    falseLabel = 'No',
    isGlobal = false,
    withIncrease = false,
    allowHeaders = true,
    base = {
        min = nil,
        max = nil,
    },
    increase = {
        min = nil,
        max = nil,
    }
}

I.Settings.registerRenderer('percentAndIncrease', function(values, set, argument)
    argument = applyDefaults(argument, defaultPercentArgument)
    if not argument.l10n then
        error('"percentAndIncrease" renderer requires a "l10n" argument')
    end
    local l10n = core.l10n(argument.l10n)
    local lastBaseInput
    local lastIncreaseInput
    local hasHeader = argument.allowHeaders and (argument.disabled or argument.withIncrease)
    local isUnused = argument.disabled or not values.checked
    local hasActualPercent = values.actual and (argument.disabled or argument.withIncrease)

    local content = { { external = { grow = 1 } } }

    if argument.isGlobal then
        local checkBox = paddedBox({
            template = I.MWUI.templates.textNormal,
            props = {
                text = core.l10n("Interface")(values.checked and argument.trueLabel or argument.falseLabel),
            },
        })
        checkBox.events = {
            mouseClick = async:callback(function() set {
                checked = not values.checked,
                base = values.base,
                increase = values.increase,
                actual = values.actual
            } end)
        }
        table.insert(content, disable(argument.disabled, checkBox))
        table.insert(content, hGap)
    end

    table.insert(content, disable(isUnused, paddedBox({
        template = textEditLine,
        props = {
            text = tostring(values.base),
            size = util.vector2(30, 0),
        },
        events = {
            textChanged = async:callback(function(text)
                lastBaseInput = text
            end),
            focusLoss = async:callback(function()
                if not lastBaseInput then return end
                local number = validateNumber(lastBaseInput, argument.base)
                if not number then
                    set(values)
                end
                if number and number ~= values.base then
                    set {
                        checked = values.checked,
                        base = number,
                        increase = values.increase,
                        actual = values.actual
                    }
                end
            end),
        },
    }, hasHeader and l10n(isUnused and "unusedPercentValue" or "basePercentValue") or nil)))

    if argument.withIncrease then
        table.insert(content, hGap)
        table.insert(content, disable(isUnused, paddedBox({
            template = textEditLine,
            props = {
                text = tostring(values.increase),
                size = util.vector2(20, 0),
            },
            events = {
                textChanged = async:callback(function(text)
                    lastIncreaseInput = text
                end),
                focusLoss = async:callback(function()
                    if not lastIncreaseInput then return end
                    local number = validateNumber(lastIncreaseInput, argument.increase)
                    if not number then
                        set(values)
                    end
                    if number and number ~= values.increase then
                        set {
                            checked = values.checked,
                            base = values.base,
                            increase = number,
                            actual = values.actual
                        }
                    end
                end),
            },
        }, hasHeader and l10n(isUnused and "unusedPercentValue" or "increasePercentValue") or nil)))
    end

    if hasActualPercent then
        table.insert(content, hGap)
        table.insert(content, paddedBox({
            template = I.MWUI.templates.textNormal,
            props = {
                text = tostring(values.actual),
                size = util.vector2(20, 0),
                textColor = actualPercentColor,
            },
        }, (argument.allowHeaders and l10n("actualPercentValue"))))
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = util.vector2(250, 0),
        },
        content = ui.content(content),
    }
end)