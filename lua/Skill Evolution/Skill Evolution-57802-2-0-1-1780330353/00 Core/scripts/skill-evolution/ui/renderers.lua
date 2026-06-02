local core = require('openmw.core')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require("openmw.interfaces")

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mHelpers = require('scripts.skill-evolution.util.helpers')

local L = core.l10n(mDef.MOD_NAME)
local maxSettingWidth = 200
local lineHeight = 30
local numberWidth = 30
local growingInterval = { external = { grow = 1 } }
local stretchingLine = { template = I.MWUI.templates.horizontalLine, external = { stretch = 1 } }
local leftArrow = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local rightArrow = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }
local noteColor = util.color.rgb(0.589, 0.481, 0.28)

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
    if argument.max and number ~= 0 and number > argument.max then return argument.max end
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

local function note(str)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = { text = str, textSize = 14, textColor = noteColor },
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

local function numberInput(value, set, argument)
    argument = applyDefaults(argument, defaultNumberArgument)
    local lastInput
    return paddedBox {
        template = I.MWUI.templates.textEditLine,
        props = {
            text = tostring(value),
            size = util.vector2(numberWidth, 0),
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
end

I.Settings.registerRenderer(mDef.renderers.number, function(value, set, argument)
    return disable(argument.disable, numberInput(value, set, argument))
end)

I.Settings.registerRenderer(mDef.renderers.skillGains, function(value, set, argument)
    local content = {}
    local prop = argument.config
    for useType, gain in pairs(prop.gains) do
        content[#content + 1] = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                textBox(L("skillUseGain", {
                    useType = prop.isCustom and gain.key or mDef.getSkillUseTypeName(gain.key),
                }), lineHeight),
                padding(5, 0),
                numberInput(
                        value[useType],
                        function(number)
                            value[useType] = number
                            set(value)
                        end,
                        argument),
            },
        }
        local message
        if not prop.isCustom then
            local isZero = false
            local modded = gain.modded
            if modded == 0 then
                isZero = true
            elseif mHelpers.areFloatEqual(modded, mCfg.skillZeroGainHack) then
                modded = 0
            end
            if isZero then
                message = L("skillUseGainModdedZero")
            elseif not mHelpers.areFloatEqual(modded, gain.original) then
                message = L("skillUseGainModded", { original = gain.original, modded = modded })
            elseif not mHelpers.areFloatEqual(value[useType], modded) then
                message = L("skillUseGainVanilla", { original = gain.original })
            end
        elseif not mHelpers.areFloatEqual(value[useType], gain.default) then
            message = L("skillUseGainDefault", { default = gain.default })
        end
        if message then
            content[#content + 1] = note(message)
        end
    end
    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        props = { arrange = ui.ALIGNMENT.End },
        content = ui.content(content)
    })
end)

local lastRangeTestValue = 50

I.Settings.registerRenderer(mDef.renderers.range, function(value, set, argument)
    argument = applyDefaults(argument, defaultNumberArgument)
    local lastFromInput
    local lastToInput
    local rangedDisabled = false

    local content = {}

    if argument.togglable then
        rangedDisabled = not value.enabled
        local box = paddedBox({
            template = I.MWUI.templates.padding,
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = core.l10n("Interface")(value.enabled and "Yes" or "No")
                    },
                },
            },
        }, lineHeight)
        box.events = {
            mouseClick = async:callback(function()
                value.enabled = not value.enabled
                set(value)
            end)
        }
        table.insert(content, {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content {
                textBox(L("scalingEnabled"), lineHeight),
                padding(5, 0),
                box,
            }
        })
    end

    table.insert(content, disable(rangedDisabled, {
        type = ui.TYPE.Flex,
        props = { horizontal = true, size = util.vector2(maxSettingWidth, 0) },
        content = ui.content {
            growingInterval,
            textBox(L("rangeFrom"), lineHeight),
            padding(5, 0),
            paddedBox({
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = tostring(value.from),
                    size = util.vector2(numberWidth, 0),
                    textAlignH = ui.ALIGNMENT.End,
                },
                events = {
                    textChanged = async:callback(function(text)
                        lastFromInput = text
                    end),
                    focusLoss = async:callback(function()
                        if not lastFromInput then return end
                        if argument.desc then
                            argument.min = value.to
                        else
                            argument.max = value.to
                        end
                        local number = validateNumber(lastFromInput, argument)
                        if number and number ~= value then
                            value.from = number
                        end
                        set(value)
                    end),
                },
            }, lineHeight),
            textBox(argument.percent and "%" or "", lineHeight),
            padding(5, 0),
            textBox(L("rangeTo"), lineHeight),
            padding(5, 0),
            paddedBox({
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = tostring(value.to),
                    size = util.vector2(numberWidth, 0),
                    textAlignH = ui.ALIGNMENT.End,
                },
                events = {
                    textChanged = async:callback(function(text)
                        lastToInput = text
                    end),
                    focusLoss = async:callback(function()
                        if not lastToInput then return end
                        if argument.desc then
                            argument.max = value.from
                        else
                            argument.min = value.from
                        end
                        local number = validateNumber(lastToInput, argument)
                        if number and number ~= value then
                            value.to = number
                        end
                        set(value)
                    end),
                },
            }, lineHeight),
            textBox(argument.percent and "%" or "", lineHeight),
        },
    }))

    if argument.log then
        table.insert(content, {
            type = ui.TYPE.Flex,
            props = { horizontal = true, size = util.vector2(maxSettingWidth, 0) },
            content = ui.content {
                growingInterval,
                textBox(L("rangeTest", {
                    factor = lastRangeTestValue == ""
                            and "--"
                            or string.format("%.2f", (argument.percent and 100 or 1) * mDef.logRangeFunctions[argument.log](lastRangeTestValue, value.from, value.to)),
                    unit = argument.percent and "%" or "",
                }), lineHeight),
                padding(5, 0),
                paddedBox({
                    template = I.MWUI.templates.textEditLine,
                    props = {
                        text = tostring(lastRangeTestValue),
                        size = util.vector2(numberWidth, 0),
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
                }, lineHeight),
            }
        })
    end

    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        props = { arrange = ui.ALIGNMENT.End },
        content = ui.content(content)
    })
end)

local lastDecayTestValue = 50
local lastDecayHoursTestValue

local function setDecayHours(value)
    lastDecayHoursTestValue = (value > 0 and lastDecayTestValue) and mCfg.decayTimeBaseInHours / (value * math.min(1, lastDecayTestValue / 100) ^ 2)
end

I.Settings.registerRenderer(mDef.renderers.decayRate, function(value, set, argument)
    argument = applyDefaults(argument, defaultNumberArgument)
    local l10n = core.l10n(argument.l10n)
    local index = mHelpers.indexOf(argument.items, value)
    setDecayHours(argument.values[value])
    local label = l10n(tostring(value))
    local labelColor
    if not index then
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
                                index = (index - 2) % #argument.items + 1
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
                                index = (index) % #argument.items + 1
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
                    textBox(L("decaySkillTest"), lineHeight),
                    padding(5, 0),
                    paddedBox({
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = lastDecayTestValue and tostring(lastDecayTestValue) or "",
                            size = util.vector2(numberWidth, 0),
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
                                setDecayHours(argument.values[value])
                                set(value)
                            end),
                        },
                    }, lineHeight),
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

I.Settings.registerRenderer(mDef.renderers.perSkillUncapper, function(data, set, argument)
    data = data or {}
    local items = {}
    local lines = {}

    -- convert the userdata list to a list of list (serializable with "set")
    local allItems = {}
    for i = 1, #argument.allItems do
        local item = argument.allItems[i]
        allItems[#allItems + 1] = { key = item.key, name = item.name, value = item.value, maxLevel = item.maxLevel }
    end

    local function getAvailableItems()
        local available = {}
        local taken = {}
        for i = 1, #items do
            taken[items[i].key] = true
        end
        for i = 1, #allItems do
            if not taken[allItems[i].key] then
                table.insert(available, allItems[i])
            end
        end
        return available
    end

    local function getNextItem(key, forward)
        local available = {}
        local taken = {}
        for i = 1, #items do
            if items[i].key ~= key then
                taken[items[i].key] = true
            end
        end
        local index
        for i = 1, #allItems do
            if not taken[allItems[i].key] then
                if allItems[i].key == key then
                    index = #available + 1
                end
                table.insert(available, allItems[i])
            end
        end
        return available[(index + (forward and 0 or -2)) % #available + 1]
    end

    local lastInput

    for index, item in pairs(data) do
        table.insert(items, { key = item.key, name = item.name, value = item.value, maxLevel = item.maxLevel })
        table.insert(lines, {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            external = { stretch = 1 },
            content = ui.content {
                growingInterval,
                disable(item.maxLevel, {
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
                }),
                { template = I.MWUI.templates.interval },
                {
                    template = I.MWUI.templates.textNormal,
                    props = { text = item.name },
                },
                { template = I.MWUI.templates.interval },
                disable(item.maxLevel, {
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
                }),
                padding(10, 0),
                {
                    template = I.MWUI.templates.textEditLine,
                    props = {
                        text = tostring(item.value),
                        size = util.vector2(numberWidth, 0),
                        textAlignH = ui.ALIGNMENT.End,
                    },
                    events = {
                        textChanged = async:callback(function(value)
                            lastInput = value
                        end),
                        focusLoss = async:callback(function()
                            if not lastInput then return end
                            local arg = argument
                            if items[index].maxLevel then
                                arg = mHelpers.copyMap(argument)
                                arg.max = items[index].maxLevel
                            end
                            local number = validateNumber(lastInput, arg)
                            if number and number ~= data then
                                items[index].value = number
                            end
                            set(items)
                            lastInput = nil
                        end),
                    }
                },
                padding(10, 0),
                disable(item.maxLevel, {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = "x",
                        size = util.vector2(1, 1) * 12,
                        textSize = 16,
                        textColor = util.color.rgb(.8, .3, .4),
                    },
                    events = {
                        mouseClick = async:callback(function()
                            table.remove(items, index)
                            set(items)
                        end),
                    }
                }),
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

I.Settings.registerRenderer(mDef.renderers.empty, function(_, _, _)
    return {}
end)
