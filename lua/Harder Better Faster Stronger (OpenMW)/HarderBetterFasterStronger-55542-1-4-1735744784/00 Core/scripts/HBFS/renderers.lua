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
    },
}

local leftArrow = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local rightArrow = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }

I.Settings.registerRenderer('percentAndIncrease', function(values, set, argument)
    argument = applyDefaults(argument, defaultPercentArgument)
    if not argument.l10n then
        error('"percentAndIncrease" renderer requires a "l10n" argument')
    end
    local l10n = core.l10n(argument.l10n)
    local lastBaseInput
    local lastIncreaseInput
    local hasActualPercent = values.actual and (argument.disabled or argument.withIncrease or (argument.items and values.selected ~= argument.defaultValue))
    local hasHeader = argument.allowHeaders and hasActualPercent
    local isUnused = argument.disabled or not values.selected

    local valuesContent = {}

    local presetContent
    if argument.items then
        local index
        local itemCount = #argument.items
        for i, item in ipairs(argument.items) do
            if item == values.selected then
                index = i
            end
        end
        local label = l10n(tostring(values.selected))
        local labelColor
        if index == nil then
            labelColor = util.color.rgb(1, 0, 0)
        end
        presetContent = {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = leftArrow,
                        size = util.vector2(1, 1) * 12,
                    },
                    events = {
                        mouseClick = async:callback(function()
                            if not index then
                                set {
                                    selected = argument.items[#argument.items],
                                    base = argument.values[#argument.items].base,
                                    increase = argument.values[#argument.items].increase,
                                    actual = values.actual
                                }
                                return
                            end
                            index = (index - 2) % itemCount + 1
                            set {
                                selected = argument.items[index],
                                base = argument.values[index].base,
                                increase = argument.values[index].increase,
                                actual = values.actual
                            }
                        end),
                    },
                },
                { template = I.MWUI.templates.interval },
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = label,
                        textColor = labelColor,
                    },
                    external = { grow = 1 },
                },
                { template = I.MWUI.templates.interval },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = rightArrow,
                        size = util.vector2(1, 1) * 12,
                    },
                    events = {
                        mouseClick = async:callback(function()
                            if not index then
                                set {
                                    selected = argument.items[1],
                                    base = argument.values[1].base,
                                    increase = argument.values[1].increase,
                                    actual = values.actual
                                }
                                return
                            end
                            index = (index) % itemCount + 1
                            set {
                                selected = argument.items[index],
                                base = argument.values[index].base,
                                increase = argument.values[index].increase,
                                actual = values.actual
                            }
                        end),
                    },
                },
            },
        }
    elseif argument.isGlobal then
        local checkBox = paddedBox({
            template = I.MWUI.templates.textNormal,
            props = {
                text = core.l10n("Interface")(values.selected and argument.trueLabel or argument.falseLabel),
            },
        })
        checkBox.events = {
            mouseClick = async:callback(function() set {
                selected = not values.selected,
                base = values.base,
                increase = values.increase,
                actual = values.actual
            } end)
        }
        table.insert(valuesContent, disable(argument.disabled, checkBox))
        table.insert(valuesContent, hGap)
    end

    if not argument.items or hasActualPercent then
        table.insert(valuesContent, disable(isUnused or argument.items, paddedBox({
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
                            selected = values.selected,
                            base = number,
                            increase = values.increase,
                            actual = values.actual
                        }
                    end
                end),
            },
        }, hasHeader and l10n(isUnused and "unusedPercentValue" or "basePercentValue") or nil)))
    end

    if argument.withIncrease then
        table.insert(valuesContent, hGap)
        table.insert(valuesContent, disable(isUnused or argument.items, paddedBox({
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
                            selected = values.selected,
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
        table.insert(valuesContent, hGap)
        table.insert(valuesContent, paddedBox({
            template = I.MWUI.templates.textNormal,
            props = {
                text = tostring(values.actual),
                size = util.vector2(20, 0),
                textColor = actualPercentColor,
            },
        }, (argument.allowHeaders and l10n("actualPercentValue") or nil)))
    end

    local body = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content(valuesContent),
        }
    }

    if presetContent then
        table.insert(body, 1, disable(argument.disabled, paddedBox(presetContent)))
    end

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