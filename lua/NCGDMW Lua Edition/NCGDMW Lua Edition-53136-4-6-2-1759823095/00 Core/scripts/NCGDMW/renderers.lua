local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require("openmw.interfaces")

local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')

local L = core.l10n(mDef.MOD_NAME)
local maxSettingWidth = 200
local rangeLineHeight = 35
local growingInterval = { external = { grow = 1 } }
local stretchingLine = { template = I.MWUI.templates.horizontalLine, external = { stretch = 1 } }
local leftArrow = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local rightArrow = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }

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

local function padding(horizontal, vertical)
    return { props = { size = util.vector2(horizontal, vertical) } }
end

local function disable(disabled, layout)
    if not disabled then
        return layout
    end
    return {
        template = I.MWUI.templates.disabled,
        content = ui.content { layout },
    }
end

local function textBox(str, height)
    local props = {}
    if height then
        props.size = util.vector2(0, height)
    end
    return {
        type = ui.TYPE.Flex,
        props = props,
        content = ui.content {
            growingInterval,
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = { text = str },
            },
            growingInterval,
        }
    }
end

local function paddedBox(layout, height, thick)
    local props = {}
    if height then
        props.size = util.vector2(0, height)
    end
    return {
        type = ui.TYPE.Flex,
        props = props,
        content = ui.content {
            growingInterval,
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
                            }
                        }
                    }
                }
            },
            growingInterval,
        }
    }
end

-- THANKS:
-- https://gitlab.com/urm-openmw-mods/camerahim/-/blob/1a12e3f8c902291d5629f2d8cc8649eac315533a/Data%20Files/scripts/CameraHIM/settings.lua#L23-35
I.Settings.registerRenderer(mDef.renderers.hotkey, function(value, set, argument)
    argument = applyDefaults(argument, defaultNumberArgument)
    return disable(argument.disabled, paddedBox({
        template = I.MWUI.templates.textEditLine,
        props = {
            text = value and input.getKeyName(value) or '',
            size = util.vector2(100, 0),
            textAlignH = ui.ALIGNMENT.End,
        },
        events = {
            keyPress = async:callback(function(e)
                set(e.code)
            end)
        }
    }, false, not value))
end)

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

local lastRangeTestValue = 50

I.Settings.registerRenderer(mDef.renderers.range, function(value, set, argument)
    assert(type(value) == "table" and #value == 2, "Range renderer value must be a table of size 2")
    assert(type(value[1]) == "number" and type(value[2]) == "number", "Range renderer values must be numbers")
    argument = applyDefaults(argument, defaultNumberArgument)
    local lastFromInput
    local lastToInput

    local content = {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true, size = util.vector2(maxSettingWidth, 0) },
            content = ui.content {
                growingInterval,
                textBox(L("rangeFrom"), rangeLineHeight),
                padding(5, 0),
                paddedBox({
                    template = I.MWUI.templates.textEditLine,
                    props = {
                        text = tostring(value[1]),
                        size = util.vector2(25, 0),
                        textAlignH = ui.ALIGNMENT.End,
                    },
                    events = {
                        textChanged = async:callback(function(text)
                            lastFromInput = text
                        end),
                        focusLoss = async:callback(function()
                            if not lastFromInput then return end
                            if argument.desc then
                                argument.min = value[2]
                            else
                                argument.max = value[2]
                            end
                            local number = validateNumber(lastFromInput, argument)
                            if number and number ~= value then
                                value[1] = number
                            end
                            set(value)
                        end),
                    },
                }, rangeLineHeight),
                textBox(argument.percent and "%" or "", rangeLineHeight),
                padding(5, 0),
                textBox(L("rangeTo"), rangeLineHeight),
                padding(5, 0),
                paddedBox({
                    template = I.MWUI.templates.textEditLine,
                    props = {
                        text = tostring(value[2]),
                        size = util.vector2(25, 0),
                        textAlignH = ui.ALIGNMENT.End,
                    },
                    events = {
                        textChanged = async:callback(function(text)
                            lastToInput = text
                        end),
                        focusLoss = async:callback(function()
                            if not lastToInput then return end
                            if argument.desc then
                                argument.max = value[1]
                            else
                                argument.min = value[1]
                            end
                            local number = validateNumber(lastToInput, argument)
                            if number and number ~= value then
                                value[2] = number
                            end
                            set(value)
                        end),
                    },
                }, rangeLineHeight),
                textBox(argument.percent and "%" or "", rangeLineHeight),
            },
        },
    }

    if argument.log then
        table.insert(content, {
            type = ui.TYPE.Flex,
            props = { horizontal = true, size = util.vector2(maxSettingWidth, 0) },
            content = ui.content {
                growingInterval,
                textBox(L("rangeTest", {
                    factor = lastRangeTestValue == ""
                            and "--"
                            or string.format("%.2f", (argument.percent and 100 or 1) * mDef.logRangeFunctions[argument.log](lastRangeTestValue, value[1], value[2])),
                    unit = argument.percent and "%" or "",
                }), rangeLineHeight),
                padding(5, 0),
                paddedBox({
                    template = I.MWUI.templates.textEditLine,
                    props = {
                        text = tostring(lastRangeTestValue),
                        size = util.vector2(25, 0),
                        textAlignH = ui.ALIGNMENT.End,
                    },
                    events = {
                        textChanged = async:callback(function(text)
                            local number = text and validateNumber(text, { integer = true, min = 0, max = 1000 })
                            if number then
                                lastRangeTestValue = number
                            else
                                lastRangeTestValue = ""
                            end
                            set(value)
                        end),
                    },
                }, rangeLineHeight),
            }
        })
    end

    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        content = ui.content(content)
    })
end)

local lastDecayTestValue = 50
local lastDecayHoursTestValue

local function setDecayHours(value)
    lastDecayHoursTestValue = (value > 0 and lastDecayTestValue) and mCfg.decayTimeBaseInHours / (value * lastDecayTestValue / 100)
end

I.Settings.registerRenderer(mDef.renderers.decayRate, function(value, set, argument)
    argument = applyDefaults(argument, defaultNumberArgument)
    local l10n = core.l10n(argument.l10n)
    local index
    local itemCount = #argument.items
    for i, item in ipairs(argument.items) do
        if item == value then
            index = i
        end
    end
    setDecayHours(argument.values[index])
    local label = l10n(tostring(value))
    local labelColor
    if index == nil then
        labelColor = util.color.rgb(1, 0, 0)
    end
    local body = {
        type = ui.TYPE.Flex,
        props = { arrange = ui.ALIGNMENT.End },
        content = ui.content {
            paddedBox({
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
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
                                    set(argument.items[#argument.items])
                                    return
                                end
                                index = (index - 2) % itemCount + 1
                                set(argument.items[index])
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
                        external = {
                            grow = 1,
                        },
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
                                    set(argument.items[1])
                                    return
                                end
                                index = (index) % itemCount + 1
                                set(argument.items[index])
                            end),
                        },
                    },
                },
            }),
            padding(0, 20),
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true, size = util.vector2(maxSettingWidth, 0) },
                content = ui.content {
                    growingInterval,
                    textBox(L("decaySkillTest"), rangeLineHeight),
                    padding(5, 0),
                    paddedBox({
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = tostring(lastDecayTestValue),
                            size = util.vector2(25, 0),
                            textAlignH = ui.ALIGNMENT.End,
                        },
                        events = {
                            textChanged = async:callback(function(text)
                                local number = text and validateNumber(text, { integer = true, min = 1, max = 999 })
                                if number then
                                    lastDecayTestValue = number
                                else
                                    lastDecayTestValue = nil
                                end
                                setDecayHours(argument.values[index])
                                set(value)
                            end),
                        },
                    }, rangeLineHeight),
                }
            },
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = L("decayTimeTest", {
                        days = lastDecayHoursTestValue
                                and tostring(math.floor(lastDecayHoursTestValue / 24))
                                or "--",
                        hours = lastDecayHoursTestValue
                                and tostring(util.round(lastDecayHoursTestValue % 24))
                                or "--",
                    })
                },
            },
        }
    }
    return disable(argument.disabled, body)
end)

local registerMultiSelectNumberRenderer = function(settingKey, allItems)
    I.Settings.registerRenderer(settingKey, function(data, set, argument)
        data = data or {}
        local items = {}
        local lines = {}

        local getAvailableItems = function()
            local available = {}
            local taken = {}
            for _, item in ipairs(items) do
                taken[item.key] = true
            end
            for _, item in ipairs(allItems) do
                if not taken[item.key] then
                    table.insert(available, item)
                end
            end
            return available
        end

        local getNextItem = function(key, forward)
            local available = {}
            local taken = {}
            for _, item in ipairs(items) do
                if item.key ~= key then
                    taken[item.key] = true
                end
            end
            local index
            for _, item in ipairs(allItems) do
                if not taken[item.key] then
                    if item.key == key then
                        index = #available + 1
                    end
                    table.insert(available, item)
                end
            end
            return available[(index + (forward and 0 or -2)) % #available + 1]
        end

        local lastInput

        for index, item in pairs(data) do
            table.insert(items, { key = item.key, name = item.name, value = item.value })

            table.insert(lines, {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                external = { stretch = 1 },
                content = ui.content {
                    growingInterval,
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = leftArrow,
                            size = util.vector2(1, 1) * 12,
                        },
                        events = {
                            mouseClick = async:callback(function()
                                items[index] = getNextItem(item.key, false)
                                set(items)
                            end),
                        },
                    },
                    { template = I.MWUI.templates.interval },
                    {
                        template = I.MWUI.templates.textNormal,
                        props = { text = item.name },
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
                                items[index] = getNextItem(item.key, true)
                                set(items)
                            end),
                        },
                    },
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = tostring(item.value),
                            size = util.vector2(50, 0),
                            textAlignH = ui.ALIGNMENT.End,
                        },
                        events = {
                            textChanged = async:callback(function(value)
                                lastInput = value
                            end),
                            focusLoss = async:callback(function()
                                if not lastInput then return end
                                local number = validateNumber(lastInput, argument)
                                if number and number ~= data then
                                    items[index].value = number
                                end
                                set(items)
                                lastInput = nil
                            end),
                        }
                    },
                    { props = { size = util.vector2(10, 0) } },
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = "x",
                            textSize = 14,
                            textColor = util.color.rgb(.8, .3, .4),
                        },
                        events = {
                            mouseClick = async:callback(function()
                                table.remove(items, index)
                                set(items)
                            end),
                        }
                    },
                },
            })
        end

        return disable(argument.disabled, paddedBox({
            type = ui.TYPE.Flex,
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = { horizontal = true, size = util.vector2(maxSettingWidth, 0) },
                    external = { stretch = 1 },
                    content = ui.content {
                        growingInterval,
                        {
                            type = ui.TYPE.Text,
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = "+",
                                textSize = 32,
                            },
                            events = {
                                mouseClick = async:callback(function()
                                    local available = getAvailableItems()
                                    if #available > 0 then
                                        items[#items + 1] = available[1]
                                        set(items)
                                    end
                                end),
                            }
                        },
                    },
                },
                stretchingLine,
                table.unpack(lines),
            },
        }))
    end)

end

local skillItems = {}
local attributeItems = {}
for _, stat in pairs(core.stats.Skill.records) do
    table.insert(skillItems, { key = stat.id, name = stat.name, value = 1000 })
end
for _, stat in pairs(core.stats.Attribute.records) do
    table.insert(attributeItems, { key = stat.id, name = stat.name, value = 1000 })
end

registerMultiSelectNumberRenderer(mDef.renderers.perSkillUncapper, skillItems)
registerMultiSelectNumberRenderer(mDef.renderers.perAttributeUncapper, attributeItems)
