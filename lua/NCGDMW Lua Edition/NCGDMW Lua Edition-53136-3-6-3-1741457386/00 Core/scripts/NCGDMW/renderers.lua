local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require("openmw.interfaces")

local def = require('scripts.NCGDMW.definition')

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

local growingInterval = {
    external = { grow = 1 }
}

local stretchingLine = {
    template = I.MWUI.templates.horizontalLine,
    external = { stretch = 1 },
}

local leftArrow = ui.texture {
    path = 'textures/omw_menu_scroll_left.dds',
}

local rightArrow = ui.texture {
    path = 'textures/omw_menu_scroll_right.dds',
}

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

-- THANKS:
-- https://gitlab.com/urm-openmw-mods/camerahim/-/blob/1a12e3f8c902291d5629f2d8cc8649eac315533a/Data%20Files/scripts/CameraHIM/settings.lua#L23-35
I.Settings.registerRenderer(def.renderers.hotkey, function(value, set, argument)
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
    }, true))
end)

I.Settings.registerRenderer(def.renderers.number, function(value, set, argument)
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
                if not number then
                    set(value)
                end
                if number and number ~= value then
                    set(number)
                end
            end),
        },
    })
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
                    props = {
                        horizontal = true,
                        size = util.vector2(200, 0),
                    },
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

registerMultiSelectNumberRenderer(def.renderers.per_skill_uncapper, skillItems)
registerMultiSelectNumberRenderer(def.renderers.per_attribute_uncapper, attributeItems)
